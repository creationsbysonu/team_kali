import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_web/core/constants/api_endpoints.dart';
import 'package:sewa_web/core/errors/exceptions.dart';
import 'package:sewa_web/core/network/api_client.dart';
import 'package:sewa_web/core/network/network_info.dart';
import 'package:sewa_web/features/ministry/data/models/staff_service_model.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';

part 'staff_services_event.dart';
part 'staff_services_state.dart';

/// BLoC for managing staff services list (similar to MinistryListBloc)
class StaffServicesBloc extends Bloc<StaffServicesEvent, StaffServicesState> {
  final ApiClient apiClient;
  final NetworkInfo networkInfo;

  StaffServicesBloc({required this.apiClient, required this.networkInfo})
    : super(StaffServicesInitial()) {
    // Use droppable() to drop duplicate events while one is already processing
    on<LoadServicesEvent>(_onLoadServices, transformer: droppable());
    on<RetryLoadServicesEvent>(_onRetryLoadServices);
  }

  Future<void> _onLoadServices(
    LoadServicesEvent event,
    Emitter<StaffServicesState> emit,
  ) async {
    debugPrint(
      'StaffServicesBloc: Loading services for place: ${event.placeSlug}, ministry: ${event.ministrySlug}',
    );

    // Skip if already loaded for the same place/ministry
    if (state is ServicesLoaded) {
      final currentState = state as ServicesLoaded;
      if (currentState.placeSlug == event.placeSlug &&
          currentState.ministrySlug == event.ministrySlug) {
        debugPrint(
          'StaffServicesBloc: Services already loaded for ${event.placeSlug}/${event.ministrySlug}, skipping',
        );
        return;
      }
    }

    emit(StaffServicesLoading());

    if (!await networkInfo.isConnected) {
      debugPrint('StaffServicesBloc: No internet connection');
      emit(const StaffServicesError(message: 'No internet connection'));
      return;
    }

    try {
      final endpoint = ApiEndpoints.publicServicesByMinistry(
        event.placeSlug,
        event.ministrySlug,
      );

      final response = await apiClient.get(endpoint);

      if (response['success'] == true) {
        final List<dynamic> servicesData = response['data'];
        final services = servicesData
            .map((json) => StaffServiceModel.fromJson(json))
            .where((service) => service.isActive)
            .toList();

        debugPrint('StaffServicesBloc: Loaded ${services.length} services');
        emit(ServicesLoaded(services, event.placeSlug, event.ministrySlug));
      } else {
        final error = response['error'] ?? 'Failed to load services';
        debugPrint('StaffServicesBloc: Error - $error');
        emit(StaffServicesError(message: error));
      }
    } on ServerException catch (e) {
      debugPrint('StaffServicesBloc: Server exception - ${e.message}');
      emit(StaffServicesError(message: e.message));
    } catch (e) {
      debugPrint('StaffServicesBloc: Unknown error - $e');
      emit(StaffServicesError(message: 'Error loading services: $e'));
    }
  }

  Future<void> _onRetryLoadServices(
    RetryLoadServicesEvent event,
    Emitter<StaffServicesState> emit,
  ) async {
    add(
      LoadServicesEvent(
        placeSlug: event.placeSlug,
        ministrySlug: event.ministrySlug,
      ),
    );
  }
}
