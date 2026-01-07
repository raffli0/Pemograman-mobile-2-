import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;

  AuthBloc({required AuthService authService})
    : _authService = authService,
      super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLogin>(_onAuthLogin);
    on<AuthRegister>(_onAuthRegister);
    on<AuthLoginAnonymously>(_onAuthLoginAnonymously);
    on<AuthLogout>(_onAuthLogout);
  }

  Future<void> _onAuthLoginAnonymously(
    AuthLoginAnonymously event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _authService.signInAnonymously();
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(const AuthError('Guest login failed'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final firebaseUser = _authService.currentUser;
      if (firebaseUser != null) {
        final user = await _authService.getUserProfile(firebaseUser.uid);
        if (user != null) {
          emit(AuthAuthenticated(user));
        } else {
          // Handle anonymous user persistence or inconsistent state
          // For now, if profile missing but firebase auth exists, logout or handle.
          emit(AuthUnauthenticated());
        }
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onAuthLogin(AuthLogin event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _authService.signIn(
        email: event.email,
        password: event.password,
      );
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(const AuthError('Login failed'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onAuthRegister(
    AuthRegister event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      // Map string role to UserRole enum if needed, but AuthService.register takes UserRole
      // The event.role is String? In register_screen it passes UserRole.. toString()?
      // Wait, AuthRegister event definition: final String name; final String email; final String password; final String role;
      // AuthService.register takes UserRole enum.

      UserRole userRole = UserRole.customer;
      if (event.role.toLowerCase() == 'cashier') {
        userRole = UserRole.cashier;
      }

      final user = await _authService.register(
        email: event.email,
        password: event.password,
        name: event.name,
        role: userRole,
      );

      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(const AuthError('Registration failed'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onAuthLogout(AuthLogout event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _authService.signOut();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}
