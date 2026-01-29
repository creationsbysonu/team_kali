import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sewa_web/core/theme/theme.dart';
import 'package:sewa_web/features/notice/domain/entities/notice_entity.dart';
import 'package:sewa_web/features/notice/presentation/bloc/notice_bloc.dart';
import 'package:sewa_web/features/notice/presentation/widgets/notice_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

/// Table widget to display notices
class NoticeTable extends StatelessWidget {
  final List<NoticeEntity> notices;

  const NoticeTable({super.key, required this.notices});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTableHeader(),
          const Divider(height: 1, color: AppTheme.borderColor),
          Expanded(
            child: ListView.separated(
              itemCount: notices.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppTheme.borderColor),
              itemBuilder: (context, index) {
                return _NoticeTableRow(notice: notices[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'Notice',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Service',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              'Type',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          SizedBox(
            width: 120,
            child: Text(
              'Ingestion',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          SizedBox(
            width: 120,
            child: Text(
              'Date',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              'Actions',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoticeTableRow extends StatelessWidget {
  final NoticeEntity notice;

  const _NoticeTableRow({required this.notice});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openFile(notice.fileUrl),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              // Notice info
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    _buildFileIcon(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notice.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            notice.createdByEmail ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Service
              Expanded(
                flex: 2,
                child: Text(
                  notice.service?.name ?? 'No Service',
                  style: TextStyle(
                    fontSize: 13,
                    color: notice.service != null
                        ? AppTheme.textPrimary
                        : AppTheme.textMuted,
                  ),
                ),
              ),
              // File type
              SizedBox(
                width: 100,
                child: FileTypeBadge(fileType: notice.fileType),
              ),
              // Ingestion status
              SizedBox(
                width: 120,
                child: Row(
                  children: [
                    IngestionStatusChip(
                      status: notice.ingestionStatus,
                      compact: true,
                    ),
                    if (notice.hasIngestionFailed) ...[
                      const SizedBox(width: 4),
                      Tooltip(
                        message: 'Retry ingestion',
                        child: InkWell(
                          onTap: () => _retryIngestion(context),
                          borderRadius: BorderRadius.circular(4),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              Icons.refresh,
                              size: 16,
                              color: AppTheme.primaryCobalt,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Date
              SizedBox(
                width: 120,
                child: Text(
                  DateFormat('MMM d, yyyy').format(notice.createdAt),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              // Actions
              SizedBox(
                width: 100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ActionButton(
                      icon: Icons.open_in_new,
                      tooltip: 'Open file',
                      onPressed: () => _openFile(notice.fileUrl),
                    ),
                    _ActionButton(
                      icon: Icons.delete_outline,
                      tooltip: 'Delete',
                      color: AppTheme.error,
                      onPressed: () => _confirmDelete(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileIcon() {
    final isPdf = notice.isPdf;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isPdf
            ? const Color(0xFFE74C3C).withValues(alpha: 0.1)
            : AppTheme.primaryCobalt.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        isPdf ? Icons.picture_as_pdf : Icons.image,
        color: isPdf ? const Color(0xFFE74C3C) : AppTheme.primaryCobalt,
        size: 20,
      ),
    );
  }

  void _openFile(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _retryIngestion(BuildContext context) {
    context.read<NoticeBloc>().add(RetryIngestionEvent(noticeId: notice.id));
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Delete Notice'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to delete this notice?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    notice.isPdf ? Icons.picture_as_pdf : Icons.image,
                    color: AppTheme.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      notice.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<NoticeBloc>().add(
                DeleteNoticeEvent(noticeId: notice.id),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 18, color: color ?? AppTheme.textSecondary),
        ),
      ),
    );
  }
}
