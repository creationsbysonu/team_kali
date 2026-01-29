import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_web/core/theme/theme.dart';
import 'package:sewa_web/features/super_admin/presentation/bloc/ministry_bloc.dart';

/// Place Filter Dropdown Widget
/// Displays a clean, minimalist dropdown for filtering ministries by place
class PlaceFilterDropdown extends StatefulWidget {
  final String? selectedPlaceId;
  final Function(String?) onPlaceSelected;

  const PlaceFilterDropdown({
    super.key,
    this.selectedPlaceId,
    required this.onPlaceSelected,
  });

  @override
  State<PlaceFilterDropdown> createState() => _PlaceFilterDropdownState();
}

class _PlaceFilterDropdownState extends State<PlaceFilterDropdown> {
  @override
  void initState() {
    super.initState();
    // Load places when widget initializes
    context.read<MinistryBloc>().add(LoadPlacesForFilterEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MinistryBloc, MinistryState>(
      builder: (context, state) {
        // Get places from bloc cache
        final places = context.read<MinistryBloc>().cachedPlaces;

        // Show loading indicator while places are being fetched
        if (places.isEmpty && state is MinistryLoading) {
          return Container(
            width: 160,
            height: 36,
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.borderColor.withAlpha(100)),
              borderRadius: BorderRadius.circular(6),
              color: Colors.grey.shade50,
            ),
            child: const Center(
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.textMuted,
                ),
              ),
            ),
          );
        }

        return Container(
          width: 160,
          height: 36,
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.borderColor.withAlpha(100)),
            borderRadius: BorderRadius.circular(6),
            color: Colors.grey.shade50,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: widget.selectedPlaceId,
              hint: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'All Places',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
              ),
              isExpanded: true,
              icon: const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(
                  Icons.filter_list,
                  size: 16,
                  color: AppTheme.textMuted,
                ),
              ),
              items: [
                // "All Places" option
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'All Places',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                // Individual place options
                ...places.map(
                  (place) => DropdownMenuItem<String?>(
                    value: place.id,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        place.displayText,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
              onChanged: (placeId) {
                widget.onPlaceSelected(placeId);
              },
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(6),
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        );
      },
    );
  }
}
