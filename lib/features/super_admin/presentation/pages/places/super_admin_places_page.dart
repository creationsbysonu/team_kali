import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_web/core/di/injection_container.dart' as di;
import 'package:sewa_web/core/theme/theme.dart';
import 'package:sewa_web/features/places/domain/entities/place.dart';
import 'package:sewa_web/features/places/presentation/bloc/place_bloc.dart';
import 'package:sewa_web/features/super_admin/presentation/widgets/dialogs/place_dialog.dart';

/// Super Admin Places Page - Clean professional design
/// Uses a singleton PlaceBloc to prevent multiple API calls
class SuperAdminPlacesPage extends StatefulWidget {
  const SuperAdminPlacesPage({super.key});

  @override
  State<SuperAdminPlacesPage> createState() => _SuperAdminPlacesPageState();
}

class _SuperAdminPlacesPageState extends State<SuperAdminPlacesPage> {
  late final PlaceBloc _placeBloc;

  @override
  void initState() {
    super.initState();
    // Get singleton PlaceBloc from DI
    _placeBloc = di.sl<PlaceBloc>();
    // Only load if not already loaded
    if (_placeBloc.state is PlaceInitial) {
      _placeBloc.add(const LoadAllPlacesEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _placeBloc,
      child: const _PlacesPageContent(),
    );
  }
}

class _PlacesPageContent extends StatelessWidget {
  const _PlacesPageContent();

  @override
  Widget build(BuildContext context) {
    return BlocListener<PlaceBloc, PlaceState>(
      listener: (context, state) {
        if (state is PlaceOperationSuccess) {
          _showSnackBar(context, state.message, isSuccess: true);
          context.read<PlaceBloc>().add(const LoadAllPlacesEvent());
        } else if (state is PlaceOperationError) {
          _showSnackBar(context, state.message, isSuccess: false);
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            Expanded(child: _buildContent(context)),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(
    BuildContext context,
    String message, {
    required bool isSuccess,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: isSuccess ? AppTheme.success : AppTheme.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: Duration(seconds: isSuccess ? 3 : 4),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Title
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Places',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Manage geographical locations for your ministries',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                ),
              ],
            ),
          ),
          // Actions
          const SizedBox(width: 16),
          _RefreshButton(),
          const SizedBox(width: 12),
          _AddPlaceButton(),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return BlocBuilder<PlaceBloc, PlaceState>(
      builder: (context, state) {
        if (state is PlaceLoading || state is PlaceOperationLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryCobalt),
          );
        }

        if (state is PlaceError) {
          return _ErrorView(message: state.message);
        }

        if (state is PlacesLoaded) {
          if (state.places.isEmpty) {
            return const _EmptyView();
          }
          return _PlacesTable(places: state.places);
        }

        return const SizedBox.shrink();
      },
    );
  }
}

class _RefreshButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {
        // Force refresh to reload from API
        context.read<PlaceBloc>().add(const RefreshPlacesEvent());
      },
      icon: const Icon(Icons.refresh, size: 18),
      label: const Text('Refresh'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.textSecondary,
        side: const BorderSide(color: AppTheme.borderColor),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _AddPlaceButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _showAddDialog(context),
      icon: const Icon(Icons.add, size: 18),
      label: const Text('Add Place'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryCobalt,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    PlaceDialog.showAdd(
      context,
      onSubmit: (name, slug) {
        context.read<PlaceBloc>().add(CreatePlaceEvent(name: name, slug: slug));
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;

  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.error.withAlpha(15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 48,
                color: AppTheme.error.withAlpha(180),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Something went wrong',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                context.read<PlaceBloc>().add(const LoadAllPlacesEvent());
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryCobalt.withAlpha(15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_city_outlined,
                size: 56,
                color: AppTheme.primaryCobalt.withAlpha(180),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No places yet',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Get started by adding your first place',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () {
                PlaceDialog.showAdd(
                  context,
                  onSubmit: (name, slug) {
                    context.read<PlaceBloc>().add(
                      CreatePlaceEvent(name: name, slug: slug),
                    );
                  },
                );
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Your First Place'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryCobalt,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlacesTable extends StatelessWidget {
  final List<Place> places;

  const _PlacesTable({required this.places});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Table Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: AppTheme.backgroundLight,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: const Row(
                children: [
                  _TableHeaderCell(title: 'Place Name', flex: 3),
                  _TableHeaderCell(title: 'Slug', flex: 2),
                  _TableHeaderCell(title: 'Status', flex: 1, center: true),
                  SizedBox(
                    width: 100,
                    child: Text(
                      'Actions',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            // Divider
            Container(height: 1, color: AppTheme.borderColor.withAlpha(100)),
            // Table Rows
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: places.length,
              separatorBuilder: (_, __) => Container(
                height: 1,
                color: AppTheme.borderColor.withAlpha(50),
              ),
              itemBuilder: (context, index) {
                return _PlaceRow(place: places[index]);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TableHeaderCell extends StatelessWidget {
  final String title;
  final int flex;
  final bool center;

  const _TableHeaderCell({
    required this.title,
    this.flex = 1,
    this.center = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        textAlign: center ? TextAlign.center : TextAlign.start,
      ),
    );
  }
}

class _PlaceRow extends StatelessWidget {
  final Place place;

  const _PlaceRow({required this.place});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Name with icon
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryCobalt.withAlpha(15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.location_city,
                    color: AppTheme.primaryCobalt,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    place.name,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Slug
          Expanded(
            flex: 2,
            child: Text(
              place.slug,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 13,
                fontFamily: 'monospace',
              ),
            ),
          ),
          // Status
          Expanded(
            flex: 1,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: place.isActive
                      ? AppTheme.success.withAlpha(15)
                      : AppTheme.warning.withAlpha(15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  place.isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    color: place.isActive ? AppTheme.success : AppTheme.warning,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
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
                  icon: Icons.edit_outlined,
                  tooltip: 'Edit',
                  color: AppTheme.primaryCobalt,
                  onPressed: () => _showEditDialog(context),
                ),
                const SizedBox(width: 4),
                _ActionButton(
                  icon: Icons.delete_outline,
                  tooltip: 'Delete',
                  color: AppTheme.error,
                  onPressed: () => _showDeleteDialog(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    PlaceDialog.showEdit(
      context,
      place: place,
      onSubmit: (name, slug, isActive) {
        context.read<PlaceBloc>().add(
          UpdatePlaceEvent(id: place.id, name: name, isActive: isActive),
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context) {
    DeletePlaceDialog.show(
      context,
      place: place,
      onConfirm: () {
        context.read<PlaceBloc>().add(DeletePlaceEvent(id: place.id));
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
            child: Icon(icon, color: color.withAlpha(180), size: 18),
          ),
        ),
      ),
    );
  }
}
