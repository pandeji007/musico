import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:just_audio/just_audio.dart';
import 'package:tuneflow/features/music/presentation/providers/music_provider.dart';
import '../../data/datasources/music_local_data_source.dart';
import '../../domain/entities/track.dart';

final audioPlayerProvider =
    StateNotifierProvider<AudioPlayerNotifier, AudioPlayerState>((ref) {
      final localDataSource = ref.watch(musicLocalDataSourceProvider);
      return AudioPlayerNotifier(localDataSource: localDataSource);
    });

class AudioPlayerState {
  final List<Track> tracks;
  final int currentIndex;
  final Track? currentTrack;

  final bool isPlaying;
  final bool isLoading;

  final Duration position;
  final Duration duration;

  const AudioPlayerState({
    this.tracks = const [],
    this.currentIndex = -1,
    this.currentTrack,
    this.isPlaying = false,
    this.isLoading = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
  });

  AudioPlayerState copyWith({
    List<Track>? tracks,
    int? currentIndex,
    Track? currentTrack,
    bool? isPlaying,
    bool? isLoading,
    Duration? position,
    Duration? duration,
  }) {
    return AudioPlayerState(
      tracks: tracks ?? this.tracks,
      currentIndex: currentIndex ?? this.currentIndex,
      currentTrack: currentTrack ?? this.currentTrack,
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      position: position ?? this.position,
      duration: duration ?? this.duration,
    );
  }
}

class AudioPlayerNotifier extends StateNotifier<AudioPlayerState> {
  AudioPlayer? _player;
  final MusicLocalDataSource _localDataSource;

  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  int _playSessionId = 0;
  bool _isSettingSource = false;
  bool _shouldPlayOnLoad = true;
  int? _lastCompletedIndex;

  AudioPlayerNotifier({required MusicLocalDataSource localDataSource})
    : _localDataSource = localDataSource,
      super(const AudioPlayerState()) {
    if (_isAudioSupported) {
      _player = AudioPlayer();
      _listenToPlayer();
    }
  }

  static bool get _isAudioSupported {
    if (kIsWeb) return true;

    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  void _listenToPlayer() {
    final player = _player;
    if (player == null) return;

    _positionSubscription = player.positionStream.listen((position) {
      state = state.copyWith(position: position);
    });

    _durationSubscription = player.durationStream.listen((duration) {
      state = state.copyWith(duration: duration ?? Duration.zero);
    });

    _playerStateSubscription = player.playerStateStream.listen((playerState) {
      if (!_isSettingSource) {
        final isBuffering =
            playerState.processingState == ProcessingState.buffering;
        state = state.copyWith(
          isPlaying: playerState.playing,
          isLoading: isBuffering,
        );
      }

      if (playerState.processingState == ProcessingState.completed) {
        _playNextAutomatically();
      }
    });
  }

  Future<void> playTrack(Track track, {List<Track>? playlist}) async {
    if (track.audio.isEmpty) {
      return;
    }

    final sessionId = ++_playSessionId;
    _isSettingSource = true;
    _shouldPlayOnLoad = true;
    _lastCompletedIndex = null;

    final tracks = playlist ?? state.tracks;
    int index = tracks.indexWhere((item) => item.id == track.id);
    if (index == -1) index = 0;

    // Optimistically update track info and immediately show playing state
    state = state.copyWith(
      tracks: tracks,
      currentIndex: index,
      currentTrack: track,
      isLoading: true,
      isPlaying: true,
      position: Duration.zero,
      duration: Duration.zero,
    );

    final player = _player;
    if (player == null) {
      _isSettingSource = false;
      state = state.copyWith(isLoading: false, isPlaying: false);
      return;
    }

    try {
      // 1. Check if audio is already cached
      final cachedAudio = _localDataSource.getCachedAudio(track.audio);

      if (sessionId != _playSessionId) return;

      if (cachedAudio != null) {
        try {
          await player.setAudioSource(_CachedAudioSource(cachedAudio));
        } catch (_) {
          if (sessionId != _playSessionId) return;
          await player.setUrl(track.audio);
        }
      } else {
        // 2. Not cached: Start playing from URL immediately
        await player.setUrl(track.audio);

        // Cache in background for future offline / instant playback
        unawaited(_localDataSource.cacheAudio(track.audio));
      }

      if (sessionId != _playSessionId) return;

      _isSettingSource = false;

      if (_shouldPlayOnLoad) {
        unawaited(player.play());
        state = state.copyWith(isLoading: false, isPlaying: true);
      } else {
        await player.pause();
        state = state.copyWith(isLoading: false, isPlaying: false);
      }

      // Prefetch next track in background for instant switching
      final nextIdx = index + 1;
      if (nextIdx < tracks.length && tracks[nextIdx].audio.isNotEmpty) {
        unawaited(_localDataSource.cacheAudio(tracks[nextIdx].audio));
      }
    } catch (e) {
      if (sessionId != _playSessionId) return;

      _isSettingSource = false;
      state = state.copyWith(isLoading: false, isPlaying: false);
    }
  }

  Future<void> playPause() async {
    if (state.currentTrack == null) {
      return;
    }

    // If currently switching or loading track, safely toggle playback intent without aborting native load
    if (_isSettingSource) {
      _shouldPlayOnLoad = !_shouldPlayOnLoad;
      state = state.copyWith(isPlaying: _shouldPlayOnLoad);
      return;
    }

    final player = _player;
    if (player == null) return;

    try {
      if (player.playing) {
        state = state.copyWith(isPlaying: false);
        await player.pause();
      } else {
        state = state.copyWith(isPlaying: true);
        unawaited(player.play());
      }
    } catch (e) {
      state = state.copyWith(isPlaying: player.playing);
    }
  }

  Future<void> next() async {
    if (state.tracks.isEmpty) {
      return;
    }

    final nextIndex = state.currentIndex + 1;

    if (nextIndex >= state.tracks.length) {
      return;
    }

    await playTrack(state.tracks[nextIndex], playlist: state.tracks);
  }

  Future<void> previous() async {
    if (state.tracks.isEmpty) {
      return;
    }

    // If the song has played for more than 3 seconds,
    // pressing previous restarts the current song.
    if (state.position.inSeconds > 3) {
      if (!_isSettingSource) {
        await _player?.seek(Duration.zero);
      }
      return;
    }

    final previousIndex = state.currentIndex - 1;

    if (previousIndex < 0) {
      return;
    }

    await playTrack(state.tracks[previousIndex], playlist: state.tracks);
  }

  Future<void> _playNextAutomatically() async {
    if (state.tracks.isEmpty || _isSettingSource) {
      return;
    }

    final nextIndex = state.currentIndex + 1;

    if (nextIndex >= state.tracks.length) {
      state = state.copyWith(isPlaying: false, position: state.duration);
      return;
    }

    if (_lastCompletedIndex == state.currentIndex) {
      return;
    }
    _lastCompletedIndex = state.currentIndex;

    await playTrack(state.tracks[nextIndex], playlist: state.tracks);
  }

  Future<void> seek(Duration position) async {
    if (_isSettingSource) return;
    await _player?.seek(position);
  }

  Future<void> stop() async {
    _isSettingSource = false;
    _playSessionId++;
    await _player?.stop();

    state = state.copyWith(isPlaying: false, position: Duration.zero);
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerStateSubscription?.cancel();

    _player?.dispose();

    super.dispose();
  }
}

class _CachedAudioSource extends StreamAudioSource {
  final Uint8List audio;

  _CachedAudioSource(this.audio);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final rangeStart = (start ?? 0).clamp(0, audio.length);
    final rangeEnd = (end ?? audio.length).clamp(rangeStart, audio.length);

    return StreamAudioResponse(
      contentType: 'audio/mpeg',
      stream: Stream.value(audio.sublist(rangeStart, rangeEnd)),
      contentLength: rangeEnd - rangeStart,
      offset: rangeStart,
      sourceLength: audio.length,
    );
  }
}
