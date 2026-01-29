import 'package:equatable/equatable.dart';
import 'package:sewa_sathi/features/notice/domain/entities/notice_entity.dart';

/// Entity for paginated notice list response.
class NoticeListResponseEntity extends Equatable {
  final List<NoticeEntity> results;
  final int count;
  final int limit;
  final int offset;
  final bool hasMore;

  const NoticeListResponseEntity({
    required this.results,
    required this.count,
    required this.limit,
    required this.offset,
    required this.hasMore,
  });

  @override
  List<Object?> get props => [results, count, limit, offset, hasMore];
}
