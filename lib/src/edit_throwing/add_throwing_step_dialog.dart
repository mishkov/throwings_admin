import 'dart:io' as io;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:throwings_admin/src/edit_throwing/edit_throwing_bloc.dart';
import 'package:throwings_core/throwings_core.dart';

class AddThrowingStepDialog extends StatelessWidget {
  const AddThrowingStepDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EditThrowingBloc, EditThrowingState>(
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
                  .read<EditThrowingBloc>()
                  .setPendingThrowingStepType(value);
            },
            value: state.pendingThrowingStepType,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () async {
              FilePickerResult? result = await FilePicker.platform.pickFiles(
                type: FileType.image,
              );

              if (result != null) {
                if (context.mounted) {
                  context
                      .read<EditThrowingBloc>()
                      .setPendingThrowingStepImage(file: result.files.single);
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
                  final isAdded =
                      context.read<EditThrowingBloc>().addPendingThrowingStep();

                  if (isAdded && context.mounted) {
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
  }
}
