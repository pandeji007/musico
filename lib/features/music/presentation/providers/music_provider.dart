import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:tuneflow/core/constants/app_config.dart';
import 'package:tuneflow/features/music/data/datasources/music_source.dart';
import 'package:tuneflow/features/music/domain/repositories/music_repository_impl.dart';
import 'dart:async';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/track.dart';
import '../../domain/repositories/music_repository.dart';

final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient();
});

final musicRemoteDataSourceProvider = Provider<MusicRemoteDataSource>((ref) {
  return MusicRemoteDataSource(dioClient: ref.read(dioClientProvider));
});

final musicRepositoryProvider = Provider<MusicRepository>((ref) {
  return MusicRepositoryImpl(
    remoteDataSource: ref.read(musicRemoteDataSourceProvider),
  );
});

final musicProvider = StateNotifierProvider<MusicNotifier, MusicState>((ref) {
  return MusicNotifier(repository: ref.read(musicRepositoryProvider));
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
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class MusicNotifier extends StateNotifier<MusicState> {
  final MusicRepository repository;

  Timer? _searchDebounceTimer;

  int _searchRequestId = 0;

  bool _hasLoadedInitialData = false;

  MusicNotifier({required this.repository}) : super(const MusicState());

  Future<void> loadTracks({bool forceReload = false}) async {
    if (state.isLoading) {
      return;
    }

    if (_hasLoadedInitialData && !forceReload) {
      return;
    }

    _hasLoadedInitialData = true;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final tracks = await repository.getTracks(offset: 0);

      state = state.copyWith(
        tracks: tracks,
        isLoading: false,
        isLoadingMore: false,
        hasMore: tracks.length >= ApiConstants.pageSize,
        searchQuery: '',
        clearError: true,
      );
    } catch (e) {
      _hasLoadedInitialData = false;

      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void search(String query) {
    _searchDebounceTimer?.cancel();

    final trimmedQuery = query.trim();

    // User cleared the search
    if (trimmedQuery.isEmpty) {
      _searchRequestId++;

      state = const MusicState();

      loadTracks(forceReload: true);

      return;
    }

    // Show loading state immediately
    state = state.copyWith(
      tracks: [],
      isLoading: true,
      isLoadingMore: false,
      hasMore: true,
      searchQuery: trimmedQuery,
      clearError: true,
    );

    final int requestId = ++_searchRequestId;

    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        final tracks = await repository.searchTracks(
          query: trimmedQuery,
          offset: 0,
        );

        // Ignore old API response
        if (requestId != _searchRequestId) {
          return;
        }

        state = state.copyWith(
          tracks: tracks,
          isLoading: false,
          hasMore: tracks.length >= ApiConstants.pageSize,
          clearError: true,
        );
      } catch (e) {
        // Ignore old API response
        if (requestId != _searchRequestId) {
          return;
        }

        state = state.copyWith(isLoading: false, errorMessage: e.toString());
      }
    });
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) {
      return;
    }

    state = state.copyWith(isLoadingMore: true, clearError: true);

    try {
      final newTracks = state.searchQuery.isEmpty
          ? await repository.getTracks(offset: state.tracks.length)
          : await repository.searchTracks(
              query: state.searchQuery,
              offset: state.tracks.length,
            );

      final allTracks = [...state.tracks, ...newTracks];

      state = state.copyWith(
        tracks: allTracks,
        isLoadingMore: false,
        hasMore: newTracks.length >= ApiConstants.pageSize,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, errorMessage: e.toString());
    }
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    super.dispose();
  }
}
