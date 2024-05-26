import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:throwings_core/throwings_core.dart';
import 'package:uuid/uuid.dart';

class AddMapBloc extends Cubit<AddMapState> {
  AddMapBloc() : super(AddMapState());

  void reset() {
    emit(AddMapState());
  }

  void setName(String name) {
    emit(state.copyWith(name: name));
  }

  void setImage(PlatformFile image) {
    emit(state.copyWith(image: image));
  }

  void markMessageAsHandled() {
    emit(state.copyWith(message: ''));
  }

  Future<void> submitAdding() async {
    try {
      if (state.name.isEmpty) {
        emit(state.copyWith(message: 'Необходимо ввести название карты'));

        return;
      }

      if (state.image.size == 0) {
        emit(state.copyWith(message: 'Необходимо выбрать изображение карты'));

        return;
      }

      assert(state.image.bytes != null, 'Picked image has no bytes');

      final decodedImage = await decodeImageFromList(state.image.bytes!);

      if (decodedImage.width != decodedImage.height) {
        emit(
          state.copyWith(
            message: 'Соотношение сторон изображения должно быть 1:1',
          ),
        );

        return;
      }

      final storage = FirebaseStorage.instance;
      final root = storage.ref();
      final maps = root.child('maps');
      final mapRef = maps.child('${const Uuid().v4()}-${state.image.name}');

      await mapRef.putData(state.image.bytes!);

      final downlaodUrl = await mapRef.getDownloadURL();

      final db = FirebaseFirestore.instance;

      final map = <String, dynamic>{
        "name": state.name,
        'url': downlaodUrl,
      };

      final doc = await db.collection("maps").add(map);

      emit(state.copyWith(message: 'Карта добавлена, id: ${doc.id}'));
    } catch (error) {
      emit(state.copyWith(message: 'Произошла ошибка: $error'));
      throwInDebug(error);
    }
  }
}

class AddMapState extends Equatable {
  final String name;
  final PlatformFile image;
  final String message;

  AddMapState({
    this.name = '',
    PlatformFile? image,
    this.message = '',
  }) : image = image ?? PlatformFile(name: 'none.png', size: 0);

  @override
  List<Object> get props => [name, image, message];

  AddMapState copyWith({
    String? name,
    PlatformFile? image,
    String? message,
  }) {
    return AddMapState(
      name: name ?? this.name,
      image: image ?? this.image,
      message: message ?? this.message,
    );
  }
}
