import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:throwings_admin/src/add_throwing/add_throwing_view.dart';
import 'package:throwings_admin/src/add_throwing/cs2_map.dart';
import 'package:throwings_admin/src/add_throwing/grenade.dart';
import 'package:throwings_admin/src/add_throwing/throwing_step.dart';
import 'package:throwings_admin/src/core/throw_in_debug.dart';
import 'package:uuid/uuid.dart';

class AddThrowingBloc extends Cubit<AddThrowingState> {
  AddThrowingBloc() : super(AddThrowingState());

  Future<void> fetchMaps() async {
    try {
      final db = FirebaseFirestore.instance;
      final event = await db.collection("maps").get();

      List<CS2Map> result = [];
      for (final doc in event.docs) {
        final data = doc.data();
        result.add(
          CS2Map(
            id: doc.id,
            name: data['name'],
            pathToImage: data['url'],
          ),
        );
      }

      emit(state.copyWith(maps: result));
    } catch (error) {
      emit(state.copyWith(message: 'Ошибка получения карт: $error'));
      throwInDebug(error);
    }
  }

  /// Retuns false if error occured.
  bool addPendingThrowingImage() {
    if (state.pendingThrowingStepType == ThrowingStepType.none) {
      emit(state.copyWith(message: 'Нужно выбрать тип шага'));

      return false;
    }

    if (state.pendingThrowingStepImage.size == 0) {
      emit(state.copyWith(message: 'Нужно выбрать изображение'));

      return false;
    }

    emit(
      state.copyWith(
        throwingSteps: List.of(state.throwingSteps)
          ..add(
            ThrowingStep(
              file: state.pendingThrowingStepImage,
              type: state.pendingThrowingStepType,
            ),
          ),
      ),
    );

    return true;
  }

  void removeThrowingStep(ThrowingStep step) {
    emit(
      state.copyWith(
        throwingSteps: List.of(state.throwingSteps)
          ..remove(
            step,
          ),
      ),
    );
  }

  void reset() {
    emit(AddThrowingState());
  }

  void setPendingThrowingStepImage({
    required PlatformFile file,
  }) {
    emit(state.copyWith(pendingThrowingStepImage: file));
  }

  void setSelectedMap(CS2Map map) {
    emit(state.copyWith(selectedMap: map));
  }

  void setSelectedGrenades(Grenade grenade) {
    emit(state.copyWith(selectedGrenade: grenade));
  }

  void setSelectedPosition(Offset position) {
    emit(state.copyWith(selectedPosition: position));
  }

  void setDescription(String value) {
    emit(state.copyWith(description: value));
  }

  void setPathToVideo(String value) {
    emit(state.copyWith(description: value));
  }

  void setPendingThrowingStepType(ThrowingStepType throwingStepType) {
    emit(state.copyWith(pendingThrowingStepType: throwingStepType));
  }

  Future<void> submitAdding() async {
    try {
      if (state.selectedMap == null) {
        emit(state.copyWith(message: 'Выберите карту'));

        return;
      }

      if (state.selectedGrenade == null) {
        emit(state.copyWith(message: 'Выберите тип гранат'));

        return;
      }

      if (state.selectedPosition == Offset.zero) {
        emit(state.copyWith(message: 'Выберите позицию'));

        return;
      }

      final addedSteps = state.throwingSteps.map((e) => e.type).toSet();
      final requiredSteps = {
        ThrowingStepType.positioning,
        ThrowingStepType.aiming,
        ThrowingStepType.zoomedAiming,
        ThrowingStepType.result,
      };
      final requiredStepsAdded = addedSteps.containsAll(requiredSteps);
      if (!requiredStepsAdded) {
        emit(state.copyWith(
            message:
                'Добавте шаги: ${requiredSteps.difference(addedSteps).map((e) => e.readableName).join(', ')}'));

        return;
      }

      // load steps images
      final storage = FirebaseStorage.instance;
      final root = storage.ref();
      final maps = root.child('steps');

      Map<ThrowingStep, String> stepToImagePath = {};
      for (final step in state.throwingSteps) {
        final mapRef = maps.child('${const Uuid().v4()}-${step.file.name}');
        await mapRef.putData(step.file.bytes!);
        final downlaodUrl = await mapRef.getDownloadURL();

        stepToImagePath[step] = downlaodUrl;
      }

      final db = FirebaseFirestore.instance;

      final throwing = <String, dynamic>{
        "map": state._selectedMap.id,
        "grenade": state._selectedGrenade.name,
        'description': state.description,
        "position": {
          'dx': state.selectedPosition.dx,
          'dy': state.selectedPosition.dy,
        },
        'steps': [
          for (final step in state.throwingSteps)
            {
              'type': step.type.name,
              'pathToImage': stepToImagePath[step],
            },
        ],
      };

      final doc = await db.collection("throwings").add(throwing);

      emit(
        state.copyWith(
          message: 'DocumentSnapshot added with ID: ${doc.id}',
        ),
      );
    } catch (error) {
      emit(state.copyWith(message: 'Ошибка: $error'));
      throwInDebug(error);
    }
  }

  void markMessageAsHandled() async {
    emit(state.copyWith(message: ''));
  }
}

class AddThrowingState extends Equatable {
  final List<CS2Map> maps;
  final CS2Map _selectedMap;
  final Grenade _selectedGrenade;
  final String description;
  final Offset selectedPosition;
  final String message;
  final String pathToVideo;
  final List<ThrowingStep> throwingSteps;
  final ThrowingStepType pendingThrowingStepType;
  final PlatformFile pendingThrowingStepImage;

  AddThrowingState({
    CS2Map selectedMap = const NoneCS2Map(),
    this.maps = const [],
    Grenade selectedGrenade = Grenade.none,
    this.selectedPosition = Offset.zero,
    this.message = '',
    this.description = '',
    this.pathToVideo = '',
    this.throwingSteps = const [],
    PlatformFile? pendingThrowingStepImage,
    this.pendingThrowingStepType = ThrowingStepType.none,
  })  : _selectedGrenade = selectedGrenade,
        _selectedMap = selectedMap,
        pendingThrowingStepImage =
            pendingThrowingStepImage ?? PlatformFile(name: 'none.png', size: 0);

  CS2Map? get selectedMap {
    return _selectedMap == const NoneCS2Map() ? null : _selectedMap;
  }

  Grenade? get selectedGrenade {
    return _selectedGrenade == Grenade.none ? null : _selectedGrenade;
  }

  @override
  List<Object> get props {
    return [
      maps,
      _selectedMap,
      _selectedGrenade,
      description,
      selectedPosition,
      message,
      pathToVideo,
      throwingSteps,
      pendingThrowingStepType,
      pendingThrowingStepImage,
    ];
  }

  AddThrowingState copyWith({
    List<CS2Map>? maps,
    CS2Map? selectedMap,
    Grenade? selectedGrenade,
    Offset? selectedPosition,
    String? message,
    String? description,
    String? pathToVideo,
    List<ThrowingStep>? throwingSteps,
    ThrowingStepType? pendingThrowingStepType,
    PlatformFile? pendingThrowingStepImage,
  }) {
    return AddThrowingState(
      maps: maps ?? this.maps,
      selectedMap: selectedMap ?? _selectedMap,
      selectedGrenade: selectedGrenade ?? _selectedGrenade,
      selectedPosition: selectedPosition ?? this.selectedPosition,
      message: message ?? this.message,
      description: description ?? this.description,
      throwingSteps: throwingSteps ?? this.throwingSteps,
      pendingThrowingStepType:
          pendingThrowingStepType ?? this.pendingThrowingStepType,
      pendingThrowingStepImage:
          pendingThrowingStepImage ?? this.pendingThrowingStepImage,
    );
  }
}
