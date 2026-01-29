import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_web/core/usecases/usecase.dart';
import 'package:sewa_web/features/ministry/domain/entities/staff_service_entity.dart';
import 'package:sewa_web/features/ministry/domain/usecases/create_staff_service_usecase.dart';
import 'package:sewa_web/features/ministry/domain/usecases/delete_staff_service_usecase.dart';
import 'package:sewa_web/features/ministry/domain/usecases/get_staff_services_usecase.dart';
import 'package:sewa_web/features/ministry/domain/usecases/reset_staff_password_usecase.dart';
import 'package:sewa_web/features/ministry/domain/usecases/toggle_staff_service_status_usecase.dart';
import 'package:sewa_web/features/ministry/domain/usecases/update_staff_service_usecase.dart';

part 'staff_service_event.dart';
part 'staff_service_state.dart';

class StaffServiceBloc extends Bloc<StaffServiceEvent, StaffServiceState> {
  final GetStaffServicesUseCase getStaffServices;
  final CreateStaffServiceUseCase createStaffService;
  final UpdateStaffServiceUseCase updateStaffService;
  final DeleteStaffServiceUseCase deleteStaffService;
  final ResetStaffPasswordUseCase resetStaffPassword;
  final ToggleStaffServiceStatusUseCase toggleStaffServiceStatus;

  StaffServiceBloc({
    required this.getStaffServices,
    required this.createStaffService,
    required this.updateStaffService,
    required this.deleteStaffService,
    required this.resetStaffPassword,
    required this.toggleStaffServiceStatus,
  }) : super(StaffServiceInitial()) {
    on<LoadStaffServicesEvent>(_onLoadStaffServices);
    on<CreateStaffServiceEvent>(_onCreateStaffService);
    on<UpdateStaffServiceEvent>(_onUpdateStaffService);
    on<DeleteStaffServiceEvent>(_onDeleteStaffService);
    on<ResetStaffPasswordEvent>(_onResetStaffPassword);
    on<ToggleStaffServiceStatusEvent>(_onToggleStaffServiceStatus);
  }

  Future<void> _onLoadStaffServices(
    LoadStaffServicesEvent event,
    Emitter<StaffServiceState> emit,
  ) async {
    emit(StaffServiceLoading());

    final result = await getStaffServices(const NoParams());

    result.fold(
      (failure) => emit(StaffServiceError(message: failure.message)),
      (services) => emit(StaffServiceLoaded(services: services)),
    );
  }

  Future<void> _onCreateStaffService(
    CreateStaffServiceEvent event,
    Emitter<StaffServiceState> emit,
  ) async {
    final currentServices = _getCurrentServices();

    emit(
      StaffServiceOperationInProgress(
        operationType: 'create',
        currentServices: currentServices,
      ),
    );

    final result = await createStaffService(
      CreateStaffServiceParams(
        serviceName: event.serviceName,
        staffName: event.staffName,
        email: event.email,
        password: event.password,
        serviceLogoBytes: event.serviceLogoBytes,
        serviceLogoFileName: event.serviceLogoFileName,
        staffImageBytes: event.staffImageBytes,
        staffImageFileName: event.staffImageFileName,
      ),
    );

    result.fold(
      (failure) => emit(
        StaffServiceError(
          message: failure.message,
          currentServices: currentServices,
        ),
      ),
      (newService) {
        // Emit created state for dialog to listen
        emit(StaffServiceCreated(service: newService));
        // Then emit loaded state with updated list
        final updatedServices = [...currentServices, newService];
        emit(StaffServiceLoaded(services: updatedServices));
      },
    );
  }

  Future<void> _onUpdateStaffService(
    UpdateStaffServiceEvent event,
    Emitter<StaffServiceState> emit,
  ) async {
    final currentServices = _getCurrentServices();

    emit(
      StaffServiceOperationInProgress(
        operationType: 'update',
        currentServices: currentServices,
      ),
    );

    final result = await updateStaffService(
      UpdateStaffServiceParams(
        id: event.id,
        serviceName: event.serviceName,
        staffName: event.staffName,
        serviceLogoBytes: event.serviceLogoBytes,
        serviceLogoFileName: event.serviceLogoFileName,
        staffImageBytes: event.staffImageBytes,
        staffImageFileName: event.staffImageFileName,
      ),
    );

    result.fold(
      (failure) => emit(
        StaffServiceError(
          message: failure.message,
          currentServices: currentServices,
        ),
      ),
      (updatedService) {
        final updatedServices = currentServices
            .map(
              (service) =>
                  service.id == updatedService.id ? updatedService : service,
            )
            .toList();
        emit(
          StaffServiceOperationSuccess(
            message: 'Service updated successfully',
            updatedServices: updatedServices,
          ),
        );
        emit(StaffServiceLoaded(services: updatedServices));
      },
    );
  }

  Future<void> _onDeleteStaffService(
    DeleteStaffServiceEvent event,
    Emitter<StaffServiceState> emit,
  ) async {
    final currentServices = _getCurrentServices();

    emit(
      StaffServiceOperationInProgress(
        operationType: 'delete',
        currentServices: currentServices,
      ),
    );

    final result = await deleteStaffService(
      DeleteStaffServiceParams(id: event.id),
    );

    result.fold(
      (failure) => emit(
        StaffServiceError(
          message: failure.message,
          currentServices: currentServices,
        ),
      ),
      (_) {
        final updatedServices = currentServices
            .where((service) => service.id != event.id)
            .toList();
        emit(
          StaffServiceOperationSuccess(
            message: 'Service deleted successfully',
            updatedServices: updatedServices,
          ),
        );
        emit(StaffServiceLoaded(services: updatedServices));
      },
    );
  }

  Future<void> _onResetStaffPassword(
    ResetStaffPasswordEvent event,
    Emitter<StaffServiceState> emit,
  ) async {
    final currentServices = _getCurrentServices();

    emit(
      StaffServiceOperationInProgress(
        operationType: 'reset_password',
        currentServices: currentServices,
      ),
    );

    final result = await resetStaffPassword(
      ResetStaffPasswordParams(id: event.id, newPassword: event.newPassword),
    );

    result.fold(
      (failure) => emit(
        StaffServiceError(
          message: failure.message,
          currentServices: currentServices,
        ),
      ),
      (_) {
        emit(
          StaffServiceOperationSuccess(
            message: 'Password reset successfully',
            updatedServices: currentServices,
          ),
        );
        emit(StaffServiceLoaded(services: currentServices));
      },
    );
  }

  Future<void> _onToggleStaffServiceStatus(
    ToggleStaffServiceStatusEvent event,
    Emitter<StaffServiceState> emit,
  ) async {
    final currentServices = _getCurrentServices();

    emit(
      StaffServiceOperationInProgress(
        operationType: 'toggle',
        currentServices: currentServices,
      ),
    );

    final result = await toggleStaffServiceStatus(
      ToggleStaffServiceStatusParams(id: event.id),
    );

    result.fold(
      (failure) => emit(
        StaffServiceError(
          message: failure.message,
          currentServices: currentServices,
        ),
      ),
      (updatedService) {
        final updatedServices = currentServices
            .map(
              (service) =>
                  service.id == updatedService.id ? updatedService : service,
            )
            .toList();
        emit(
          StaffServiceOperationSuccess(
            message: 'Status updated successfully',
            updatedServices: updatedServices,
          ),
        );
        emit(StaffServiceLoaded(services: updatedServices));
      },
    );
  }

  /// Helper method to get current services from state
  List<StaffService> _getCurrentServices() {
    final currentState = state;
    if (currentState is StaffServiceLoaded) {
      return currentState.services;
    } else if (currentState is StaffServiceOperationInProgress) {
      return currentState.currentServices;
    } else if (currentState is StaffServiceError &&
        currentState.currentServices != null) {
      return currentState.currentServices!;
    }
    return [];
  }
}
