part of 'staff_services_bloc.dart';

abstract class StaffServicesEvent extends Equatable {
  const StaffServicesEvent();

  @override
  List<Object?> get props => [];
}

class LoadServicesEvent extends StaffServicesEvent {
  final String placeSlug;
  final String ministrySlug;

  const LoadServicesEvent({
    required this.placeSlug,
    required this.ministrySlug,
  });

  @override
  List<Object?> get props => [placeSlug, ministrySlug];
}

class RetryLoadServicesEvent extends StaffServicesEvent {
  final String placeSlug;
  final String ministrySlug;

  const RetryLoadServicesEvent({
    required this.placeSlug,
    required this.ministrySlug,
  });

  @override
  List<Object?> get props => [placeSlug, ministrySlug];
}
