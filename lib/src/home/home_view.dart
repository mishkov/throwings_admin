import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:throwings_admin/src/add_map/add_map_view.dart';
import 'package:throwings_admin/src/add_throwing/add_throwing_view.dart';
import 'package:throwings_admin/src/edit_throwing/edit_throwing_view.dart';
import 'package:throwings_admin/src/home/home_bloc.dart';
import 'package:throwings_admin/src/home/select_throwing_on_map_dialog.dart';
import 'package:throwings_core/throwings_core.dart';

import '../settings/settings_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({
    super.key,
  });

  static const routeName = '/';

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _selectedDestinationIndex = 0;

  @override
  void initState() {
    super.initState();

    context.read<HomeBloc>().fetchData();
  }

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
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedDestinationIndex,
            labelType: NavigationRailLabelType.all,
            onDestinationSelected: (index) {
              setState(() {
                _selectedDestinationIndex = index;
              });
            },
            destinations: <NavigationRailDestination>[
              NavigationRailDestination(
                icon: Icon(MdiIcons.bomb),
                label: const Text('Throwings'),
              ),
              const NavigationRailDestination(
                icon: Icon(Icons.map_rounded),
                label: Text('Maps'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: [
              BlocBuilder<HomeBloc, HomeState>(
                builder: (context, state) {
                  if (state.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator.adaptive(),
                    );
                  }

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context)
                                  .pushNamed(AddThrowingView.routeName);
                            },
                            child: const Text(
                              'Добавить раскидку',
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.all(12.0),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 300,
                          ),
                          itemCount: state.maps.length,
                          itemBuilder: (BuildContext context, int index) {
                            final map = state.maps[index];

                            return InkWell(
                              onTap: () async {
                                final throwing = await showDialog(
                                  context: context,
                                  builder: (context) {
                                    return SelectTrowingOnMapDialog(
                                      map: map,
                                      throwings:
                                          state.throwings.where((element) {
                                        return element.map.id == map.id;
                                      }).toList(),
                                    );
                                  },
                                );

                                if (throwing is! Throwing) {
                                  return;
                                }

                                if (mounted && context.mounted) {
                                  Navigator.of(context).pushNamed(
                                    EditThrowingView.routeName,
                                    arguments: throwing,
                                  );
                                }
                              },
                              child: GridTile(
                                header: Container(
                                  alignment: Alignment.topLeft,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                      borderRadius: const BorderRadius.only(
                                        bottomRight: Radius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      map.name,
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Image.network(map.pathToImage),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
              Column(
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
            ][_selectedDestinationIndex],
          ),
        ],
      ),
    );
  }
}
