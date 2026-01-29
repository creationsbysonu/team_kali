import 'package:flutter/material.dart';
import 'package:sewa_web/core/theme/theme.dart';
import 'package:sewa_web/features/notice/domain/entities/notice_entity.dart';

/// Header widget for notice page with filters
/// Adapts based on user type (Ministry Admin vs Staff Admin)
class NoticeHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onUpload;
  final VoidCallback onRefresh;
  final String? selectedServiceId;
  final String? selectedStatus;
  final String searchQuery;
  final List<NoticeServiceEntity> services;
  final ValueChanged<String?> onServiceChanged;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<String> onSearchChanged;
  final int totalCount;
  final bool showServiceFilter;

  const NoticeHeader({
    super.key,
    this.title = 'Notice Portal',
    this.subtitle = 'Upload and manage public notices',
    required this.onUpload,
    required this.onRefresh,
    required this.selectedServiceId,
    required this.selectedStatus,
    required this.searchQuery,
    required this.services,
    required this.onServiceChanged,
    required this.onStatusChanged,
    required this.onSearchChanged,
    required this.totalCount,
    this.showServiceFilter = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryCobalt.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.article_outlined,
                  color: AppTheme.primaryCobalt,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalCount notices • $subtitle',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey.shade100,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: onUpload,
                icon: const Icon(Icons.upload, size: 18),
                label: const Text('Upload Notice'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryCobalt,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Filters row
          Row(
            children: [
              // Search
              Expanded(
                flex: 2,
                child: _SearchField(
                  value: searchQuery,
                  onChanged: onSearchChanged,
                ),
              ),
              // Service filter - only show for ministry admin
              if (showServiceFilter && services.isNotEmpty) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _FilterDropdown(
                    value: selectedServiceId,
                    hint: 'All Services',
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('All Services'),
                      ),
                      ...services.map(
                        (s) => DropdownMenuItem<String>(
                          value: s.id,
                          child: Text(s.name),
                        ),
                      ),
                    ],
                    onChanged: onServiceChanged,
                  ),
                ),
              ],
              const SizedBox(width: 12),
              // Status filter
              Expanded(
                child: _FilterDropdown(
                  value: selectedStatus,
                  hint: 'All Status',
                  items: const [
                    DropdownMenuItem<String>(
                      value: null,
                      child: Text('All Status'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'pending',
                      child: Text('Pending'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'processing',
                      child: Text('Processing'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'completed',
                      child: Text('Completed'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'failed',
                      child: Text('Failed'),
                    ),
                  ],
                  onChanged: onStatusChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _SearchField({required this.value, required this.onChanged});

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_SearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        hintText: 'Search notices...',
        prefixIcon: const Icon(
          Icons.search,
          color: AppTheme.textMuted,
          size: 20,
        ),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(
                  Icons.clear,
                  color: AppTheme.textMuted,
                  size: 18,
                ),
                onPressed: () {
                  _controller.clear();
                  widget.onChanged('');
                },
              )
            : null,
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.primaryCobalt, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String? value;
  final String hint;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.primaryCobalt, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      items: items,
      onChanged: onChanged,
      isExpanded: true,
    );
  }
}
