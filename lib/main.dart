import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:throwings_admin/firebase_options.dart';
import 'package:throwings_admin/src/add_map/add_map_bloc.dart';
import 'package:throwings_admin/src/add_throwing/add_throwing_bloc.dart';

import 'src/app.dart';
import 'src/settings/settings_controller.dart';
import 'src/settings/settings_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set up the SettingsController, which will glue user settings to multiple
  // Flutter Widgets.
  final settingsController = SettingsController(SettingsService());

  // Load the user's preferred theme while the splash screen is displayed.
  // This prevents a sudden theme change when the app is first displayed.
  await settingsController.loadSettings();

  // Run the app and pass in the SettingsController. The app listens to the
  // SettingsController for changes, then passes it further down to the
  // SettingsView.
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<AddThrowingBloc>(
          create: (BuildContext context) => AddThrowingBloc(),
        ),
        BlocProvider<AddMapBloc>(
          create: (BuildContext context) => AddMapBloc(),
        ),
      ],
      child: MyApp(settingsController: settingsController),
    ),
  );
}
