import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_web/core/usecases/usecase.dart';
import 'package:sewa_web/features/staff/domain/entities/staff_member.dart';
import 'package:sewa_web/features/staff/domain/usecases/staff_usecases.dart';

part 'staff_event.dart';
part 'staff_state.dart';

/// BLoC for managing staff members
class StaffBloc extends Bloc<StaffEvent, StaffState> {
  final GetMinistryStaffUseCase getMinistryStaff;
  final CreateStaffUseCase? createStaff;
  final UpdateStaffUseCase? updateStaff;
  final DeleteStaffUseCase? deleteStaff;
  final ResetStaffPasswordUseCase? resetStaffPassword;

  StaffBloc({
    required this.getMinistryStaff,
    this.createStaff,
    this.updateStaff,
    this.deleteStaff,
    this.resetStaffPassword,
  }) : super(StaffInitial()) {
    on<LoadStaffEvent>(_onLoadStaff);
    on<CreateStaffEvent>(_onCreateStaff);
    on<UpdateStaffEvent>(_onUpdateStaff);
    on<DeleteStaffEvent>(_onDeleteStaff);
    on<ResetStaffPasswordEvent>(_onResetPassword);
  }

  Future<void> _onLoadStaff(
    LoadStaffEvent event,
    Emitter<StaffState> emit,
  ) async {
    emit(StaffLoading());

    final result = await getMinistryStaff(const NoParams());

    result.fold(
      (failure) => emit(StaffError(message: failure.message)),
      (staff) => emit(StaffLoaded(staff: staff)),
    );
  }

  Future<void> _onCreateStaff(
    CreateStaffEvent event,
    Emitter<StaffState> emit,
  ) async {
    if (createStaff == null) {
      emit(const StaffError(message: 'Not authorized'));
      return;
    }

    emit(StaffOperationLoading());

    final result = await createStaff!(
      CreateStaffParams(
        name: event.name,
        email: event.email,
        password: event.password,
        serviceId: event.serviceId,
        contact: event.contact,
        imagePath: event.imagePath,
      ),
    );

    result.fold(
      (failure) => emit(StaffOperationError(message: failure.message)),
      (staff) => emit(
        StaffOperationSuccess(
          message: 'Staff "${staff.name}" created successfully',
          staff: staff,
        ),
      ),
    );
  }

  Future<void> _onUpdateStaff(
    UpdateStaffEvent event,
    Emitter<StaffState> emit,
  ) async {
    if (updateStaff == null) {
      emit(const StaffError(message: 'Not authorized'));
      return;
    }

    emit(StaffOperationLoading());

    final result = await updateStaff!(
      UpdateStaffParams(
        id: event.id,
        name: event.name,
        contact: event.contact,
        password: event.password,
        isActive: event.isActive,
      ),
    );

    result.fold(
      (failure) => emit(StaffOperationError(message: failure.message)),
      (staff) => emit(
        StaffOperationSuccess(
          message: 'Staff "${staff.name}" updated successfully',
          staff: staff,
        ),
      ),
    );
  }

  Future<void> _onDeleteStaff(
    DeleteStaffEvent event,
    Emitter<StaffState> emit,
  ) async {
    if (deleteStaff == null) {
      emit(const StaffError(message: 'Not authorized'));
      return;
    }

    emit(StaffOperationLoading());

    final result = await deleteStaff!(event.id);

    result.fold(
      (failure) => emit(StaffOperationError(message: failure.message)),
      (_) => emit(
        const StaffOperationSuccess(message: 'Staff deleted successfully'),
      ),
    );
  }

  Future<void> _onResetPassword(
    ResetStaffPasswordEvent event,
    Emitter<StaffState> emit,
  ) async {
    if (resetStaffPassword == null) {
      emit(const StaffError(message: 'Not authorized'));
      return;
    }

    emit(StaffOperationLoading());

    final result = await resetStaffPassword!(
      ResetStaffPasswordParams(
        staffId: event.staffId,
        newPassword: event.newPassword,
      ),
    );

    result.fold(
      (failure) => emit(StaffOperationError(message: failure.message)),
      (_) => emit(
        const StaffOperationSuccess(message: 'Password reset successfully'),
      ),
    );
  }
}
