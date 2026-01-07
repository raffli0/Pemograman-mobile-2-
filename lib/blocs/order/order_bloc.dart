import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/order_service.dart';
import '../../models/order_model.dart';
import 'order_event.dart';
import 'order_state.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final OrderService _orderService;
  StreamSubscription? _historySubscription;
  Timer? _pollingTimer;

  // Cache to maintain state between polling/streams
  List<Order> _activeCache = [];
  List<Order> _historyCache = [];

  OrderBloc({required OrderService orderService})
    : _orderService = orderService,
      super(OrderInitial()) {
    on<LoadHistoryOrders>(_onLoadHistoryOrders);
    on<StartPollingQueue>(_onStartPollingQueue);
    on<StopPollingQueue>(_onStopPollingQueue);
    on<CreateOrder>(_onCreateOrder);
    on<UpdateOrderStatus>(_onUpdateOrderStatus);
    on<CancelOrder>(_onCancelOrder);

    // Internal events
    on<_HistoryUpdated>(_onHistoryUpdated);
    on<_QueueUpdated>(_onQueueUpdated);
    on<_OrderErrorEvent>(_onOrderError);
  }

  @override
  Future<void> close() {
    _historySubscription?.cancel();
    _pollingTimer?.cancel();
    return super.close();
  }

  void _onLoadHistoryOrders(LoadHistoryOrders event, Emitter<OrderState> emit) {
    // If not already loading or loaded, emit loading?
    // Better to emit OrderLoaded with empty lists if initial.
    if (state is OrderInitial) {
      emit(OrderLoading());
    }

    _historySubscription?.cancel();
    final stream = event.customerId != null
        ? _orderService.getCustomerHistoryOrders(event.customerId!)
        : _orderService.getHistoryOrders();

    _historySubscription = stream.listen(
      (orders) => add(_HistoryUpdated(orders)),
      onError: (e) => add(_OrderErrorEvent(e.toString())),
    );
  }

  void _onStartPollingQueue(StartPollingQueue event, Emitter<OrderState> emit) {
    if (state is OrderInitial) {
      emit(OrderLoading());
    }

    _pollingTimer?.cancel();

    // Immediate fetch
    _fetchQueue(event.customerId);

    // Periodic
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _fetchQueue(event.customerId);
    });
  }

  void _onStopPollingQueue(StopPollingQueue event, Emitter<OrderState> emit) {
    _pollingTimer?.cancel();
  }

  Future<void> _fetchQueue(String? customerId) async {
    try {
      final orders = customerId != null
          ? await _orderService.fetchCustomerActiveOrders(customerId)
          : await _orderService.fetchActiveOrders();
      add(_QueueUpdated(orders));
    } catch (e) {
      // Silent fail on polling? Or log?
      // add(_OrderErrorEvent(e.toString()));
      print('Polling error: $e');
    }
  }

  // Event Handlers
  void _onHistoryUpdated(_HistoryUpdated event, Emitter<OrderState> emit) {
    _historyCache = event.orders;
    emit(OrderLoaded(activeOrders: _activeCache, historyOrders: _historyCache));
  }

  void _onQueueUpdated(_QueueUpdated event, Emitter<OrderState> emit) {
    _activeCache = event.orders;
    emit(OrderLoaded(activeOrders: _activeCache, historyOrders: _historyCache));
  }

  void _onOrderError(_OrderErrorEvent event, Emitter<OrderState> emit) {
    emit(OrderError(event.message));
  }

  Future<void> _onCreateOrder(
    CreateOrder event,
    Emitter<OrderState> emit,
  ) async {
    try {
      final totalAmount = event.items.fold(
        0.0,
        (sum, item) => sum + item.totalPrice,
      );
      final order = Order(
        id: '', // Generated
        customerId: event.customerId,
        customerName: event.customerName,
        items: event.items,
        totalAmount: totalAmount,
        paymentMethod: event.paymentMethod,
        status: OrderStatus.pending,
        createdAt: DateTime.now(),
      );

      await _orderService.createOrder(order);

      // Emit success for UI feedback
      emit(const OrderOperationSuccess('Order placed successfully!'));

      // Refresh active queue immediately and go back to loaded
      await _fetchQueue(event.customerId);

      // If fetchQueue doesn't emit (it adds event), we might need to manually ensure we are in Loaded state
      // Actually fetchQueue adds _QueueUpdated which emits OrderLoaded.
      // So we rely on that.
    } catch (e) {
      emit(OrderError(e.toString()));
      // Re-emit loaded state
      emit(
        OrderLoaded(activeOrders: _activeCache, historyOrders: _historyCache),
      );
    }
  }

  Future<void> _onUpdateOrderStatus(
    UpdateOrderStatus event,
    Emitter<OrderState> emit,
  ) async {
    // Optimistic Update can be tricky in BLoC without modifying _activeCache accurately.
    // For now, implementing standard "Call -> Refresh" flow.
    // To do optimistic, we would modify _activeCache, emit, then call API.

    final originalCache = List<Order>.from(_activeCache);

    try {
      // Optimistic
      final index = _activeCache.indexWhere((o) => o.id == event.orderId);
      if (index != -1) {
        if (event.status == OrderStatus.completed) {
          _activeCache.removeAt(index);
        } else {
          _activeCache[index] = _activeCache[index].copyWith(
            status: event.status,
          );
        }
        emit(
          OrderLoaded(activeOrders: _activeCache, historyOrders: _historyCache),
        );
      }

      await _orderService.updateOrderStatus(event.orderId, event.status);
      _fetchQueue(null); // Refresh queue (assuming cashier context here)
    } catch (e) {
      // Revert
      _activeCache = originalCache;
      emit(OrderError(e.toString()));
      emit(
        OrderLoaded(activeOrders: _activeCache, historyOrders: _historyCache),
      );
    }
  }

  Future<void> _onCancelOrder(
    CancelOrder event,
    Emitter<OrderState> emit,
  ) async {
    final originalCache = List<Order>.from(_activeCache);
    try {
      final index = _activeCache.indexWhere((o) => o.id == event.orderId);
      if (index != -1) {
        _activeCache[index] = _activeCache[index].copyWith(
          status: OrderStatus.cancelled,
        );
        emit(
          OrderLoaded(activeOrders: _activeCache, historyOrders: _historyCache),
        );
      }

      await _orderService.cancelOrder(event.orderId);
      _fetchQueue(null);
    } catch (e) {
      _activeCache = originalCache;
      emit(OrderError(e.toString()));
      emit(
        OrderLoaded(activeOrders: _activeCache, historyOrders: _historyCache),
      );
    }
  }
}

// Internal events
class _HistoryUpdated extends OrderEvent {
  final List<Order> orders;
  const _HistoryUpdated(this.orders);
  @override
  List<Object> get props => [orders];
}

class _QueueUpdated extends OrderEvent {
  final List<Order> orders;
  const _QueueUpdated(this.orders);
  @override
  List<Object> get props => [orders];
}

class _OrderErrorEvent extends OrderEvent {
  final String message;
  const _OrderErrorEvent(this.message);
  @override
  List<Object> get props => [message];
}
