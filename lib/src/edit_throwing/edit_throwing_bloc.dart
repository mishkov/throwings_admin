import 'dart:io' as io;
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:throwings_admin/src/add_throwing/picked_file_to_core_file.dart';
import 'package:throwings_core/throwings_core.dart';
import 'package:uuid/uuid.dart';

class EditThrowingBloc extends Cubit<EditThrowingState> {
  final CS2MapsReader mapsReader;

  EditThrowingBloc({
    required this.mapsReader,
  }) : super(EditThrowingState());

  Future<void> init({required Throwing editingThrowing}) async {
    _reset();
    await _fetchMaps();

    emit(
      state.copyWith(
        throwingId: editingThrowing.id,
        originThrowing: editingThrowing,
        selectedMap: editingThrowing.map,
        selectedGrenade: editingThrowing.grenade,
        description: editingThrowing.description,
        howToThrowText: editingThrowing.howToThrowText,
        selectedPosition: editingThrowing.selectedPosition,
      ),
    );

    final storage = FirebaseStorage.instance;

    final videoRef = storage.ref(editingThrowing.pathToVideo);
    final pathToNetworkVideo = await videoRef.getDownloadURL();
    emit(
      state.copyWith(
        pathToNetworkVideo: pathToNetworkVideo,
      ),
    );

    final throwingSteps = <PendingThrowingStep>[];
    for (final originStep in editingThrowing.throwingSteps) {
      final imageRef = storage.ref(originStep.pathToImage);
      final downloadUrl = await imageRef.getDownloadURL();

      throwingSteps.add(PendingThrowingStep(
        imageFile: originStep.imageFile,
        pathToImage: originStep.pathToImage,
        pathToNetworkImage: downloadUrl,
        type: originStep.type,
      ));

      emit(
        state.copyWith(
          throwingSteps: throwingSteps,
        ),
      );
    }
  }

  Future<void> _fetchMaps() async {
    try {
      final maps = await mapsReader.getMaps();

      emit(state.copyWith(maps: maps));
    } catch (error) {
      emit(state.copyWith(message: 'Ошибка получения карт: $error'));
      throwInDebug(error);
    }
  }

  /// Retuns false if error occured.
  bool addPendingThrowingStep() {
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
            PendingThrowingStep(
              requiredAction: PendingThrowingStepAction.upload,
              imageFile: state.pendingThrowingStepImage.toCoreFile(),
              type: state.pendingThrowingStepType,
            ),
          ),
      ),
    );

    return true;
  }

  void removeThrowingStep(PendingThrowingStep step) {
    if (step.pathToImage.isNotEmpty) {
      emit(
        state.copyWith(
          throwingSteps: List.of(state.throwingSteps)
            ..remove(
              step,
            )
            ..add(step.copyWith(
              requiredAction: PendingThrowingStepAction.remove,
            ) as PendingThrowingStep),
        ),
      );
    }

    emit(
      state.copyWith(
        throwingSteps: List.of(state.throwingSteps)
          ..remove(
            step,
          ),
      ),
    );
  }

  void reorderThrowingStep(int oldIndex, int newIndex) {
    final copy = List.of(state.throwingSteps.withoutStepsToDelete);
    final reorderedStep = copy.removeAt(oldIndex);
    if (newIndex >= copy.length) {
      copy.add(reorderedStep);
    } else {
      copy.insert(newIndex, reorderedStep);
    }

    emit(
      state.copyWith(
        throwingSteps: copy..addAll(state.throwingSteps.onlyStepsToDelete),
      ),
    );
  }

  void _reset() {
    emit(EditThrowingState());
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

  void setSelectedPosition(Point position) {
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

  /// Returns true if throwing was successfully updated.
  Future<bool> submitEditing() async {
    try {
      if (state.selectedMap == null) {
        emit(state.copyWith(message: 'Выберите карту'));

        return false;
      }

      if (state.selectedGrenade == null) {
        emit(state.copyWith(message: 'Выберите тип гранат'));

        return false;
      }

      if (state.selectedPosition == const Point(0, 0)) {
        emit(state.copyWith(message: 'Выберите позицию'));

        return false;
      }

      if (state.video.size == 0 && state.originThrowing.pathToVideo.isEmpty) {
        emit(state.copyWith(message: 'Добавьте видео'));

        return false;
      }

      final addedSteps =
          state.throwingSteps.withoutStepsToDelete.map((e) => e.type).toSet();
      const requiredSteps = {
        ThrowingStepType.positioning,
        ThrowingStepType.aiming,
        ThrowingStepType.zoomedAiming,
        ThrowingStepType.result,
      };
      final requiredStepsAdded = addedSteps.containsAll(requiredSteps);
      if (!requiredStepsAdded) {
        final missingSteps = requiredSteps.difference(addedSteps);
        final missingStepsReadleName = missingSteps.map((e) => e.readableName);
        final missingStepsString = missingStepsReadleName.join(', ');

        emit(
          state.copyWith(
            message: 'Добавьте шаги: $missingStepsString',
          ),
        );

        return false;
      }

      // load steps images
      final storage = FirebaseStorage.instance;
      final root = storage.ref();

      final videos = root.child('videos');
      String? pathToVideo;
      // Update video if storage.
      if (state.video.path == null) {
        // Do nothing because video is not changed.
      } else if (state.originThrowing.pathToVideo.isEmpty) {
        // Updload new video because early it was not uploaded.
        final videoRef =
            videos.child('${const Uuid().v4()}-${state.video.name}');
        await videoRef.putFile(io.File(state.video.path!));
        pathToVideo = videoRef.fullPath;
      } else {
        // Remove previous video and upload new.

        // Remove.
        final previousVideoRef = storage.ref(state.originThrowing.pathToVideo);
        await previousVideoRef.delete();

        // Upload.
        final videoRef =
            videos.child('${const Uuid().v4()}-${state.video.name}');
        await videoRef.putFile(io.File(state.video.path!));
        pathToVideo = videoRef.fullPath;
      }

      final steps = root.child('steps');

      final stepsImagesToRemove =
          state.throwingSteps.onlyStepsToDelete.map((e) => e.pathToImage);

      for (final url in stepsImagesToRemove) {
        assert(
          url.isNotEmpty,
          'The url of the image must be not null. Verify your logic',
        );

        final imageRef = storage.ref(url);
        await imageRef.delete();
      }

      emit(
        state.copyWith(
          throwingSteps: List.of(state.throwingSteps)
            ..removeWhere(
              (step) => step.requiredAction == PendingThrowingStepAction.remove,
            ),
        ),
      );

      assert(
        state.throwingSteps.every(
          (step) => step.requiredAction != PendingThrowingStepAction.reorder,
        ),
        'Reordering is not supported at the moment. Review your code logic.',
      );

      Map<ThrowingStep, String> pathToStepImage = {};
      for (final step in state.throwingSteps) {
        if (step.requiredAction == PendingThrowingStepAction.none) {
          assert(
            step.pathToImage.isNotEmpty,
            'Expected that step with [PendingThrowingStepAction.none] contains url to image',
          );

          pathToStepImage[step] = step.pathToImage;

          continue;
        }

        assert(
          step.imageFile.name != null,
          'step must have name to be uploaded',
        );

        final stepImageRef =
            steps.child('${const Uuid().v4()}-${step.imageFile.name}');
        assert(
          step.imageFile.path != null,
          'Make sure you have set the [throwings_core.File.path] when adding the step.',
        );
        await stepImageRef.putFile(io.File(step.imageFile.path!));

        pathToStepImage[step] = stepImageRef.fullPath;
      }

      final db = FirebaseFirestore.instance;

      final throwing = <String, dynamic>{
        'map': state._selectedMap.id,
        'grenade': state._selectedGrenade.name,
        'description': state.description,
        'howToThrowText': state.howToThrowText,
        if (pathToVideo != null) 'videoPath': pathToVideo,
        'position': {
          'dx': state.selectedPosition.x,
          'dy': state.selectedPosition.y,
        },
        'steps': [
          for (final step in state.throwingSteps)
            {
              'type': step.type.name,
              'pathToImage': pathToStepImage[step],
            },
        ],
      };

      assert(
        state.throwingId.isNotEmpty,
        'Make sure you have initialized the [throwingsId] before updating the document in firebase',
      );

      await db.collection("throwings").doc(state.throwingId).update(throwing);

      emit(
        state.copyWith(
          message: 'Document with ID: ${state.throwingId} is updated',
        ),
      );

      return true;
    } catch (error) {
      emit(state.copyWith(message: 'Ошибка: $error'));

      throwInDebug(error);

      return false;
    }
  }

  /// Returns true if throwing was successfully deleted.
  Future<bool> deleteThrowing() async {
    try {
      final db = FirebaseFirestore.instance;
      await db.collection("throwings").doc(state.throwingId).delete();

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

class EditThrowingState extends Equatable {
  final String throwingId;
  final Throwing originThrowing;
  final List<CS2Map> maps;
  final CS2Map _selectedMap;
  final Grenade _selectedGrenade;
  final String description;
  final Point selectedPosition;
  final String message;

  final List<PendingThrowingStep> throwingSteps;
  final ThrowingStepType pendingThrowingStepType;
  final PlatformFile pendingThrowingStepImage;
  final PlatformFile video;
  final String howToThrowText;
  final String pathToNetworkVideo;

  EditThrowingState({
    CS2Map selectedMap = const NoneCS2Map(),
    this.maps = const [],
    Grenade selectedGrenade = Grenade.none,
    this.selectedPosition = const Point<double>(0, 0),
    this.message = '',
    this.description = '',
    this.throwingSteps = const [],
    PlatformFile? pendingThrowingStepImage,
    this.pendingThrowingStepType = ThrowingStepType.none,
    PlatformFile? video,
    this.howToThrowText = '',
    this.throwingId = '',
    this.pathToNetworkVideo = '',
    this.originThrowing = const Throwing(
      id: '',
      description: '',
      grenade: Grenade.none,
      howToThrowText: '',
      map: NoneCS2Map(),
      pathToVideo: '',
      selectedPosition: Point(0, 0),
      throwingSteps: [],
    ),
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
      throwingSteps,
      pendingThrowingStepType,
      pendingThrowingStepImage,
      video,
      howToThrowText,
      throwingId,
      originThrowing,
      pathToNetworkVideo,
    ];
  }

  EditThrowingState copyWith({
    List<CS2Map>? maps,
    CS2Map? selectedMap,
    Grenade? selectedGrenade,
    Point? selectedPosition,
    String? message,
    String? description,
    List<PendingThrowingStep>? throwingSteps,
    ThrowingStepType? pendingThrowingStepType,
    PlatformFile? pendingThrowingStepImage,
    PlatformFile? video,
    String? howToThrowText,
    String? throwingId,
    Throwing? originThrowing,
    String? pathToNetworkVideo,
  }) {
    return EditThrowingState(
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
      throwingId: throwingId ?? this.throwingId,
      originThrowing: originThrowing ?? this.originThrowing,
      pathToNetworkVideo: pathToNetworkVideo ?? this.pathToNetworkVideo,
    );
  }
}

class PendingThrowingStep extends ThrowingStep {
  final PendingThrowingStepAction requiredAction;
  final String pathToNetworkImage;

  const PendingThrowingStep({
    this.requiredAction = PendingThrowingStepAction.none,
    this.pathToNetworkImage = '',
    super.pathToImage = '',
    super.imageFile = const File(),
    required super.type,
  });

  @override
  List<Object> get props => [
        requiredAction,
        pathToNetworkImage,
        ...super.props,
      ];

  @override
  ThrowingStep copyWith({
    String? pathToImage,
    File? imageFile,
    ThrowingStepType? type,
    PendingThrowingStepAction? requiredAction,
    String? pathToNetworkImage,
  }) {
    return PendingThrowingStep(
      pathToImage: pathToImage ?? this.pathToImage,
      imageFile: imageFile ?? this.imageFile,
      type: type ?? this.type,
      requiredAction: requiredAction ?? this.requiredAction,
      pathToNetworkImage: pathToNetworkImage ?? this.pathToNetworkImage,
    );
  }
}

enum PendingThrowingStepAction {
  /// The previous step was reordered.
  reorder,

  /// The new step is added.
  upload,

  /// The origin step was removed.
  remove,

  /// The step was not changed.
  none,
}

extension PendingsThrowingStepsWithoutStepsToDelete
    on List<PendingThrowingStep> {
  List<PendingThrowingStep> get withoutStepsToDelete {
    return where((step) {
      return step.requiredAction != PendingThrowingStepAction.remove;
    }).toList();
  }

  List<PendingThrowingStep> get onlyStepsToDelete {
    return where((step) {
      return step.requiredAction == PendingThrowingStepAction.remove;
    }).toList();
  }
}
