/// Core routing components for the Sewa Sathi Web Admin.
///
/// This library provides:
/// - [AuthAwareRouterDelegate] - Base class for auth-aware routing
/// - [FadePage], [SlidePage], [ScalePage] - Page transition widgets
/// - [AppRouterDelegate] - Main app router with URL sync
/// - [AppRouteInformationParser] - URL parsing for web
/// - [AppRoutePath] - Route path configuration
/// - [AppScreen] - Available screens enum
/// - [AppRoutes] - Route name constants
///
/// Usage:
/// ```dart
/// import 'package:sewa_web/core/routes/routes.dart';
///
/// // In your app widget:
/// late final AppRouterDelegate _routerDelegate;
/// late final AppRouteInformationParser _routeInformationParser;
///
/// @override
/// void initState() {
///   super.initState();
///   _routeInformationParser = AppRouteInformationParser();
///   _routerDelegate = AppRouterDelegate(
///     authBloc: widget.authBloc,
///     getMinistries: () => _ministries,
///     getIsLoadingMinistries: () => _isLoading,
///     getErrorMessage: () => _error,
///     onRetry: _fetchMinistries,
///   );
/// }
///
/// @override
/// Widget build(BuildContext context) {
///   return MaterialApp.router(
///     routerDelegate: _routerDelegate,
///     routeInformationParser: _routeInformationParser,
///     backButtonDispatcher: RootBackButtonDispatcher(),
///   );
/// }
/// ```
library routes;

export 'auth_aware_router_delegate.dart';
export 'fade_page.dart';
export 'app_router.dart';
