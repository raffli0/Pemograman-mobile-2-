import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'blocs/auth/auth_bloc.dart';
import 'blocs/auth/auth_event.dart';
import 'blocs/auth/auth_state.dart';
import 'blocs/menu/menu_bloc.dart';
import 'blocs/menu/menu_event.dart';
import 'blocs/cart/cart_bloc.dart';
import 'blocs/order/order_bloc.dart';

import 'services/auth_service.dart';
import 'services/menu_service.dart';
import 'services/order_service.dart';
import 'services/notification_service.dart';

import 'screens/cashier/cashier_dashboard.dart';
import 'screens/customer/customer_dashboard.dart';
import 'screens/auth/welcome_screen.dart';
import 'models/user_model.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Create services instances
    final authService = AuthService();
    final menuService = MenuService();
    final orderService = OrderService();

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: authService),
        RepositoryProvider.value(value: menuService),
        RepositoryProvider.value(value: orderService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) =>
                AuthBloc(authService: authService)..add(AuthCheckRequested()),
          ),
          BlocProvider<MenuBloc>(
            create: (context) =>
                MenuBloc(menuService: menuService)..add(LoadMenu()),
          ),
          BlocProvider<CartBloc>(create: (context) => CartBloc()),
          BlocProvider<OrderBloc>(
            create: (context) => OrderBloc(orderService: orderService),
          ),
        ],
        child: MaterialApp(
          title: 'Restaurant POS',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.amber,
              primary: Colors.amber[700],
              secondary: Colors.red[700],
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.amber[700],
              foregroundColor: Colors.black,
              elevation: 0,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[700],
                foregroundColor: Colors.black,
              ),
            ),
            useMaterial3: true,
          ),
          home: const AuthWrapper(),
        ),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    try {
      await _notificationService.initialize();
    } catch (e) {
      debugPrint('Notification initialization error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) async {
        if (state is AuthAuthenticated) {
          // Subscribe cashiers to new order notifications
          if (state.user.role == UserRole.cashier) {
            await _notificationService.subscribeToTopic('new_orders');
          }
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            if (state.user.role == UserRole.cashier) {
              return const CashierDashboard();
            } else {
              return const CustomerDashboard();
            }
          } else if (state is AuthUnauthenticated) {
            return const WelcomeScreen();
          } else if (state is AuthLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // Default/Initial state
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }
}
