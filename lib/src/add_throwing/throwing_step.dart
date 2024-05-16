import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:throwings_admin/src/add_throwing/add_throwing_view.dart';

class ThrowingStep extends Equatable {
  final PlatformFile file;
  final ThrowingStepType type;

  const ThrowingStep({
    required this.file,
    required this.type,
  });

  @override
  List<Object> get props => [file, type];

  ThrowingStep copyWith({
    PlatformFile? file,
    ThrowingStepType? type,
  }) {
    return ThrowingStep(
      file: file ?? this.file,
      type: type ?? this.type,
    );
  }
}
