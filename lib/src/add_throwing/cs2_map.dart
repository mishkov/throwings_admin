import 'package:equatable/equatable.dart';

class CS2Map extends Equatable {
  final String id;

  final String name;

  final String pathToImage;

  const CS2Map({
    required this.id,
    required this.name,
    required this.pathToImage,
  });

  @override
  List<Object> get props => [id, name, pathToImage];
}

/// Use this class to indicate that no map is selected.
class NoneCS2Map extends CS2Map {
  const NoneCS2Map() : super(name: '', id: '', pathToImage: '');
}
