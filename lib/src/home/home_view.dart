import 'package:flutter/material.dart';
import 'package:throwings_admin/src/add_map/add_map_view.dart';
import 'package:throwings_admin/src/add_throwing/add_throwing_view.dart';

import '../settings/settings_view.dart';

class HomeView extends StatelessWidget {
  const HomeView({
    super.key,
  });

  static const routeName = '/';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Главная страница'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.restorablePushNamed(context, SettingsView.routeName);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.restorablePushNamed(
                      context,
                      AddThrowingView.routeName,
                    );
                  },
                  child: const Text(
                    'Добавить раскидку',
                  ),
                ),
                const SizedBox(width: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.restorablePushNamed(
                      context,
                      AddMapView.routeName,
                    );
                  },
                  child: const Text(
                    'Добавить Карту',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
