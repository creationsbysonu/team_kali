import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_sathi/features/notice/domain/entities/notice_detail_entity.dart';
import 'package:sewa_sathi/features/notice/domain/usecases/get_notice_detail_usecase.dart';

part 'notice_detail_event.dart';
part 'notice_detail_state.dart';

/// BLoC for managing notice detail screen.
class NoticeDetailBloc extends Bloc<NoticeDetailEvent, NoticeDetailState> {
  final GetNoticeDetailUseCase getNoticeDetail;

  NoticeDetailBloc({required this.getNoticeDetail})
    : super(NoticeDetailInitial()) {
    on<LoadNoticeDetail>(_onLoadNoticeDetail);
  }

  Future<void> _onLoadNoticeDetail(
    LoadNoticeDetail event,
    Emitter<NoticeDetailState> emit,
  ) async {
    emit(NoticeDetailLoadInProgress());

    final result = await getNoticeDetail(event.noticeId);

    result.fold(
      (failure) => emit(NoticeDetailLoadFailure(message: failure.message)),
      (notice) => emit(NoticeDetailLoadSuccess(notice: notice)),
    );
  }
}
