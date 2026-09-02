import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:just_audio/just_audio.dart';
import '../../data/datasources/music_local_data_source.dart';
import '../../domain/entities/track.dart';

final audioPlayerProvider =
    StateNotifierProvider<AudioPlayerNotifier, AudioPlayerState>((ref) {
      return AudioPlayerNotifier();
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
  final MusicLocalDataSource _localDataSource = MusicLocalDataSource();

  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  AudioPlayerNotifier() : super(const AudioPlayerState()) {
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
      state = state.copyWith(isPlaying: playerState.playing);

      if (playerState.processingState == ProcessingState.completed) {
        _playNextAutomatically();
      }
    });
  }

  Future<void> playTrack(Track track, {List<Track>? playlist}) async {
    if (track.audio.isEmpty) {
      return;
    }

    try {
      await _localDataSource.init();

      final tracks = playlist ?? state.tracks;

      int index = tracks.indexWhere((item) => item.id == track.id);

      if (index == -1) {
        index = 0;
      }

      state = state.copyWith(
        tracks: tracks,
        currentIndex: index,
        currentTrack: track,
        isLoading: true,
        isPlaying: false,
        position: Duration.zero,
        duration: Duration.zero,
      );

      final player = _player;
      if (player == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      await player.stop();

      final audio =
          _localDataSource.getCachedAudio(track.audio) ??
          await _localDataSource.cacheAudio(track.audio);

      if (audio != null) {
        try {
          await player.setAudioSource(_CachedAudioSource(audio));
          await player.play();
        } catch (_) {
          await player.setUrl(track.audio);
          await player.play();
        }
      } else {
        await player.setUrl(track.audio);
        await player.play();
      }

      state = state.copyWith(isLoading: false, isPlaying: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, isPlaying: false);
    }
  }

  Future<void> playPause() async {
    if (state.currentTrack == null || state.isLoading) {
      return;
    }

    try {
      final player = _player;
      if (player == null) return;

      if (player.playing) {
        await player.pause();
      } else {
        await player.play();
      }
    } catch (e) {
      // Error handling can be added here if needed
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
      await _player?.seek(Duration.zero);
      return;
    }

    final previousIndex = state.currentIndex - 1;

    if (previousIndex < 0) {
      return;
    }

    await playTrack(state.tracks[previousIndex], playlist: state.tracks);
  }

  Future<void> _playNextAutomatically() async {
    if (state.tracks.isEmpty) {
      return;
    }

    final nextIndex = state.currentIndex + 1;

    if (nextIndex >= state.tracks.length) {
      state = state.copyWith(isPlaying: false, position: state.duration);
      return;
    }

    await playTrack(state.tracks[nextIndex], playlist: state.tracks);
  }

  Future<void> seek(Duration position) async {
    await _player?.seek(position);
  }

  Future<void> stop() async {
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
    final rangeStart = start ?? 0;
    final rangeEnd = end ?? audio.length;

    return StreamAudioResponse(
      contentType: 'audio/mpeg',
      stream: Stream.value(audio.sublist(rangeStart, rangeEnd)),
      contentLength: rangeEnd - rangeStart,
      offset: rangeStart,
      sourceLength: audio.length,
    );
  }
}
