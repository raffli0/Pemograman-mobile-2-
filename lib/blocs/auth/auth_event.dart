import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthLogin extends AuthEvent {
  final String email;
  final String password;

  const AuthLogin({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

class AuthRegister extends AuthEvent {
  final String email;
  final String password;
  final String name;
  final String role; // 'cashier' or 'customer'

  const AuthRegister({
    required this.email,
    required this.password,
    required this.name,
    required this.role,
  });

  @override
  List<Object> get props => [email, password, name, role];
}

class AuthLoginAnonymously extends AuthEvent {}

class AuthLogout extends AuthEvent {}
