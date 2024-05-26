import 'dart:async';
import 'dart:io' as io;
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:throwings_admin/src/edit_throwing/add_throwing_step_dialog.dart';
import 'package:throwings_admin/src/edit_throwing/edit_throwing_bloc.dart';
import 'package:throwings_admin/src/home/home_bloc.dart';
import 'package:throwings_core/throwings_core.dart';
import 'package:video_player/video_player.dart';

class EditThrowingView extends StatefulWidget {
  static const routeName = '/edit_throwing';

  const EditThrowingView({
    super.key,
    required this.throwing,
  });

  final Throwing throwing;

  @override
  State<EditThrowingView> createState() => _EditThrowingViewState();
}

class _EditThrowingViewState extends State<EditThrowingView> {
  VideoPlayerController? _controller;
  final _descriptionTextController = TextEditingController();
  final _howToThrowTextController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _asyncInit();
  }

  Future<void> _asyncInit() async {
    final bloc = context.read<EditThrowingBloc>();
    await bloc.init(editingThrowing: widget.throwing);

    _descriptionTextController.text = bloc.state.description;
    _howToThrowTextController.text = bloc.state.howToThrowText;

    if (bloc.state.pathToNetworkVideo.isNotEmpty) {
      await _controller?.dispose();
      _controller = VideoPlayerController.networkUrl(
          Uri.parse(bloc.state.pathToNetworkVideo));
      _controller!.initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
        setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit throwing',
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 8.0,
            horizontal: 24,
          ),
          child: BlocConsumer<EditThrowingBloc, EditThrowingState>(
            listener: (context, state) {
              if (state.message.isNotEmpty) {
                final messenger = ScaffoldMessenger.of(context);
                messenger.clearSnackBars();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                  ),
                );

                context.read<EditThrowingBloc>().markMessageAsHandled();
              }
            },
            builder: (context, state) {
              final throwingSteps = state.throwingSteps.withoutStepsToDelete;

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

                      context.read<EditThrowingBloc>().setSelectedMap(value);
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
                          .read<EditThrowingBloc>()
                          .setSelectedGrenades(value);
                    },
                    value: state.selectedGrenade,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    onChanged: context.read<EditThrowingBloc>().setDescription,
                    controller: _descriptionTextController,
                    decoration: const InputDecoration(
                      labelText: 'Описание',
                      hintText: 'Например, что полезного в этой раскидке',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    onChanged:
                        context.read<EditThrowingBloc>().setHowToThrowText,
                    controller: _howToThrowTextController,
                    decoration: const InputDecoration(
                      labelText: 'Как бросать гранату',
                      hintText: 'Например, удерживать D или с прыжком',
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Click on map to set grenade position'),
                  if (state.selectedMap != null)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 600),
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
                                      .read<EditThrowingBloc>()
                                      .setSelectedPosition(
                                        Point(
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
                                      left: state.selectedPosition.x * width -
                                          pointSize / 2,
                                      top: state.selectedPosition.y * height -
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

                        await _controller?.dispose();
                        _controller = VideoPlayerController.file(videoFile);
                        _controller!.initialize().then((_) {
                          // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
                          setState(() {});
                        });

                        if (mounted && context.mounted) {
                          context
                              .read<EditThrowingBloc>()
                              .setVideo(result.files.single);
                        }
                      } else {
                        // User canceled the picker
                      }
                    },
                    child: const Text(
                      'Загрузите Видео',
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_controller != null && _controller!.value.isInitialized)
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
                  ReorderableListView.builder(
                    itemCount: throwingSteps.length,
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    onReorder:
                        context.read<EditThrowingBloc>().reorderThrowingStep,
                    itemBuilder: (context, index) {
                      final step = throwingSteps[index];

                      return Card(
                        key: ValueKey(step),
                        child: ListTile(
                          title: Text(step.type.readableName),
                          subtitle: Text(
                            step.imageFile.name ??
                                step.imageFile.path ??
                                step.pathToNetworkImage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          leading: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: 100,
                              maxHeight: 100,
                            ),
                            child: step.imageFile.path?.isNotEmpty ?? false
                                ? Image.file(
                                    io.File(step.imageFile.path!),
                                  )
                                : step.pathToNetworkImage.isNotEmpty
                                    ? Image.network(step.pathToNetworkImage)
                                    : const Icon(
                                        Icons.hide_image_rounded,
                                      ),
                          ),
                          trailing: IconButton(
                            onPressed: () {
                              context
                                  .read<EditThrowingBloc>()
                                  .removeThrowingStep(step);
                            },
                            icon: const Icon(Icons.delete_rounded),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // show "make sure" dialog and pop screen.
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title:
                                      const Text('Изменния могут быть утерены'),
                                  content: const SingleChildScrollView(
                                    child: ListBody(
                                      children: <Widget>[
                                        Text(
                                            'Вы уверены, что хотите выйти без сохранения изменений'),
                                      ],
                                    ),
                                  ),
                                  actions: <Widget>[
                                    TextButton(
                                      child: const Text('Отмена'),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                    TextButton(
                                      child: const Text('Да'),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: const Text(
                            'Отменить изменения',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final needToFetchUpdatedThrowings = await context
                                .read<EditThrowingBloc>()
                                .submitEditing();

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

                            Navigator.of(context).pop();
                          },
                          child: const Text(
                            'Сохранить изменения',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('Удаление нельзя отменить'),
                            content: const SingleChildScrollView(
                              child: ListBody(
                                children: <Widget>[
                                  Text(
                                      'Вы уверены, что хотите удалить данную раскидку?'),
                                ],
                              ),
                            ),
                            actions: <Widget>[
                              TextButton(
                                child: const Text('Отмена'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                              TextButton(
                                child: const Text('Да'),
                                onPressed: () async {
                                  final needToFetchUpdatedThrowings =
                                      await context
                                          .read<EditThrowingBloc>()
                                          .deleteThrowing();

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

                                  Navigator.of(context).pop();
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: const Text(
                      'Удалить',
                      textAlign: TextAlign.center,
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
    context.read<EditThrowingBloc>().setPendingThrowingStepType(
          ThrowingStepType.none,
        );
    context.read<EditThrowingBloc>().setPendingThrowingStepImage(
          file: PlatformFile(
            name: 'none.png',
            size: 0,
          ),
        );

    await showDialog(
      context: context,
      builder: (context) => const AddThrowingStepDialog(),
    );
  }
}
