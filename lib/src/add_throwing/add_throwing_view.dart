import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:throwings_admin/src/add_throwing/add_throwing_bloc.dart';
import 'package:throwings_admin/src/add_throwing/cs2_map.dart';
import 'package:throwings_admin/src/add_throwing/grenade.dart';

class AddThrowingView extends StatefulWidget {
  static const routeName = '/add_throwing';

  const AddThrowingView({super.key});

  @override
  State<AddThrowingView> createState() => _AddThrowingViewState();
}

class _AddThrowingViewState extends State<AddThrowingView> {
  @override
  void initState() {
    super.initState();

    final bloc = context.read<AddThrowingBloc>();
    bloc.reset();
    unawaited(bloc.fetchMaps());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add new throwing',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 8.0,
          horizontal: 24,
        ),
        child: SingleChildScrollView(
          child: BlocConsumer<AddThrowingBloc, AddThrowingState>(
            listener: (context, state) {
              if (state.message.isNotEmpty) {
                final messenger = ScaffoldMessenger.of(context);
                messenger.clearSnackBars();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                  ),
                );

                context.read<AddThrowingBloc>().markMessageAsHandled();
              }
            },
            builder: (context, state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButton<CS2Map>(
                    hint: const Text('Карта'),
                    items: state.maps.map((map) {
                      return DropdownMenuItem(
                        value: map,
                        child: Text(map.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      context.read<AddThrowingBloc>().setSelectedMap(value);
                    },
                    value: state.selectedMap,
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<Grenade>(
                    hint: const Text('Тип гранаты'),
                    items: Grenade.values
                        .where((element) => element != Grenade.none)
                        .map((map) {
                      return DropdownMenuItem(
                        value: map,
                        child: Text(map.readableName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      context
                          .read<AddThrowingBloc>()
                          .setSelectedGrenades(value);
                    },
                    value: state.selectedGrenade,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    onChanged: context.read<AddThrowingBloc>().setDescription,
                    decoration: const InputDecoration(
                      labelText: 'Описание',
                      hintText: 'Например, что полезного в этой раскидке',
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Click on map to set grenade position'),
                  if (state.selectedMap != null)
                    SizedBox(
                      height: 600,
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints.expand(),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              assert(constraints.hasTightHeight);
                              assert(constraints.hasTightWidth);

                              const pointSize = 10.0;

                              final width = constraints.maxWidth;
                              final height = constraints.maxHeight;

                              return GestureDetector(
                                onTapDown: (details) {
                                  context
                                      .read<AddThrowingBloc>()
                                      .setSelectedPosition(
                                        Offset(
                                          details.localPosition.dx / width,
                                          details.localPosition.dy / height,
                                        ),
                                      );
                                },
                                child: Stack(
                                  children: [
                                    Image.network(
                                      state.selectedMap!.pathToImage,
                                    ),
                                    Positioned(
                                      left: state.selectedPosition.dx * width -
                                          pointSize / 2,
                                      top: state.selectedPosition.dy * height -
                                          pointSize / 2,
                                      child: Container(
                                        height: pointSize,
                                        width: pointSize,
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    )
                  else
                    const Text('Выберите карту для выбора позиции'),
                  const SizedBox(
                    height: 8,
                  ),
                  Row(
                    children: [
                      const Text('Шаги бросания'),
                      IconButton(
                        onPressed: () => _showAddThrowingStepImage(context),
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  ListView.builder(
                    itemCount: state.throwingSteps.length,
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      final step = state.throwingSteps[index];
                      return Card(
                        child: ListTile(
                          title: Text(step.type.readableName),
                          subtitle: Text(step.file.name),
                          leading: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: 100,
                              maxHeight: 100,
                            ),
                            child: step.file.bytes != null
                                ? Image.memory(
                                    step.file.bytes!,
                                  )
                                : const Icon(
                                    Icons.hide_image_rounded,
                                  ),
                          ),
                          trailing: IconButton(
                            onPressed: () {
                              context
                                  .read<AddThrowingBloc>()
                                  .removeThrowingStep(step);
                            },
                            icon: const Icon(Icons.delete_rounded),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<AddThrowingBloc>().submitAdding();
                    },
                    child: const Text(
                      'Добавить',
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _showAddThrowingStepImage(BuildContext context) async {
    context.read<AddThrowingBloc>().setPendingThrowingStepType(
          ThrowingStepType.none,
        );
    context.read<AddThrowingBloc>().setPendingThrowingStepImage(
          file: PlatformFile(
            name: 'none.png',
            size: 0,
          ),
        );

    await showDialog(
      context: context,
      builder: (context) {
        return BlocBuilder<AddThrowingBloc, AddThrowingState>(
            builder: (context, state) {
          return SimpleDialog(
            title: Text(
              'Добавление шага',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            contentPadding: const EdgeInsets.all(12),
            children: [
              const Text('Выберите тип'),
              DropdownButton<ThrowingStepType>(
                hint: const Text('Тип'),
                items: ThrowingStepType.values.map((map) {
                  return DropdownMenuItem(
                    value: map,
                    child: Text(map.readableName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  context
                      .read<AddThrowingBloc>()
                      .setPendingThrowingStepType(value);
                },
                value: state.pendingThrowingStepType,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  FilePickerResult? result =
                      await FilePicker.platform.pickFiles(
                    type: FileType.image,
                  );

                  if (result != null) {
                    if (mounted && context.mounted) {
                      context
                          .read<AddThrowingBloc>()
                          .setPendingThrowingStepImage(
                              file: result.files.single);
                    }
                  } else {
                    // User canceled the picker
                  }
                },
                child: const Text(
                  'Загрузите изображение',
                ),
              ),
              const SizedBox(height: 8),
              if (state.pendingThrowingStepImage.bytes != null)
                SizedBox(
                  height: 300,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Image.memory(
                      state.pendingThrowingStepImage.bytes!,
                    ),
                  ),
                ),
              const SizedBox(height: 26),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Отмена'),
                  ),
                  TextButton(
                    onPressed: () async {
                      final isAdded = context
                          .read<AddThrowingBloc>()
                          .addPendingThrowingImage();

                      if (isAdded && mounted && context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    child: const Text('Добавить'),
                  ),
                ],
              ),
            ],
          );
        });
      },
    );
  }
}

extension on Grenade {
  String get readableName => switch (this) {
        Grenade.flashbang => 'Флешка',
        Grenade.molotov => 'Молотов',
        Grenade.highExplosive => 'Хаешка',
        Grenade.smoke => 'Дым',
        Grenade.none => 'Не определено',
      };
}

enum ThrowingStepType {
  positioning,
  aiming,
  zoomedAiming,
  additional,
  result,
  none,
}

extension ReadableThrowingStepType on ThrowingStepType {
  String get readableName => switch (this) {
        ThrowingStepType.positioning => 'позиционирование',
        ThrowingStepType.aiming => 'прицеливание',
        ThrowingStepType.zoomedAiming => 'приближенное прицеливание',
        ThrowingStepType.additional => 'дополнительно',
        ThrowingStepType.result => 'результат раскидки',
        ThrowingStepType.none => 'Не определено',
      };
}
