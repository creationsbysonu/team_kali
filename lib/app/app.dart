import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_web/core/di/injection_container.dart' as di;
import 'package:sewa_web/core/routes/routes.dart';
import 'package:sewa_web/core/theme/theme.dart';
import 'package:sewa_web/core/widget/global_operation_overlay.dart';
import 'package:sewa_web/core/widget/loading_overlay.dart';
import 'package:sewa_web/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sewa_web/features/auth/presentation/bloc/ministry_list_bloc.dart';
import 'package:sewa_web/features/attendance/presentation/bloc/attendance_calendar_bloc.dart';
import 'package:sewa_web/features/places/places.dart';
import 'package:sewa_web/features/staff/presentation/bloc/staff_services_bloc.dart';

class MyApp extends StatefulWidget {
  final AuthBloc authBloc;
  const MyApp({super.key, required this.authBloc});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Create router delegate ONCE and reuse it
  late final AppRouterDelegate _routerDelegate;
  late final AppRouteInformationParser _routeInformationParser;
  late final PlaceBloc _placeBloc;
  late final MinistryListBloc _ministryListBloc;
  late final StaffServicesBloc _staffServicesBloc;
  late final AttendanceCalendarBloc _attendanceCalendarBloc;

  @override
  void initState() {
    super.initState();

    // Initialize PlaceBloc
    _placeBloc = di.sl<PlaceBloc>()..add(const LoadPublicPlacesEvent());

    // Initialize MinistryListBloc
    _ministryListBloc = di.sl<MinistryListBloc>();

    // Initialize StaffServicesBloc
    _staffServicesBloc = di.sl<StaffServicesBloc>();

    // Initialize AttendanceCalendarBloc
    _attendanceCalendarBloc = di.sl<AttendanceCalendarBloc>();

    // Initialize router components once
    _routeInformationParser = AppRouteInformationParser();
    _routerDelegate = AppRouterDelegate(
      authBloc: widget.authBloc,
      onPlaceSelected: _onPlaceSelected,
      onMinistrySelectedForStaff: _onMinistrySelectedForStaff,
    );
  }

  @override
  void dispose() {
    _routerDelegate.dispose();
    _placeBloc.close();
    _ministryListBloc.close();
    _staffServicesBloc.close();
    _attendanceCalendarBloc.close();
    super.dispose();
  }

  /// Called when a place is selected - fetch ministries for that place
  void _onPlaceSelected(String placeSlug) {
    debugPrint('MyApp: Place selected, loading ministries for: $placeSlug');
    _ministryListBloc.add(LoadMinistriesByPlaceEvent(placeSlug: placeSlug));
  }

  /// Called when a ministry is selected for staff login - fetch services
  void _onMinistrySelectedForStaff(String placeSlug, String ministrySlug) {
    debugPrint(
      'MyApp: Ministry selected for staff, loading services for: $placeSlug/$ministrySlug',
    );
    _staffServicesBloc.add(
      LoadServicesEvent(placeSlug: placeSlug, ministrySlug: ministrySlug),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: widget.authBloc),
        BlocProvider.value(value: _placeBloc),
        BlocProvider.value(value: _ministryListBloc),
        BlocProvider.value(value: _staffServicesBloc),
        BlocProvider.value(value: _attendanceCalendarBloc),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          // Ensure loading overlay is hidden when auth state changes to unauthenticated
          // This handles logout overlay that might be stuck during navigation
          if (state is UnAuthenticated) {
            LoadingOverlay.hide();
          }
        },
        child: GlobalOperationOverlay.wrap(
          MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'Sewa Sathi - Government Web Admin',
            theme: AppTheme.buildThemeData(),
            routerDelegate: _routerDelegate,
            routeInformationParser: _routeInformationParser,
            backButtonDispatcher: RootBackButtonDispatcher(),
          ),
        ),
      ),
    );
  }
}
