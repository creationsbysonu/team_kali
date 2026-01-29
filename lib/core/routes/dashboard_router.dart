import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sewa_sathi/core/di/injection_container.dart' as di;
import 'package:sewa_sathi/core/routes/route_names.dart';
import 'package:sewa_sathi/features/auth/presentation/pages/email_page.dart';
import 'package:sewa_sathi/features/auth/presentation/pages/otp_page.dart';
import 'package:sewa_sathi/features/home/presentation/pages/home_screen.dart';
import 'package:sewa_sathi/features/profile/presentation/pages/name_input_page.dart';
import 'package:sewa_sathi/features/profile/presentation/pages/place_selection_page.dart';
import 'package:sewa_sathi/features/notice/presentation/pages/notice_list_screen.dart';
import 'package:sewa_sathi/features/notice/presentation/pages/notice_detail_screen.dart';
import 'package:sewa_sathi/features/community/presentation/bloc/feed_bloc.dart';
import 'package:sewa_sathi/features/community/presentation/pages/issues_screen.dart';
import 'package:sewa_sathi/features/community/presentation/pages/ideas_screen.dart';
import 'package:sewa_sathi/features/community/presentation/pages/create_post_screen.dart';
import 'package:sewa_sathi/features/get_token/domain/entities/ministry_entity.dart';
import 'package:sewa_sathi/features/get_token/domain/entities/staff_service_entity.dart';
import 'package:sewa_sathi/features/get_token/presentation/pages/ministry_list_screen.dart';
import 'package:sewa_sathi/features/get_token/presentation/pages/service_list_screen.dart';
import 'package:sewa_sathi/features/get_token/presentation/pages/service_detail_screen.dart';
import 'package:sewa_sathi/features/get_token/presentation/pages/my_tokens_screen.dart';

/// Router for generating routes in the dashboard app.
class DashboardRouter {
  /// Generate routes based on route settings.
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.email:
        return _buildRoute(const EmailPage(), settings);

      case RouteNames.otp:
        final email = settings.arguments as String;
        return _buildRoute(OtpPage(email: email), settings);

      case RouteNames.nameInput:
        return _buildRoute(const NameInputPage(), settings);

      case RouteNames.placeSelection:
        final fullName = settings.arguments as String;
        return _buildRoute(PlaceSelectionPage(fullName: fullName), settings);

      case RouteNames.home:
        return _buildRoute(const HomeScreen(), settings);

      case RouteNames.noticeList:
        return _buildRoute(const NoticeListScreen(), settings);

      case RouteNames.noticeDetail:
        final noticeId = settings.arguments as String;
        return _buildRoute(NoticeDetailScreen(noticeId: noticeId), settings);

      case RouteNames.issues:
        return _buildRoute(
          BlocProvider(
            create: (_) => di.sl<FeedBloc>(),
            child: const IssuesScreen(),
          ),
          settings,
        );

      case RouteNames.ideas:
        return _buildRoute(
          BlocProvider(
            create: (_) => di.sl<FeedBloc>(),
            child: const IdeasScreen(),
          ),
          settings,
        );

      case RouteNames.createPost:
        return _buildRoute(const CreatePostScreen(), settings);

      case RouteNames.ministryList:
        final placeId = settings.arguments as int;
        return _buildRoute(MinistryListScreen(placeId: placeId), settings);

      case RouteNames.serviceList:
        final ministry = settings.arguments as MinistryEntity;
        return _buildRoute(ServiceListScreen(ministry: ministry), settings);

      case RouteNames.serviceDetails:
        final service = settings.arguments as StaffServiceEntity;
        return _buildRoute(ServiceDetailScreen(service: service), settings);

      case RouteNames.myTokens:
        return _buildRoute(const MyTokensScreen(), settings);

      default:
        return _buildRoute(
          const Scaffold(body: Center(child: Text('Page not found'))),
          settings,
        );
    }
  }

  /// Build a MaterialPageRoute with the given page and settings.
  static MaterialPageRoute _buildRoute(Widget page, RouteSettings settings) {
    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }
}
