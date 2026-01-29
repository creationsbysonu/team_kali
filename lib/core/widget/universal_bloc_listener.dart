import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_web/core/widget/global_operation_overlay.dart';
import 'package:sewa_web/features/places/presentation/bloc/place_bloc.dart';
import 'package:sewa_web/features/services/presentation/bloc/service_bloc.dart';
import 'package:sewa_web/features/staff/presentation/bloc/staff_bloc.dart';
import 'package:sewa_web/features/super_admin/presentation/bloc/ministry_bloc.dart';

/// A universal bloc listener that automatically shows/hides the global
/// operation overlay based on bloc states across the entire app.
///
/// This listener dynamically detects which blocs are available in the widget
/// tree and only listens to those that exist.
///
/// Usage:
/// ```dart
/// UniversalBlocListener(
///   child: YourPageContent(),
/// )
/// ```
class UniversalBlocListener extends StatelessWidget {
  final Widget child;

  const UniversalBlocListener({super.key, required this.child});

  /// Helper to check if a bloc is available in the context
  static T? _tryGetBloc<T extends StateStreamableSource<Object?>>(
    BuildContext context,
  ) {
    try {
      return context.read<T>();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Build the list of listeners dynamically based on available blocs
    final List<BlocListenerBase> listeners = [];

    // Check and add Ministry Bloc Listener
    if (_tryGetBloc<MinistryBloc>(context) != null) {
      listeners.add(
        BlocListener<MinistryBloc, MinistryState>(
          listener: (context, state) {
            _handleMinistryState(context, state);
          },
        ),
      );
    }

    // Check and add Place Bloc Listener
    if (_tryGetBloc<PlaceBloc>(context) != null) {
      listeners.add(
        BlocListener<PlaceBloc, PlaceState>(
          listener: (context, state) {
            _handlePlaceState(context, state);
          },
        ),
      );
    }

    // Check and add Staff Bloc Listener
    if (_tryGetBloc<StaffBloc>(context) != null) {
      listeners.add(
        BlocListener<StaffBloc, StaffState>(
          listener: (context, state) {
            _handleStaffState(context, state);
          },
        ),
      );
    }

    // Check and add Service Bloc Listener
    if (_tryGetBloc<ServiceBloc>(context) != null) {
      listeners.add(
        BlocListener<ServiceBloc, ServiceState>(
          listener: (context, state) {
            _handleServiceState(context, state);
          },
        ),
      );
    }

    // If no blocs are available, just return the child
    if (listeners.isEmpty) {
      return child;
    }

    return MultiBlocListener(listeners: listeners, child: child);
  }

  void _handleMinistryState(BuildContext context, MinistryState state) {
    // Show overlay for operation states
    if (state is MinistryCreating) {
      GlobalOperationOverlay.show(message: 'Creating ministry');
    } else if (state is MinistryUpdating) {
      GlobalOperationOverlay.show(message: 'Updating ministry');
    }
    // Hide overlay and show result for completion states
    else if (state is MinistryCreated) {
      GlobalOperationOverlay.hide();
      _showSuccessSnackbar(context, 'Ministry created successfully!');
    } else if (state is MinistryUpdated) {
      GlobalOperationOverlay.hide();
      _showSuccessSnackbar(context, 'Ministry updated successfully!');
    } else if (state is MinistryActivated) {
      GlobalOperationOverlay.hide();
      _showSuccessSnackbar(context, 'Ministry activated successfully!');
    } else if (state is MinistrySuspended) {
      GlobalOperationOverlay.hide();
      _showSuccessSnackbar(context, 'Ministry suspended');
    } else if (state is MinistryDeleted) {
      GlobalOperationOverlay.hide();
      _showSuccessSnackbar(context, 'Ministry moved to trash');
    } else if (state is MinistryRestored) {
      GlobalOperationOverlay.hide();
      _showSuccessSnackbar(context, 'Ministry restored successfully!');
    } else if (state is MinistryHardDeleted) {
      GlobalOperationOverlay.hide();
      _showSuccessSnackbar(context, 'Ministry permanently deleted');
    } else if (state is MinistryPasswordReset) {
      GlobalOperationOverlay.hide();
      _showSuccessSnackbar(context, 'Password reset successfully!');
    } else if (state is MinistryOperationError) {
      GlobalOperationOverlay.hide();
      _showErrorSnackbar(context, state.message);
    }
    // Also hide overlay for loaded states (in case of navigation issues)
    else if (state is MinistryLoaded || state is DeletedMinistriesLoaded) {
      // Only hide if no other operation is in progress
      if (GlobalOperationOverlay.isShowing) {
        GlobalOperationOverlay.hide();
      }
    }
  }

  void _handlePlaceState(BuildContext context, PlaceState state) {
    if (state is PlaceOperationLoading) {
      GlobalOperationOverlay.show(message: 'Processing');
    } else if (state is PlaceOperationSuccess) {
      GlobalOperationOverlay.hide();
      _showSuccessSnackbar(context, state.message);
    } else if (state is PlaceOperationError) {
      GlobalOperationOverlay.hide();
      _showErrorSnackbar(context, state.message);
    }
  }

  void _handleStaffState(BuildContext context, StaffState state) {
    if (state is StaffOperationLoading) {
      GlobalOperationOverlay.show(message: 'Processing');
    } else if (state is StaffOperationSuccess) {
      GlobalOperationOverlay.hide();
      _showSuccessSnackbar(context, state.message);
    } else if (state is StaffOperationError) {
      GlobalOperationOverlay.hide();
      _showErrorSnackbar(context, state.message);
    }
  }

  void _handleServiceState(BuildContext context, ServiceState state) {
    if (state is ServiceOperationLoading) {
      GlobalOperationOverlay.show(message: 'Processing');
    } else if (state is ServiceOperationSuccess) {
      GlobalOperationOverlay.hide();
      _showSuccessSnackbar(context, state.message);
    } else if (state is ServiceOperationError) {
      GlobalOperationOverlay.hide();
      _showErrorSnackbar(context, state.message);
    }
  }

  void _showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFE94560),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}

/// Extension to add operation states check
extension MinistryStateOperationCheck on MinistryState {
  bool get isOperating => this is MinistryCreating || this is MinistryUpdating;
}

extension PlaceStateOperationCheck on PlaceState {
  bool get isOperating => this is PlaceOperationLoading;
}

extension StaffStateOperationCheck on StaffState {
  bool get isOperating => this is StaffOperationLoading;
}

extension ServiceStateOperationCheck on ServiceState {
  bool get isOperating => this is ServiceOperationLoading;
}
