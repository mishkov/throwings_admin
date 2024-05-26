import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:throwings_core/throwings_core.dart';

class HomeBloc extends Cubit<HomeState> {
  final CS2MapsReader mapsReader;
  final ThrowingsReader throwingsReader;

  HomeBloc({
    required this.mapsReader,
    required this.throwingsReader,
  }) : super(const HomeState.initial());

  Future<void> fetchData() async {
    await _fetchMaps();
    await _fetchThrowings();
  }

  Future<void> _fetchMaps() async {
    try {
      emit(state.copyWith(isLoading: true));

      final maps = await mapsReader.getMaps();

      emit(state.copyWith(maps: maps));
    } catch (error) {
      emit(state.copyWith(message: 'Ошибка получения карт: $error'));
    } finally {
      emit(state.copyWith(isLoading: false));
    }
  } 

  /// Call [_fetchMaps] before this method.
  Future<void> _fetchThrowings() async {
    try {
      emit(state.copyWith(isLoading: true));

      final throwings = await throwingsReader.getThrowings(maps: state.maps);

      emit(state.copyWith(throwings: throwings));
    } catch (error) {
      emit(state.copyWith(message: 'Ошибка получения раскидок: $error'));
    } finally {
      emit(state.copyWith(isLoading: false));
    }
  }
}

class HomeState extends Equatable {
  final List<CS2Map> maps;
  final List<Throwing> throwings;
  final String message;
  final bool isLoading;

  const HomeState({
    required this.maps,
    required this.throwings,
    required this.message,
    required this.isLoading,
  });

  const HomeState.initial()
      : maps = const [],
        throwings = const [],
        message = '',
        isLoading = false;

  HomeState copyWith({
    List<CS2Map>? maps,
    List<Throwing>? throwings,
    String? message,
    bool? isLoading,
  }) {
    return HomeState(
      maps: maps ?? this.maps,
      throwings: throwings ?? this.throwings,
      message: message ?? this.message,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object> get props => [maps, throwings, message, isLoading];
}
