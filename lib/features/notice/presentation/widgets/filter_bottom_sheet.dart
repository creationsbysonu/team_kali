import 'package:flutter/material.dart';
import 'package:sewa_sathi/core/di/injection_container.dart' as di;
import 'package:sewa_sathi/core/usecases/usecase.dart';
import 'package:sewa_sathi/features/notice/domain/entities/filter_options_entity.dart';
import 'package:sewa_sathi/features/notice/domain/entities/ministry_entity.dart';
import 'package:sewa_sathi/features/notice/domain/entities/service_entity.dart';
import 'package:sewa_sathi/features/notice/domain/usecases/notice_usecases.dart';

/// Filter bottom sheet for notices.
///
/// Allows filtering by:
/// - Ministry
/// - Service
/// - File type (PDF, Image)
class FilterBottomSheet extends StatefulWidget {
  final NoticeParams currentParams;
  final Function(NoticeParams) onApply;

  const FilterBottomSheet({
    super.key,
    required this.currentParams,
    required this.onApply,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  String? _selectedMinistryId;
  String? _selectedServiceId;
  String? _selectedFileType;

  List<ServiceEntity> _availableServices = [];

  // Load filter options directly without bloc state
  late Future<FilterOptionsEntity?> _filterOptionsFuture;

  @override
  void initState() {
    super.initState();
    _selectedMinistryId = widget.currentParams.ministryId;
    _selectedServiceId = widget.currentParams.serviceId;
    _selectedFileType = widget.currentParams.fileType;

    // Load filter options directly
    _filterOptionsFuture = _loadFilterOptions();
  }

  Future<FilterOptionsEntity?> _loadFilterOptions() async {
    final useCase = di.sl<GetFilterOptionsUseCase>();
    final result = await useCase(const NoParams());
    return result.fold((failure) => null, (options) => options);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Text(
                      'Filter Notices',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _clearFilters,
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
              ),

              const Divider(),

              // Filter options
              Expanded(
                child: FutureBuilder<FilterOptionsEntity?>(
                  future: _filterOptionsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError || snapshot.data == null) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Failed to load filters',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _filterOptionsFuture = _loadFilterOptions();
                                });
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }

                    final options = snapshot.data!;

                    // Update available services when ministry changes
                    if (_selectedMinistryId != null) {
                      _availableServices = options.services
                          .where(
                            (s) =>
                                s.ministryId == _selectedMinistryId ||
                                s.ministry?.id == _selectedMinistryId,
                          )
                          .toList();
                    } else {
                      _availableServices = options.services;
                    }

                    return _buildFilterContent(scrollController, options);
                  },
                ),
              ),

              // Apply button
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0047AB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Apply Filters',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build filter content.
  Widget _buildFilterContent(
    ScrollController scrollController,
    FilterOptionsEntity options,
  ) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        // Ministry filter
        _buildFilterSection(
          title: 'Ministry',
          child: _buildMinistryDropdown(options.ministries),
        ),

        const SizedBox(height: 16),

        // Service filter
        _buildFilterSection(title: 'Service', child: _buildServiceDropdown()),

        const SizedBox(height: 16),

        // File type filter
        _buildFilterSection(
          title: 'File Type',
          child: _buildFileTypeChips(options.fileTypes),
        ),
      ],
    );
  }

  /// Build filter section with title.
  Widget _buildFilterSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A2E),
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  /// Build ministry dropdown.
  Widget _buildMinistryDropdown(List<MinistryEntity> ministries) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _selectedMinistryId,
          hint: const Text('Select Ministry'),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('All Ministries'),
            ),
            ...ministries.map((ministry) {
              return DropdownMenuItem<String>(
                value: ministry.id,
                child: Text(ministry.name),
              );
            }),
          ],
          onChanged: (value) {
            setState(() {
              _selectedMinistryId = value;
              // Clear service if ministry changes
              if (_selectedMinistryId != _selectedServiceId) {
                _selectedServiceId = null;
              }
            });
          },
        ),
      ),
    );
  }

  /// Build service dropdown.
  Widget _buildServiceDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _selectedServiceId,
          hint: const Text('Select Service'),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('All Services'),
            ),
            ..._availableServices.map((service) {
              return DropdownMenuItem<String>(
                value: service.id,
                child: Text(service.name),
              );
            }),
          ],
          onChanged: (value) {
            setState(() {
              _selectedServiceId = value;
            });
          },
        ),
      ),
    );
  }

  /// Build file type chips.
  Widget _buildFileTypeChips(List<String> fileTypes) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        // All types chip
        ChoiceChip(
          label: const Text('All Types'),
          selected: _selectedFileType == null,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _selectedFileType = null;
              });
            }
          },
          selectedColor: const Color(0xFF0047AB),
          labelStyle: TextStyle(
            color: _selectedFileType == null ? Colors.white : Colors.black,
          ),
        ),
        // File type chips
        ...fileTypes.map((fileType) {
          final label = fileType.toUpperCase();
          return ChoiceChip(
            label: Text(label),
            selected: _selectedFileType == fileType,
            onSelected: (selected) {
              setState(() {
                _selectedFileType = selected ? fileType : null;
              });
            },
            selectedColor: const Color(0xFF0047AB),
            labelStyle: TextStyle(
              color: _selectedFileType == fileType
                  ? Colors.white
                  : Colors.black,
            ),
          );
        }),
      ],
    );
  }

  /// Clear all filters.
  void _clearFilters() {
    setState(() {
      _selectedMinistryId = null;
      _selectedServiceId = null;
      _selectedFileType = null;
    });
  }

  /// Apply filters and close bottom sheet.
  void _applyFilters() {
    final params = NoticeParams(
      ministryId: _selectedMinistryId,
      serviceId: _selectedServiceId,
      fileType: _selectedFileType,
      search: widget.currentParams.search,
    );

    widget.onApply(params);
    Navigator.pop(context);
  }
}
