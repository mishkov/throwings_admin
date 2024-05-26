import 'package:file_picker/file_picker.dart';
import 'package:throwings_core/throwings_core.dart';

extension PickedFileToCoreFile on PlatformFile {
  File toCoreFile() {
    return File(
      path: path,
      name: name,
      bytes: bytes,
    );
  }
}
