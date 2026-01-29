import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// BLoC observer for debugging and logging.
/// Only logs in debug mode for cleaner production output.
class AppBlocObserver extends BlocObserver {
  // Set to true to enable verbose logging
  static const bool _verboseLogging = false;

  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    if (_verboseLogging) {
      debugPrint('🟢 Bloc Created: ${bloc.runtimeType}');
    }
  }

  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    // Always log events as they're important for debugging
    debugPrint('📤 ${bloc.runtimeType}: $event');
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    // Log state changes concisely
    debugPrint(
      '🔄 ${bloc.runtimeType}: ${change.currentState.runtimeType} → ${change.nextState.runtimeType}',
    );
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    // Skip transition logs to reduce noise (onChange already logs state changes)
    if (_verboseLogging) {
      debugPrint('🔀 Transition: ${bloc.runtimeType}');
      debugPrint('   Event: ${transition.event}');
      debugPrint(
        '   ${transition.currentState.runtimeType} → ${transition.nextState.runtimeType}',
      );
    }
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    // Always log errors
    debugPrint('❌ ${bloc.runtimeType} Error: $error');
    if (_verboseLogging) {
      debugPrint('   StackTrace: $stackTrace');
    }
    super.onError(bloc, error, stackTrace);
  }

  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    if (_verboseLogging) {
      debugPrint('🔴 Bloc Closed: ${bloc.runtimeType}');
    }
  }
}
