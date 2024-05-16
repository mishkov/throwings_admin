import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:throwings_admin/src/add_map/add_map_bloc.dart';

class AddMapView extends StatefulWidget {
  static const routeName = '/add_map';

  const AddMapView({super.key});

  @override
  State<AddMapView> createState() => _AddMapViewState();
}

class _AddMapViewState extends State<AddMapView> {
  @override
  void initState() {
    super.initState();

    final bloc = context.read<AddMapBloc>();
    bloc.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Добавление новой карты',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 8.0,
          horizontal: 24,
        ),
        child: SingleChildScrollView(
          child: BlocConsumer<AddMapBloc, AddMapState>(
            listener: (context, state) {
              if (state.message.isNotEmpty) {
                final messenger = ScaffoldMessenger.of(context);
                messenger.clearSnackBars();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                  ),
                );

                context.read<AddMapBloc>().markMessageAsHandled();
              }
            },
            builder: (context, state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  TextField(
                    onChanged: context.read<AddMapBloc>().setName,
                    decoration: const InputDecoration(
                      labelText: 'Название',
                      hintText: 'Например, Dust 2 или Inferno',
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () async {
                      FilePickerResult? result =
                          await FilePicker.platform.pickFiles(
                        type: FileType.image,
                      );

                      if (result != null) {
                        if (mounted && context.mounted) {
                          context
                              .read<AddMapBloc>()
                              .setImage(result.files.single);
                        }
                      } else {
                        // User canceled the picker
                      }
                    },
                    child: const Text(
                      'Выбрать изображение карты (радар), соотношение 1:1',
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (state.image.bytes != null)
                    SizedBox(
                      height: 600,
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Image.memory(
                          state.image.bytes!,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<AddMapBloc>().submitAdding();
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
}
