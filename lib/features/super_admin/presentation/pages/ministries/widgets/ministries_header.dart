import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_web/core/theme/theme.dart';
import 'package:sewa_web/features/super_admin/presentation/bloc/ministry_bloc.dart';
import 'package:sewa_web/features/super_admin/presentation/pages/ministries/widgets/ministry_shared_widgets.dart';
import 'package:sewa_web/features/super_admin/presentation/pages/ministries/widgets/place_filter_dropdown.dart';

/// Ministries Header Component with Place Filter
class MinistriesHeader extends StatefulWidget {
  final VoidCallback onRefresh;

  const MinistriesHeader({super.key, required this.onRefresh});

  @override
  State<MinistriesHeader> createState() => _MinistriesHeaderState();
}

class _MinistriesHeaderState extends State<MinistriesHeader> {
  String? _selectedPlaceId;

  void _onPlaceFilterChanged(String? placeId) {
    setState(() => _selectedPlaceId = placeId);
    // Trigger load with place filter
    context.read<MinistryBloc>().add(LoadMinistriesEvent(placeId: placeId));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          // Title
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ministries',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Manage ministries and their configurations',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
              ),
            ],
          ),
          const Spacer(),
          // Actions with inline filter
          Row(
            children: [
              // Place filter dropdown (subtle, inline)
              PlaceFilterDropdown(
                selectedPlaceId: _selectedPlaceId,
                onPlaceSelected: _onPlaceFilterChanged,
              ),
              const SizedBox(width: 12),
              // Refresh button
              OutlinedButton.icon(
                onPressed: widget.onRefresh,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textSecondary,
                  side: BorderSide(color: AppTheme.borderColor.withAlpha(150)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Add Ministry button
              Builder(
                builder: (context) => ElevatedButton.icon(
                  onPressed: () => showCreateMinistryDialog(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Ministry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryCobalt,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
