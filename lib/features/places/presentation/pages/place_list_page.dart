import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_web/core/theme/theme.dart';
import 'package:sewa_web/features/places/domain/entities/place.dart';
import 'package:sewa_web/features/places/presentation/bloc/place_bloc.dart';

/// Page for selecting a place from the list
/// Displayed after user chooses to go to ministry or staff login
class PlaceListPage extends StatelessWidget {
  final Function(Place place) onPlaceSelected;
  final VoidCallback onBack;

  const PlaceListPage({
    super.key,
    required this.onPlaceSelected,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryCobaltDark,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),

            // Place list
            Expanded(
              child: BlocBuilder<PlaceBloc, PlaceState>(
                builder: (context, state) {
                  if (state is PlaceLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }

                  if (state is PlaceError) {
                    return _buildErrorState(context, state.message);
                  }

                  if (state is PlacesLoaded) {
                    if (state.places.isEmpty) {
                      return _buildEmptyState();
                    }
                    return _buildPlaceGrid(state.places);
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: onBack,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Place',
                  style: AppTheme.headingMedium().copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose your location to continue',
                  style: AppTheme.bodyMedium().copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppTheme.accentRed, size: 64),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTheme.bodyLarge().copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              context.read<PlaceBloc>().add(const LoadPublicPlacesEvent());
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentBlue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.location_off, color: Colors.white54, size: 64),
          const SizedBox(height: 16),
          Text(
            'No places available',
            style: AppTheme.bodyLarge().copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceGrid(List<Place> places) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: places.length,
      itemBuilder: (context, index) => _PlaceCard(
        place: places[index],
        onTap: () => onPlaceSelected(places[index]),
      ),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  final Place place;
  final VoidCallback onTap;

  const _PlaceCard({required this.place, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.accentBlue.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.location_city,
                  color: AppTheme.accentBlue,
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                place.name,
                style: AppTheme.headingSmall().copyWith(
                  color: AppTheme.primaryCobaltDark,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
