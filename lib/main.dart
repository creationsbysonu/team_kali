import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sewa_sathi/app/app.dart';
import 'package:sewa_sathi/app/app_bloc_observer.dart';
import 'package:sewa_sathi/core/di/injection_container.dart' as di;

Future<void> main() async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Initialize Hive for local storage (community posts)
      await Hive.initFlutter();

      // Set up BLoC observer for debugging
      if (kDebugMode) {
        Bloc.observer = AppBlocObserver();
      }

      // Initialize dependency injection
      await di.init();

      runApp(const App());
    },
    (error, stack) {
      debugPrint('Unhandled exception: $error');
      debugPrint(stack.toString());
    },
  );
}
