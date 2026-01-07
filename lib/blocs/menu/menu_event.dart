import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class MenuEvent extends Equatable {
  const MenuEvent();

  @override
  List<Object?> get props => [];
}

class LoadMenu extends MenuEvent {}

class AddMenuItem extends MenuEvent {
  final String name;
  final String description;
  final double price;
  final File? imageFile;

  const AddMenuItem({
    required this.name,
    required this.description,
    required this.price,
    this.imageFile,
  });

  @override
  List<Object?> get props => [name, description, price, imageFile];
}

class UpdateMenuItem extends MenuEvent {
  final String id;
  final String name;
  final String description;
  final double price;
  final String? existingImageUrl;
  final File? newImageFile;
  final bool isAvailable;

  const UpdateMenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.existingImageUrl,
    this.newImageFile,
    required this.isAvailable,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    price,
    existingImageUrl,
    newImageFile,
    isAvailable,
  ];
}

class DeleteMenuItem extends MenuEvent {
  final String id;

  const DeleteMenuItem(this.id);

  @override
  List<Object> get props => [id];
}

class ToggleAvailability extends MenuEvent {
  final String id;
  final bool isAvailable;

  const ToggleAvailability(this.id, this.isAvailable);

  @override
  List<Object> get props => [id, isAvailable];
}
