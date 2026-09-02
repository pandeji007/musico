import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:just_audio/just_audio.dart';
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
  final AudioPlayer _player = AudioPlayer();

  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  AudioPlayerNotifier() : super(const AudioPlayerState()) {
    _listenToPlayer();
  }

  void _listenToPlayer() {
    _positionSubscription = _player.positionStream.listen((position) {
      state = state.copyWith(position: position);
    });

    _durationSubscription = _player.durationStream.listen((duration) {
      state = state.copyWith(duration: duration ?? Duration.zero);
    });

    _playerStateSubscription = _player.playerStateStream.listen((playerState) {
      state = state.copyWith(isPlaying: playerState.playing);

      if (playerState.processingState == ProcessingState.completed) {
        _playNextAutomatically();
      }
    });
  }

  Future<void> playTrack(Track track, {List<Track>? playlist}) async {
    if (track.audio.isEmpty) {
      debugPrint('Audio URL is empty for: ${track.name}');
      return;
    }

    try {
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

      await _player.stop();

      await _player.setUrl(track.audio);

      await _player.play();

      state = state.copyWith(isLoading: false, isPlaying: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, isPlaying: false);

      debugPrint('AUDIO PLAYER ERROR: $e');
    }
  }

  Future<void> playPause() async {
    if (state.currentTrack == null || state.isLoading) {
      return;
    }

    try {
      if (_player.playing) {
        await _player.pause();
      } else {
        await _player.play();
      }
    } catch (e) {
      debugPrint('PLAY/PAUSE ERROR: $e');
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
      await _player.seek(Duration.zero);
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
    await _player.seek(position);
  }

  Future<void> stop() async {
    await _player.stop();

    state = state.copyWith(isPlaying: false, position: Duration.zero);
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerStateSubscription?.cancel();

    _player.dispose();

    super.dispose();
  }
}
