part of 'staff_services_bloc.dart';

abstract class StaffServicesState extends Equatable {
  const StaffServicesState();

  @override
  List<Object?> get props => [];
}

class StaffServicesInitial extends StaffServicesState {}

class StaffServicesLoading extends StaffServicesState {}

class ServicesLoaded extends StaffServicesState {
  final List<StaffServiceModel> services;
  final String placeSlug;
  final String ministrySlug;

  const ServicesLoaded(this.services, this.placeSlug, this.ministrySlug);

  @override
  List<Object?> get props => [services, placeSlug, ministrySlug];
}

class StaffServicesError extends StaffServicesState {
  final String message;

  const StaffServicesError({required this.message});

  @override
  List<Object?> get props => [message];
}
