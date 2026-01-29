import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_web/features/auth/domain/entities/ministry.dart';
import 'package:sewa_web/features/auth/domain/repositories/public_ministry_repository.dart';

part 'ministry_list_event.dart';
part 'ministry_list_state.dart';

/// BLoC for managing ministry list by place
class MinistryListBloc extends Bloc<MinistryListEvent, MinistryListState> {
  final PublicMinistryRepository publicMinistryRepository;

  MinistryListBloc({required this.publicMinistryRepository})
    : super(MinistryListInitial()) {
    // Use droppable to prevent concurrent loads
    on<LoadMinistriesByPlaceEvent>(
      _onLoadMinistriesByPlace,
      transformer: droppable(),
    );
    on<RetryLoadMinistriesEvent>(
      _onRetryLoadMinistries,
      transformer: droppable(),
    );
    on<ClearMinistriesEvent>(_onClearMinistries);
  }

  Future<void> _onLoadMinistriesByPlace(
    LoadMinistriesByPlaceEvent event,
    Emitter<MinistryListState> emit,
  ) async {
    emit(MinistryListLoading());

    final result = await publicMinistryRepository.getMinistriesByPlace(
      event.placeSlug,
    );

    result.fold(
      (failure) {
        debugPrint(
          'MinistryListBloc: Error loading ministries: ${failure.message}',
        );
        emit(
          MinistryListError(
            message: failure.message,
            placeSlug: event.placeSlug,
          ),
        );
      },
      (ministries) {
        debugPrint('MinistryListBloc: Loaded ${ministries.length} ministries');
        emit(
          MinistriesLoaded(ministries: ministries, placeSlug: event.placeSlug),
        );
      },
    );
  }

  Future<void> _onRetryLoadMinistries(
    RetryLoadMinistriesEvent event,
    Emitter<MinistryListState> emit,
  ) async {
    add(LoadMinistriesByPlaceEvent(placeSlug: event.placeSlug));
  }

  void _onClearMinistries(
    ClearMinistriesEvent event,
    Emitter<MinistryListState> emit,
  ) {
    emit(MinistryListInitial());
  }
}
