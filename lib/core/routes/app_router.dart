import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_web/core/routes/auth_aware_router_delegate.dart';
import 'package:sewa_web/core/routes/fade_page.dart';
import 'package:sewa_web/core/widget/dashboard_shell.dart';
import 'package:sewa_web/features/auth/domain/entities/ministry.dart';
import 'package:sewa_web/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sewa_web/features/auth/presentation/bloc/ministry_list_bloc.dart';
import 'package:sewa_web/features/auth/presentation/pages/login_page.dart';
import 'package:sewa_web/features/auth/presentation/pages/ministry_list_page.dart';
import 'package:sewa_web/features/auth/presentation/pages/role_selection_page.dart';
import 'package:sewa_web/features/ministry/data/models/staff_service_model.dart';
import 'package:sewa_web/features/ministry/presentation/pages/ministry_shell.dart';
import 'package:sewa_web/features/places/domain/entities/place.dart';
import 'package:sewa_web/features/places/presentation/pages/place_list_page.dart';
import 'package:sewa_web/features/places/presentation/pages/place_selection_page.dart';
import 'package:sewa_web/features/staff/presentation/bloc/staff_services_bloc.dart';
import 'package:sewa_web/features/staff/presentation/pages/public_services_page.dart';
import 'package:sewa_web/features/staff/presentation/pages/staff_shell.dart';

/// Route names for URL-based navigation
class AppRoutes {
  static const String roleSelection = '/';
  static const String places = '/places';
  static const String placeSelected = '/places/selected';
  static const String ministries = '/ministries';
  static const String services = '/services';
  static const String loginSuperAdmin = '/login/super-admin';
  static const String loginMinistry = '/login/ministry';
  static const String loginStaff = '/login/staff';
  static const String dashboard = '/dashboard';
}

/// Screens available in the app
enum AppScreen {
  roleSelection,
  places,
  placeSelected,
  ministries,
  services,
  loginSuperAdmin,
  loginMinistry,
  loginStaff,
  dashboard,
}

/// Login flow type
enum LoginFlow { ministryAdmin, staff }

/// Route path configuration for URL parsing
class AppRoutePath {
  final AppScreen screen;
  final String? placeSlug;
  final String? ministrySlug;
  final String? serviceSlug;

  AppRoutePath.roleSelection()
    : screen = AppScreen.roleSelection,
      placeSlug = null,
      ministrySlug = null,
      serviceSlug = null;

  AppRoutePath.places()
    : screen = AppScreen.places,
      placeSlug = null,
      ministrySlug = null,
      serviceSlug = null;

  AppRoutePath.placeSelected(this.placeSlug)
    : screen = AppScreen.placeSelected,
      ministrySlug = null,
      serviceSlug = null;

  AppRoutePath.ministries(this.placeSlug)
    : screen = AppScreen.ministries,
      ministrySlug = null,
      serviceSlug = null;

  AppRoutePath.services(this.placeSlug, this.ministrySlug)
    : screen = AppScreen.services,
      serviceSlug = null;

  AppRoutePath.loginSuperAdmin()
    : screen = AppScreen.loginSuperAdmin,
      placeSlug = null,
      ministrySlug = null,
      serviceSlug = null;

  AppRoutePath.loginMinistry(this.placeSlug, this.ministrySlug)
    : screen = AppScreen.loginMinistry,
      serviceSlug = null;

  AppRoutePath.loginStaff(this.placeSlug, this.ministrySlug, this.serviceSlug)
    : screen = AppScreen.loginStaff;

  AppRoutePath.dashboard()
    : screen = AppScreen.dashboard,
      placeSlug = null,
      ministrySlug = null,
      serviceSlug = null;
}

/// Route information parser for URL handling
class AppRouteInformationParser extends RouteInformationParser<AppRoutePath> {
  @override
  Future<AppRoutePath> parseRouteInformation(
    RouteInformation routeInformation,
  ) async {
    final uri = routeInformation.uri;
    final segments = uri.pathSegments;

    // /places
    if (segments.length == 1 && segments[0] == 'places') {
      return AppRoutePath.places();
    }
    // /places/{slug}
    else if (segments.length == 2 && segments[0] == 'places') {
      return AppRoutePath.placeSelected(segments[1]);
    }
    // /places/{slug}/ministries
    else if (segments.length == 3 &&
        segments[0] == 'places' &&
        segments[2] == 'ministries') {
      return AppRoutePath.ministries(segments[1]);
    }
    // /places/{slug}/ministries/{ministry}/services
    else if (segments.length == 5 &&
        segments[0] == 'places' &&
        segments[2] == 'ministries' &&
        segments[4] == 'services') {
      return AppRoutePath.services(segments[1], segments[3]);
    }
    // /login/super-admin
    else if (segments.length == 2 &&
        segments[0] == 'login' &&
        segments[1] == 'super-admin') {
      return AppRoutePath.loginSuperAdmin();
    }
    // /login/ministry/{place}/{ministry}
    else if (segments.length == 4 &&
        segments[0] == 'login' &&
        segments[1] == 'ministry') {
      return AppRoutePath.loginMinistry(segments[2], segments[3]);
    }
    // /login/staff/{place}/{ministry}/{service}
    else if (segments.length == 5 &&
        segments[0] == 'login' &&
        segments[1] == 'staff') {
      return AppRoutePath.loginStaff(segments[2], segments[3], segments[4]);
    }
    // /dashboard
    else if (segments.length == 1 && segments[0] == 'dashboard') {
      return AppRoutePath.dashboard();
    }
    // Default: role selection
    return AppRoutePath.roleSelection();
  }

  @override
  RouteInformation? restoreRouteInformation(AppRoutePath configuration) {
    switch (configuration.screen) {
      case AppScreen.roleSelection:
        return RouteInformation(uri: Uri.parse('/'));
      case AppScreen.places:
        return RouteInformation(uri: Uri.parse('/places'));
      case AppScreen.placeSelected:
        final slug = configuration.placeSlug ?? 'unknown';
        return RouteInformation(uri: Uri.parse('/places/$slug'));
      case AppScreen.ministries:
        final placeSlug = configuration.placeSlug ?? 'unknown';
        return RouteInformation(
          uri: Uri.parse('/places/$placeSlug/ministries'),
        );
      case AppScreen.services:
        final placeSlug = configuration.placeSlug ?? 'unknown';
        final ministrySlug = configuration.ministrySlug ?? 'unknown';
        return RouteInformation(
          uri: Uri.parse(
            '/places/$placeSlug/ministries/$ministrySlug/services',
          ),
        );
      case AppScreen.loginSuperAdmin:
        return RouteInformation(uri: Uri.parse('/login/super-admin'));
      case AppScreen.loginMinistry:
        final placeSlug = configuration.placeSlug ?? 'unknown';
        final ministrySlug = configuration.ministrySlug ?? 'unknown';
        return RouteInformation(
          uri: Uri.parse('/login/ministry/$placeSlug/$ministrySlug'),
        );
      case AppScreen.loginStaff:
        final placeSlug = configuration.placeSlug ?? 'unknown';
        final ministrySlug = configuration.ministrySlug ?? 'unknown';
        final serviceSlug = configuration.serviceSlug ?? 'unknown';
        return RouteInformation(
          uri: Uri.parse('/login/staff/$placeSlug/$ministrySlug/$serviceSlug'),
        );
      case AppScreen.dashboard:
        return RouteInformation(uri: Uri.parse('/dashboard'));
    }
  }
}

/// Main app router delegate with auth awareness and URL sync
class AppRouterDelegate
    extends
        AuthAwareRouterDelegate<AppRoutePath, AppScreen, AuthBloc, AuthState>
    with AuthenticatedRouteGuard<AppRoutePath, AppScreen, AuthBloc, AuthState> {
  // Callback when place is selected (to trigger ministry loading)
  final void Function(String placeSlug)? onPlaceSelected;

  // Callback when ministry is selected for staff login (to trigger service loading)
  final void Function(String placeSlug, String ministrySlug)?
  onMinistrySelectedForStaff;

  /// Currently selected place
  Place? _selectedPlace;

  /// Currently selected ministry
  Ministry? _selectedMinistry;

  /// Currently selected service (for staff login)
  StaffServiceModel? _selectedService;

  /// Current login flow type
  LoginFlow? _loginFlow;

  AppRouterDelegate({
    required super.authBloc,
    this.onPlaceSelected,
    this.onMinistrySelectedForStaff,
  }) : super(initialScreen: AppScreen.roleSelection);

  @override
  bool isAuthenticated(AuthState state) => state is Authenticated;

  @override
  bool isUnauthenticated(AuthState state) => state is UnAuthenticated;

  @override
  AppScreen get authenticatedScreen => AppScreen.dashboard;

  @override
  AppScreen get unauthenticatedScreen => AppScreen.roleSelection;

  @override
  bool requiresAuthentication(AppScreen screen) =>
      screen == AppScreen.dashboard;

  @override
  void onUnauthenticated() {
    _selectedPlace = null;
    _selectedMinistry = null;
    _selectedService = null;
    _loginFlow = null;
    super.onUnauthenticated();
  }

  @override
  AppRoutePath get currentConfiguration {
    switch (currentScreen) {
      case AppScreen.roleSelection:
        return AppRoutePath.roleSelection();
      case AppScreen.places:
        return AppRoutePath.places();
      case AppScreen.placeSelected:
        return AppRoutePath.placeSelected(_selectedPlace?.slug);
      case AppScreen.ministries:
        return AppRoutePath.ministries(_selectedPlace?.slug);
      case AppScreen.services:
        return AppRoutePath.services(
          _selectedPlace?.slug,
          _selectedMinistry?.slug,
        );
      case AppScreen.loginSuperAdmin:
        return AppRoutePath.loginSuperAdmin();
      case AppScreen.loginMinistry:
        return AppRoutePath.loginMinistry(
          _selectedPlace?.slug,
          _selectedMinistry?.slug,
        );
      case AppScreen.loginStaff:
        return AppRoutePath.loginStaff(
          _selectedPlace?.slug,
          _selectedMinistry?.slug,
          _selectedService?.serviceName.toLowerCase().replaceAll(' ', '-'),
        );
      case AppScreen.dashboard:
        return AppRoutePath.dashboard();
    }
  }

  @override
  Future<void> setNewRoutePath(AppRoutePath configuration) async {
    if (shouldBlockNavigation(configuration.screen)) {
      return;
    }

    currentScreen = configuration.screen;

    // ============ UNIVERSAL STATE RESTORATION ============
    // This handles browser reload for ALL screens by:
    // 1. Reconstructing entity objects from URL slugs
    // 2. Triggering appropriate API calls to fetch actual data
    // 3. Inferring login flow context from screen type

    bool shouldLoadMinistries = false;
    bool shouldLoadServices = false;

    // ============ PLACE RESTORATION ============
    if (configuration.placeSlug != null) {
      if (_selectedPlace == null ||
          _selectedPlace!.slug != configuration.placeSlug) {
        _selectedPlace = Place(
          id: '',
          name: _formatSlugToName(configuration.placeSlug!),
          slug: configuration.placeSlug!,
        );

        // Trigger ministry loading for any screen that needs place data
        if (configuration.screen == AppScreen.placeSelected ||
            configuration.screen == AppScreen.ministries ||
            configuration.screen == AppScreen.services ||
            configuration.screen == AppScreen.loginMinistry ||
            configuration.screen == AppScreen.loginStaff) {
          shouldLoadMinistries = true;
        }
      }
    }

    // ============ MINISTRY RESTORATION ============
    if (configuration.ministrySlug != null) {
      if (_selectedMinistry == null ||
          _selectedMinistry!.slug != configuration.ministrySlug) {
        _selectedMinistry = Ministry(
          id: '',
          name: _formatSlugToName(configuration.ministrySlug!),
          slug: configuration.ministrySlug!,
        );

        // Infer login flow based on target screen
        if (configuration.screen == AppScreen.services ||
            configuration.screen == AppScreen.loginStaff) {
          _loginFlow = LoginFlow.staff;
          shouldLoadServices = true;
        } else if (configuration.screen == AppScreen.loginMinistry) {
          _loginFlow = LoginFlow.ministryAdmin;
          // Also load ministries to get full ministry data (including logo)
          if (_selectedPlace != null) {
            shouldLoadMinistries = true;
          }
        }
      }
    }

    // ============ LOGIN FLOW INFERENCE ============
    // Universal login flow detection for any screen in the flow
    if (_loginFlow == null) {
      // Check screen type to infer flow
      if (configuration.screen == AppScreen.services ||
          configuration.screen == AppScreen.loginStaff) {
        _loginFlow = LoginFlow.staff;
      } else if (configuration.screen == AppScreen.loginMinistry) {
        _loginFlow = LoginFlow.ministryAdmin;
      } else if (configuration.screen == AppScreen.ministries) {
        // At ministries screen - default to staff flow (most common)
        // This handles the case where user bookmarks/reloads ministries page
        _loginFlow = LoginFlow.staff;
      }
    }

    // ============ SERVICE RESTORATION ============
    if (configuration.serviceSlug != null) {
      if (_selectedService == null ||
          _selectedService!.serviceName.toLowerCase().replaceAll(' ', '-') !=
              configuration.serviceSlug) {
        _selectedService = StaffServiceModel(
          id: '',
          serviceName: _formatSlugToName(configuration.serviceSlug!),
          staffName: '',
          email: '',
          status: 'active',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Always load services when we have a service slug
        // This ensures we get actual staff name and image
        if (_selectedPlace != null && _selectedMinistry != null) {
          shouldLoadServices = true;
        }
      }
    }

    // ============ TRIGGER DATA LOADING ============
    // Call the appropriate callbacks to fetch data from backend
    // This ensures all necessary data is available after reload

    if (shouldLoadMinistries &&
        _selectedPlace != null &&
        onPlaceSelected != null) {
      // Load ministries for the selected place
      onPlaceSelected!(_selectedPlace!.slug);
    }

    if (shouldLoadServices &&
        _selectedPlace != null &&
        _selectedMinistry != null &&
        onMinistrySelectedForStaff != null) {
      // Load services for the selected ministry
      onMinistrySelectedForStaff!(
        _selectedPlace!.slug,
        _selectedMinistry!.slug,
      );
    }

    notifyListeners();
  }

  String _formatSlugToName(String slug) {
    return slug
        .split('-')
        .map(
          (word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1)}'
              : '',
        )
        .join(' ');
  }

  // ============ Navigation Methods ============

  void goToRoleSelection() {
    currentScreen = AppScreen.roleSelection;
    _selectedPlace = null;
    _selectedMinistry = null;
    _selectedService = null;
    _loginFlow = null;
  }

  void goToSuperAdminLogin() {
    currentScreen = AppScreen.loginSuperAdmin;
  }

  void goToPlacesList() {
    currentScreen = AppScreen.places;
  }

  void goToPlaceSelected(Place place) {
    _selectedPlace = place;
    currentScreen = AppScreen.placeSelected;
    // Trigger ministry loading for the selected place
    if (onPlaceSelected != null) {
      onPlaceSelected!(place.slug);
    }
  }

  void goToMinistriesForLogin(LoginFlow flow) {
    _loginFlow = flow;
    currentScreen = AppScreen.ministries;
  }

  void goToMinistryLogin(Ministry ministry) {
    _selectedMinistry = ministry;
    currentScreen = AppScreen.loginMinistry;
  }

  void goToServicesForStaff(Ministry ministry) {
    _selectedMinistry = ministry;
    currentScreen = AppScreen.services;
    // Trigger service loading for the selected ministry
    if (_selectedPlace != null && onMinistrySelectedForStaff != null) {
      onMinistrySelectedForStaff!(_selectedPlace!.slug, ministry.slug);
    }
  }

  void goToStaffLogin(StaffServiceModel service) {
    _selectedService = service;
    currentScreen = AppScreen.loginStaff;
  }

  void goBackFromPlaceSelected() {
    currentScreen = AppScreen.places;
    _selectedPlace = null;
    _loginFlow = null;
  }

  void goBackFromMinistries() {
    currentScreen = AppScreen.placeSelected;
    _selectedMinistry = null;
  }

  void goBackFromServices() {
    currentScreen = AppScreen.ministries;
    _selectedService = null;
  }

  void goBackFromMinistryLogin() {
    currentScreen = AppScreen.ministries;
    _selectedMinistry = null;
  }

  void goBackFromStaffLogin() {
    currentScreen = AppScreen.services;
    _selectedService = null;
  }

  @override
  Widget build(BuildContext context) {
    final authState = authBloc.state;

    return Navigator(
      key: navigatorKey,
      pages: _buildPages(authState),
      onDidRemovePage: (page) {
        if (currentScreen == AppScreen.loginSuperAdmin) {
          goToRoleSelection();
        } else if (currentScreen == AppScreen.loginStaff) {
          goBackFromStaffLogin();
        } else if (currentScreen == AppScreen.loginMinistry) {
          goBackFromMinistryLogin();
        } else if (currentScreen == AppScreen.services) {
          goBackFromServices();
        } else if (currentScreen == AppScreen.ministries) {
          goBackFromMinistries();
        } else if (currentScreen == AppScreen.placeSelected) {
          goBackFromPlaceSelected();
        } else if (currentScreen == AppScreen.places) {
          goToRoleSelection();
        }
      },
    );
  }

  List<Page> _buildPages(AuthState authState) {
    final pages = <Page>[];

    // Always have role selection as base
    pages.add(
      FadePage(
        key: const ValueKey('role_selection'),
        child: RoleSelectionPage(
          onSuperAdminSelected: goToSuperAdminLogin,
          onSelectPlaceSelected: goToPlacesList,
        ),
      ),
    );

    // ============ Place Selection Flow ============

    // Add places list page (uses PlaceBloc internally)
    if (_isScreenInFlow(AppScreen.places)) {
      pages.add(
        FadePage(
          key: const ValueKey('places_list'),
          child: PlaceListPage(
            onPlaceSelected: goToPlaceSelected,
            onBack: goToRoleSelection,
          ),
        ),
      );
    }

    // Add place selected page (Ministry Login / Staff Login choice)
    if (_isScreenInFlow(AppScreen.placeSelected) && _selectedPlace != null) {
      pages.add(
        FadePage(
          key: ValueKey('place_selected_${_selectedPlace!.slug}'),
          child: PlaceSelectionPage(
            place: _selectedPlace!,
            onMinistryLoginSelected: () =>
                goToMinistriesForLogin(LoginFlow.ministryAdmin),
            onStaffLoginSelected: () => goToMinistriesForLogin(LoginFlow.staff),
            onBack: goBackFromPlaceSelected,
          ),
        ),
      );
    }

    // Add ministry list page with BlocBuilder
    if (_isScreenInFlow(AppScreen.ministries) && _selectedPlace != null) {
      // Infer login flow if not set (handles URL restoration edge cases)
      if (_loginFlow == null && _selectedMinistry != null) {
        // If we have a ministry selected, we must have come from somewhere
        // Check the next screen in the flow to infer
        if (currentScreen == AppScreen.ministries) {
          // Default to staff flow if ambiguous
          _loginFlow = LoginFlow.staff;
        }
      }

      pages.add(
        FadePage(
          key: ValueKey('ministry_list_${_selectedPlace!.slug}'),
          child: BlocBuilder<MinistryListBloc, MinistryListState>(
            builder: (context, state) {
              final isLoading = state is MinistryListLoading;
              final errorMessage = state is MinistryListError
                  ? state.message
                  : null;
              final ministries = state is MinistriesLoaded
                  ? state.ministries
                  : <Ministry>[];

              // Use the SAME MinistryListPage for both flows
              return MinistryListPage(
                ministries: ministries,
                isLoading: isLoading,
                errorMessage: errorMessage,
                onRetry: () {
                  context.read<MinistryListBloc>().add(
                    RetryLoadMinistriesEvent(placeSlug: _selectedPlace!.slug),
                  );
                },
                onMinistrySelected: (slug, name, logoUrl) {
                  final ministry = Ministry(
                    id: '',
                    name: name,
                    slug: slug,
                    logoUrl: logoUrl,
                  );
                  if (_loginFlow == LoginFlow.staff) {
                    goToServicesForStaff(ministry);
                  } else {
                    goToMinistryLogin(ministry);
                  }
                },
                onBack: goBackFromMinistries,
              );
            },
          ),
        ),
      );
    }

    // Add services list page (only for staff login flow) - Using BLoC
    if (_isScreenInFlow(AppScreen.services) &&
        _selectedPlace != null &&
        _selectedMinistry != null) {
      pages.add(
        FadePage(
          key: ValueKey(
            'services_${_selectedPlace!.slug}_${_selectedMinistry!.slug}',
          ),
          child: BlocBuilder<StaffServicesBloc, StaffServicesState>(
            builder: (context, state) {
              final isLoading = state is StaffServicesLoading;
              final errorMessage = state is StaffServicesError
                  ? state.message
                  : null;
              final services = state is ServicesLoaded
                  ? state.services
                  : <StaffServiceModel>[];

              return PublicServicesPage(
                services: services,
                isLoading: isLoading,
                errorMessage: errorMessage,
                onRetry: () {
                  context.read<StaffServicesBloc>().add(
                    RetryLoadServicesEvent(
                      placeSlug: _selectedPlace!.slug,
                      ministrySlug: _selectedMinistry!.slug,
                    ),
                  );
                },
                onServiceSelected: goToStaffLogin,
                onBack: goBackFromServices,
              );
            },
          ),
        ),
      );
    }

    // ============ Login Pages ============

    // Super Admin Login
    if (currentScreen == AppScreen.loginSuperAdmin) {
      pages.add(
        FadePage(
          key: const ValueKey('login_super_admin'),
          child: LoginPage(
            loginType: LoginType.superAdmin,
            onBackToSelection: goToRoleSelection,
          ),
        ),
      );
    }

    // Ministry Admin Login
    if (currentScreen == AppScreen.loginMinistry &&
        _selectedPlace != null &&
        _selectedMinistry != null) {
      pages.add(
        FadePage(
          key: ValueKey('login_ministry_${_selectedMinistry!.slug}'),
          child: BlocBuilder<MinistryListBloc, MinistryListState>(
            builder: (context, state) {
              // Get actual ministry data from loaded ministries if available
              Ministry? actualMinistry = _selectedMinistry;
              if (state is MinistriesLoaded) {
                // Find the matching ministry by slug
                try {
                  actualMinistry = state.ministries.firstWhere(
                    (m) => m.slug == _selectedMinistry!.slug,
                    orElse: () => _selectedMinistry!,
                  );
                } catch (e) {
                  actualMinistry = _selectedMinistry;
                }
              }

              return LoginPage(
                loginType: LoginType.ministry,
                placeSlug: _selectedPlace!.slug,
                placeName: _selectedPlace!.name,
                ministrySlug: _selectedMinistry!.slug,
                ministryName: actualMinistry!.name,
                ministryLogoUrl: actualMinistry.logoUrl,
                onBackToSelection: goBackFromMinistryLogin,
              );
            },
          ),
        ),
      );
    }

    // Staff Login
    if (currentScreen == AppScreen.loginStaff &&
        _selectedPlace != null &&
        _selectedMinistry != null &&
        _selectedService != null) {
      pages.add(
        FadePage(
          key: ValueKey(
            'login_staff_${_selectedService!.serviceName.toLowerCase().replaceAll(' ', '-')}',
          ),
          child: BlocBuilder<StaffServicesBloc, StaffServicesState>(
            builder: (context, state) {
              // Get actual service data from loaded services if available
              StaffServiceModel? actualService = _selectedService;
              if (state is ServicesLoaded) {
                // Find the matching service by slug or name
                final serviceSlug = _selectedService!.serviceName
                    .toLowerCase()
                    .replaceAll(' ', '-');
                try {
                  actualService = state.services.firstWhere(
                    (s) =>
                        s.serviceName.toLowerCase().replaceAll(' ', '-') ==
                        serviceSlug,
                    orElse: () => _selectedService!,
                  );
                } catch (e) {
                  actualService = _selectedService;
                }
              }

              return LoginPage(
                loginType: LoginType.staff,
                placeSlug: _selectedPlace!.slug,
                placeName: _selectedPlace!.name,
                ministrySlug: _selectedMinistry!.slug,
                ministryName: _selectedMinistry!.name,
                serviceSlug: _selectedService!.serviceName
                    .toLowerCase()
                    .replaceAll(' ', '-'),
                serviceName: actualService!.serviceName,
                staffName: actualService.staffName,
                staffImageUrl: actualService.staffImage,
                onBackToSelection: goBackFromStaffLogin,
              );
            },
          ),
        ),
      );
    }

    // ============ Dashboard ============

    if (currentScreen == AppScreen.dashboard && authState is Authenticated) {
      final user = authState.user;

      if (user.isSuperAdmin) {
        pages.add(
          const FadePage(
            key: ValueKey('dashboard_super_admin'),
            child: DashboardShell(),
          ),
        );
      } else if (user.isAdmin && user.ministry != null) {
        pages.add(
          const FadePage(
            key: ValueKey('dashboard_ministry_admin'),
            child: MinistryShell(),
          ),
        );
      } else if (user.isStaff && user.service != null) {
        pages.add(
          const FadePage(key: ValueKey('dashboard_staff'), child: StaffShell()),
        );
      } else {
        pages.add(
          const FadePage(key: ValueKey('dashboard'), child: DashboardShell()),
        );
      }
    }

    return pages;
  }

  bool _isScreenInFlow(AppScreen screen) {
    final flowOrder = [
      AppScreen.roleSelection,
      AppScreen.places,
      AppScreen.placeSelected,
      AppScreen.ministries,
      AppScreen.services,
      AppScreen.loginStaff,
    ];

    final currentIndex = flowOrder.indexOf(currentScreen);
    final screenIndex = flowOrder.indexOf(screen);

    if (currentIndex != -1 && screenIndex != -1) {
      return screenIndex <= currentIndex;
    }

    if (currentScreen == AppScreen.loginMinistry) {
      return screen == AppScreen.places ||
          screen == AppScreen.placeSelected ||
          screen == AppScreen.ministries;
    }

    return false;
  }
}
