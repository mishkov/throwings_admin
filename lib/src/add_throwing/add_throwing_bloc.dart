import 'dart:io' as io;
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:throwings_admin/src/add_throwing/picked_file_to_core_file.dart';
import 'package:throwings_core/throwings_core.dart';
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
              imageFile: state.pendingThrowingStepImage.toCoreFile(),
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

  void setHowToThrowText(String value) {
    emit(state.copyWith(howToThrowText: value));
  }

  void setVideo(PlatformFile value) {
    emit(state.copyWith(video: value));
  }

  void setPendingThrowingStepType(ThrowingStepType throwingStepType) {
    emit(state.copyWith(pendingThrowingStepType: throwingStepType));
  }

  /// Return true if throwings was successfully added.
  Future<bool> submitAdding() async {
    try {
      if (state.selectedMap == null) {
        emit(state.copyWith(message: 'Выберите карту'));

        return false;
      }

      if (state.selectedGrenade == null) {
        emit(state.copyWith(message: 'Выберите тип гранат'));

        return false;
      }

      if (state.selectedPosition == Offset.zero) {
        emit(state.copyWith(message: 'Выберите позицию'));

        return false;
      }

      if (state.video.size == 0) {
        emit(state.copyWith(message: 'Добавьте видео'));

        return false;
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
                'Добавьте шаги: ${requiredSteps.difference(addedSteps).map((e) => e.readableName).join(', ')}'));

        return false;
      }

      // load steps images
      final storage = FirebaseStorage.instance;
      final root = storage.ref();

      final videos = root.child('videos');
      final videoRef = videos.child('${const Uuid().v4()}-${state.video.name}');
      await videoRef.putFile(io.File(state.video.path!));

      final maps = root.child('steps');

      Map<ThrowingStep, String> pathTostepImage = {};
      for (final step in state.throwingSteps) {
        final stepRef =
            maps.child('${const Uuid().v4()}-${step.imageFile.name}');
        assert(
          step.imageFile.path != null,
          'Make sure you have set the [throwings_core.File.path] when adding the step.',
        );
        await stepRef.putFile(io.File(step.imageFile.path!));

        pathTostepImage[step] = stepRef.fullPath;
      }

      final db = FirebaseFirestore.instance;

      final throwing = <String, dynamic>{
        "map": state._selectedMap.id,
        "grenade": state._selectedGrenade.name,
        'description': state.description,
        'howToThrowText': state.howToThrowText,
        'videoPath': videoRef.fullPath,
        "position": {
          'dx': state.selectedPosition.dx,
          'dy': state.selectedPosition.dy,
        },
        'steps': [
          for (final step in state.throwingSteps)
            {
              'type': step.type.name,
              'pathToImage': pathTostepImage[step],
            },
        ],
      };

      final doc = await db.collection("throwings").add(throwing);

      emit(
        state.copyWith(
          message: 'DocumentSnapshot added with ID: ${doc.id}',
        ),
      );

      return true;
    } catch (error) {
      emit(state.copyWith(message: 'Ошибка: $error'));
      throwInDebug(error);

      return false;
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
  final PlatformFile video;
  final String howToThrowText;

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
    PlatformFile? video,
    this.howToThrowText = '',
  })  : _selectedGrenade = selectedGrenade,
        _selectedMap = selectedMap,
        pendingThrowingStepImage =
            pendingThrowingStepImage ?? PlatformFile(name: 'none.png', size: 0),
        video = video ?? PlatformFile(name: 'none.mp4', size: 0);

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
      video,
      howToThrowText,
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
    PlatformFile? video,
    String? howToThrowText,
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
      video: video ?? this.video,
      howToThrowText: howToThrowText ?? this.howToThrowText,
    );
  }
}
