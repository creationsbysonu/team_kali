import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_web/core/usecases/usecase.dart';
import 'package:sewa_web/features/services/domain/entities/service.dart';
import 'package:sewa_web/features/services/domain/usecases/service_usecases.dart';

part 'service_event.dart';
part 'service_state.dart';

/// BLoC for managing services
class ServiceBloc extends Bloc<ServiceEvent, ServiceState> {
  final GetPublicServicesUseCase getPublicServices;
  final GetMinistryServicesUseCase? getMinistryServices;
  final CreateServiceUseCase? createService;
  final UpdateServiceUseCase? updateService;
  final DeleteServiceUseCase? deleteService;

  ServiceBloc({
    required this.getPublicServices,
    this.getMinistryServices,
    this.createService,
    this.updateService,
    this.deleteService,
  }) : super(ServiceInitial()) {
    on<LoadPublicServicesEvent>(_onLoadPublicServices);
    on<LoadMinistryServicesEvent>(_onLoadMinistryServices);
    on<SelectServiceEvent>(_onSelectService);
    on<CreateServiceEvent>(_onCreateService);
    on<UpdateServiceEvent>(_onUpdateService);
    on<DeleteServiceEvent>(_onDeleteService);
    on<ClearSelectedServiceEvent>(_onClearSelectedService);
  }

  Future<void> _onLoadPublicServices(
    LoadPublicServicesEvent event,
    Emitter<ServiceState> emit,
  ) async {
    emit(ServiceLoading());

    final result = await getPublicServices(
      GetPublicServicesParams(
        placeSlug: event.placeSlug,
        ministrySlug: event.ministrySlug,
      ),
    );

    result.fold(
      (failure) => emit(ServiceError(message: failure.message)),
      (services) => emit(ServicesLoaded(services: services)),
    );
  }

  Future<void> _onLoadMinistryServices(
    LoadMinistryServicesEvent event,
    Emitter<ServiceState> emit,
  ) async {
    if (getMinistryServices == null) {
      emit(const ServiceError(message: 'Not authorized'));
      return;
    }

    emit(ServiceLoading());

    final result = await getMinistryServices!(const NoParams());

    result.fold(
      (failure) => emit(ServiceError(message: failure.message)),
      (services) => emit(ServicesLoaded(services: services)),
    );
  }

  void _onSelectService(SelectServiceEvent event, Emitter<ServiceState> emit) {
    emit(ServiceSelected(service: event.service));
  }

  void _onClearSelectedService(
    ClearSelectedServiceEvent event,
    Emitter<ServiceState> emit,
  ) {
    emit(ServiceInitial());
  }

  Future<void> _onCreateService(
    CreateServiceEvent event,
    Emitter<ServiceState> emit,
  ) async {
    if (createService == null) {
      emit(const ServiceError(message: 'Not authorized'));
      return;
    }

    emit(ServiceOperationLoading());

    final result = await createService!(
      CreateServiceParams(
        name: event.name,
        slug: event.slug,
        description: event.description,
        serviceType: event.serviceType,
        feeAmount: event.feeAmount,
      ),
    );

    result.fold(
      (failure) => emit(ServiceOperationError(message: failure.message)),
      (service) => emit(
        ServiceOperationSuccess(
          message: 'Service "${service.name}" created successfully',
          service: service,
        ),
      ),
    );
  }

  Future<void> _onUpdateService(
    UpdateServiceEvent event,
    Emitter<ServiceState> emit,
  ) async {
    if (updateService == null) {
      emit(const ServiceError(message: 'Not authorized'));
      return;
    }

    emit(ServiceOperationLoading());

    final result = await updateService!(
      UpdateServiceParams(
        id: event.id,
        name: event.name,
        slug: event.slug,
        description: event.description,
        serviceType: event.serviceType,
        feeAmount: event.feeAmount,
        isActive: event.isActive,
        isPublished: event.isPublished,
      ),
    );

    result.fold(
      (failure) => emit(ServiceOperationError(message: failure.message)),
      (service) => emit(
        ServiceOperationSuccess(
          message: 'Service "${service.name}" updated successfully',
          service: service,
        ),
      ),
    );
  }

  Future<void> _onDeleteService(
    DeleteServiceEvent event,
    Emitter<ServiceState> emit,
  ) async {
    if (deleteService == null) {
      emit(const ServiceError(message: 'Not authorized'));
      return;
    }

    emit(ServiceOperationLoading());

    final result = await deleteService!(event.id);

    result.fold(
      (failure) => emit(ServiceOperationError(message: failure.message)),
      (_) => emit(
        const ServiceOperationSuccess(message: 'Service deleted successfully'),
      ),
    );
  }
}
