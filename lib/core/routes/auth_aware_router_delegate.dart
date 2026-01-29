import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Base class for creating auth-aware router delegates.
///
/// This delegate automatically handles:
/// - Listening to auth state changes from BLoC
/// - Navigating to authenticated/unauthenticated screens
/// - Proper disposal of stream subscriptions
/// - URL synchronization with browser history
///
/// Example usage:
/// ```dart
/// class MyRouterDelegate extends AuthAwareRouterDelegate<MyRoutePath, MyScreen, MyAuthBloc, MyAuthState> {
///   MyRouterDelegate({required super.authBloc});
///
///   @override
///   bool isAuthenticated(MyAuthState state) => state is Authenticated;
///
///   @override
///   bool isUnauthenticated(MyAuthState state) => state is Unauthenticated;
///
///   @override
///   MyScreen get authenticatedScreen => MyScreen.dashboard;
///
///   @override
///   MyScreen get unauthenticatedScreen => MyScreen.login;
///
///   @override
///   Widget build(BuildContext context) {
///     return Navigator(
///       key: navigatorKey,
///       pages: buildPages(),
///       onDidRemovePage: handlePageRemoved,
///     );
///   }
/// }
/// ```
abstract class AuthAwareRouterDelegate<
  TRoutePath,
  TScreen extends Enum,
  TBloc extends BlocBase<TState>,
  TState
>
    extends RouterDelegate<TRoutePath>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<TRoutePath> {
  /// The auth BLoC to listen to for state changes
  final TBloc authBloc;

  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Current screen being displayed
  TScreen _currentScreen;

  /// Stream subscription for auth state changes
  StreamSubscription<TState>? _authSubscription;

  /// Whether the delegate has been disposed
  bool _isDisposed = false;

  /// Get the current screen
  TScreen get currentScreen => _currentScreen;

  /// Set the current screen and notify listeners
  set currentScreen(TScreen screen) {
    if (_currentScreen != screen) {
      _currentScreen = screen;
      if (!_isDisposed) {
        notifyListeners();
      }
    }
  }

  AuthAwareRouterDelegate({
    required this.authBloc,
    required TScreen initialScreen,
  }) : _currentScreen = initialScreen {
    // Check initial auth state
    final currentState = authBloc.state;
    if (isAuthenticated(currentState)) {
      _currentScreen = authenticatedScreen;
    }

    // Listen to future auth state changes
    _authSubscription = authBloc.stream.listen((state) {
      if (_isDisposed) return;

      if (isAuthenticated(state)) {
        debugPrint(
          'Router: User authenticated, navigating to authenticated screen',
        );
        currentScreen = authenticatedScreen;
        // Note: Do NOT clear browser history here - it breaks URL preservation on refresh
      } else if (isUnauthenticated(state)) {
        debugPrint(
          'Router: User unauthenticated, navigating to unauthenticated screen',
        );
        onUnauthenticated();
      }
    });
  }

  /// Override to check if the given state represents an authenticated user
  bool isAuthenticated(TState state);

  /// Override to check if the given state represents an unauthenticated user
  bool isUnauthenticated(TState state);

  /// The screen to navigate to when authenticated
  TScreen get authenticatedScreen;

  /// The screen to navigate to when unauthenticated
  TScreen get unauthenticatedScreen;

  /// Called when user becomes unauthenticated.
  /// Override to reset any stored state (e.g., selected ministry).
  void onUnauthenticated() {
    currentScreen = unauthenticatedScreen;
  }

  /// Notify that data has changed and UI should be updated
  void notifyDataChanged() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  /// Navigate to a specific screen
  void navigateTo(TScreen screen) {
    currentScreen = screen;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _authSubscription?.cancel();
    super.dispose();
  }
}

/// Mixin for router delegates that need to handle authenticated route guards.
///
/// This prevents users from navigating to non-authenticated routes
/// when they are already authenticated.
mixin AuthenticatedRouteGuard<
  TRoutePath,
  TScreen extends Enum,
  TBloc extends BlocBase<TState>,
  TState
>
    on AuthAwareRouterDelegate<TRoutePath, TScreen, TBloc, TState> {
  /// Check if the given screen requires authentication
  bool requiresAuthentication(TScreen screen);

  /// Check if navigation to the given screen should be blocked
  bool shouldBlockNavigation(TScreen targetScreen) {
    final state = authBloc.state;

    // If user is authenticated and trying to go to a non-authenticated screen
    if (isAuthenticated(state) && !requiresAuthentication(targetScreen)) {
      debugPrint(
        'Router: User is authenticated, blocking navigation to $targetScreen',
      );
      return true;
    }

    return false;
  }
}
