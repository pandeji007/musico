import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:tuneflow/core/constants/app_config.dart';
import 'package:tuneflow/features/music/data/datasources/music_source.dart';
import 'package:tuneflow/features/music/domain/repositories/music_repository_impl.dart';

import '../../../../core/network/dio_client.dart';
import '../../domain/entities/track.dart';
import '../../domain/repositories/music_repository.dart';

final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient();
});

final musicRemoteDataSourceProvider = Provider<MusicRemoteDataSource>((ref) {
  return MusicRemoteDataSource(
    dioClient: ref.read(dioClientProvider),
  );
});

final musicRepositoryProvider = Provider<MusicRepository>((ref) {
  return MusicRepositoryImpl(
    remoteDataSource: ref.read(musicRemoteDataSourceProvider),
  );
});

final musicProvider =
StateNotifierProvider<MusicNotifier, MusicState>((ref) {
  return MusicNotifier(

    repository: ref.read(musicRepositoryProvider),
  );
});

class MusicState {
  final List<Track> tracks;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? errorMessage;
  final String searchQuery;

  const MusicState({
    this.tracks = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.errorMessage,
    this.searchQuery = '',
  });

  MusicState copyWith({
    List<Track>? tracks,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? errorMessage,
    String? searchQuery,
    bool clearError = false,
  }) {
    return MusicState(
      tracks: tracks ?? this.tracks,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: clearError
          ? null
          : errorMessage ?? this.errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class MusicNotifier extends StateNotifier<MusicState> {
  final MusicRepository repository;
  bool _hasLoadedInitialData = false;

  MusicNotifier({
    required this.repository,
  }) : super(const MusicState());

  Future<void> loadTracks() async {
    if (state.isLoading || _hasLoadedInitialData) {
      return;
    }

    _hasLoadedInitialData = true;

    print('==============================');
    print('LOAD TRACKS STARTED');
    print('CLIENT ID: ${ApiConstants.clientId}');
    print('==============================');

    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final tracks = await repository.getTracks(
        offset: 0,
      );

      print('TRACKS RECEIVED: ${tracks.length}');

      state = state.copyWith(
        tracks: tracks,
        isLoading: false,
        hasMore: tracks.length >= ApiConstants.pageSize,
        clearError: true,
      );

      print('STATE UPDATED');
      print('STATE TRACK COUNT: ${state.tracks.length}');
      print('==============================');
    } catch (e) {
      print('==============================');
      print('LOAD TRACKS ERROR');
      print(e);
      print('==============================');

      // Allow retry if the initial request failed.
      _hasLoadedInitialData = false;

      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
  Future<void> loadMore() async {
    if (state.isLoading ||
        state.isLoadingMore ||
        !state.hasMore) {
      return;
    }

    state = state.copyWith(
      isLoadingMore: true,
      clearError: true,
    );

    try {
      final newTracks = state.searchQuery.isEmpty
          ? await repository.getTracks(
        offset: state.tracks.length,
      )
          : await repository.searchTracks(
        query: state.searchQuery,
        offset: state.tracks.length,
      );

      final allTracks = [
        ...state.tracks,
        ...newTracks,
      ];

      state = state.copyWith(
        tracks: allTracks,
        isLoadingMore: false,
        hasMore: newTracks.length >= ApiConstants.pageSize,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> search(String query) async {
    final trimmedQuery = query.trim();

    if (trimmedQuery.isEmpty) {
      state = const MusicState();
      await loadTracks();
      return;
    }

    state = state.copyWith(
      tracks: [],
      isLoading: true,
      isLoadingMore: false,
      hasMore: true,
      searchQuery: trimmedQuery,
      clearError: true,
    );

    try {
      final tracks = await repository.searchTracks(
        query: trimmedQuery,
        offset: 0,
      );

      state = state.copyWith(
        tracks: tracks,
        isLoading: false,
        hasMore: tracks.length >= ApiConstants.pageSize,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
}