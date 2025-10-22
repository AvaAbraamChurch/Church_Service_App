import 'package:church/core/models/Classes/classes_model.dart';

/// Base state for Classes management
abstract class ClassesState {}

/// Initial state
class ClassesInitial extends ClassesState {}

/// Loading state
class ClassesLoading extends ClassesState {}

/// Classes loaded successfully
class ClassesLoaded extends ClassesState {
  final List<Model> classes;

  ClassesLoaded(this.classes);
}

/// Error state
class ClassesError extends ClassesState {
  final String message;

  ClassesError(this.message);
}

/// Class added successfully
class ClassAdded extends ClassesState {}

/// Class updated successfully
class ClassUpdated extends ClassesState {}

/// Class deleted successfully
class ClassDeleted extends ClassesState {}

/// Validation error (e.g., duplicate name)
class ClassValidationError extends ClassesState {
  final String message;

  ClassValidationError(this.message);
}

