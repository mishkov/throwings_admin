import 'dart:async';
import 'dart:io' as io;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:throwings_admin/src/add_throwing/add_throwing_bloc.dart';
import 'package:throwings_admin/src/home/home_bloc.dart';
import 'package:throwings_core/throwings_core.dart';
import 'package:video_player/video_player.dart';

class AddThrowingView extends StatefulWidget {
  static const routeName = '/add_throwing';

  const AddThrowingView({super.key});

  @override
  State<AddThrowingView> createState() => _AddThrowingViewState();
}

class _AddThrowingViewState extends State<AddThrowingView> {
  VideoPlayerController? _controller;

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
                  TextField(
                    onChanged:
                        context.read<AddThrowingBloc>().setHowToThrowText,
                    decoration: const InputDecoration(
                      labelText: 'Как бросать гранату',
                      hintText: 'Например, удерживать D или с прыжком',
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Click on map to set grenade position'),
                  if (state.selectedMap != null)
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxHeight: 600,
                      ),
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
                  ElevatedButton(
                    onPressed: () async {
                      FilePickerResult? result =
                          await FilePicker.platform.pickFiles(
                        type: FileType.video,
                      );

                      if (result != null) {
                        final videoFile = io.File(result.files.single.path!);

                        _controller = VideoPlayerController.file(videoFile);
                        _controller!.initialize().then((_) {
                          // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
                          setState(() {});
                        });

                        if (mounted && context.mounted) {
                          context
                              .read<AddThrowingBloc>()
                              .setVideo(result.files.single);
                        }
                      }
                    },
                    child: const Text(
                      'Загрузите Видео',
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_controller != null && state.video.size > 0)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 400),
                      child: Column(
                        children: [
                          Expanded(
                            child: AspectRatio(
                              aspectRatio: _controller!.value.aspectRatio,
                              child: VideoPlayer(_controller!),
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  _controller?.play();
                                },
                                icon: const Icon(
                                  Icons.play_arrow,
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  _controller?.pause();
                                },
                                icon: const Icon(
                                  Icons.pause,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
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
                          subtitle: Text(step.imageFile.name ?? 'No name'),
                          leading: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: 100,
                              maxHeight: 100,
                            ),
                            child: step.imageFile.path?.isNotEmpty ?? false
                                ? Image.file(
                                    io.File(step.imageFile.path!),
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
                    onPressed: () async {
                      final needToFetchUpdatedThrowings =
                          await context.read<AddThrowingBloc>().submitAdding();

                      if (!needToFetchUpdatedThrowings) {
                        return;
                      }

                      if (!mounted || !context.mounted) {
                        return;
                      }

                      await context.read<HomeBloc>().fetchData();

                      if (!mounted || !context.mounted) {
                        return;
                      }
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
              if (state.pendingThrowingStepImage.size > 0)
                SizedBox(
                  height: 300,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Image.file(
                      io.File(state.pendingThrowingStepImage.path!),
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
