import 'package:church/core/blocs/classes/classes_states.dart';
import 'package:church/core/models/Classes/classes_model.dart';
import 'package:church/core/repositories/classes_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Cubit for managing classes CRUD operations
class ClassesCubit extends Cubit<ClassesState> {
  final ClassesRepository _repository;

  ClassesCubit({ClassesRepository? repository})
      : _repository = repository ?? ClassesRepository(),
        super(ClassesInitial());

  /// Static method to get cubit from context
  static ClassesCubit get(context) => BlocProvider.of(context);

  /// Load all classes
  Stream<List<Model>> getAllClassesStream() {
    return _repository.getAllClasses();
  }

  /// Add a new class
  Future<void> addClass(String name) async {
    if (name.trim().isEmpty) {
      emit(ClassValidationError('الرجاء إدخال اسم الأسرة'));
      return;
    }

    emit(ClassesLoading());

    try {
      // Check if name already exists
      final exists = await _repository.classNameExists(name.trim());
      if (exists) {
        emit(ClassValidationError('اسم الأسرة موجود بالفعل'));
        return;
      }

      await _repository.addClass(name.trim());
      emit(ClassAdded());
    } catch (e) {
      emit(ClassesError('فشل في إضافة الأسرة: $e'));
    }
  }

  /// Update an existing class
  Future<void> updateClass(String id, String name) async {
    if (name.trim().isEmpty) {
      emit(ClassValidationError('الرجاء إدخال اسم الأسرة'));
      return;
    }

    emit(ClassesLoading());

    try {
      // Check if name already exists (excluding current class)
      final exists = await _repository.classNameExists(name.trim(), excludeId: id);
      if (exists) {
        emit(ClassValidationError('اسم الأسرة موجود بالفعل'));
        return;
      }

      await _repository.updateClass(id, name.trim());
      emit(ClassUpdated());
    } catch (e) {
      emit(ClassesError('فشل في تحديث الأسرة: $e'));
    }
  }

  /// Delete a class
  Future<void> deleteClass(String id) async {
    emit(ClassesLoading());

    try {
      await _repository.deleteClass(id);
      emit(ClassDeleted());
    } catch (e) {
      emit(ClassesError('فشل في حذف الأسرة: $e'));
    }
  }
}

