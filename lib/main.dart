import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:sewa_web/app/app.dart';
import 'package:sewa_web/app/app_bloc_observer.dart';
import 'package:sewa_web/core/di/injection_container.dart' as di;
import 'package:sewa_web/features/auth/presentation/bloc/auth_bloc.dart';

// Global error handler for uncaught exceptions
void _logError(Object error, StackTrace stack) {
  debugPrint('Unhandled exception: $error');
  debugPrint(stack.toString());
}

Future<void> main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Use path URL strategy (removes the # from URLs)
    usePathUrlStrategy();

    Bloc.observer = AppBlocObserver();
    await di.init();
    final authBloc = di.sl<AuthBloc>()..add(CheckAuthStatusEvent());
    runApp(MyApp(authBloc: authBloc));
  }, _logError);
}
