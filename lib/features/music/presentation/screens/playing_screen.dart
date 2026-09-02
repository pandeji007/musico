import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../providers/audio_player_provider.dart';

class NowPlayingScreen extends ConsumerWidget {
  const NowPlayingScreen({super.key});

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(audioPlayerProvider);
    final track = playerState.currentTrack;

    if (track == null) {
      return const Scaffold(
        body: Center(
          child: Text('No song playing'),
        ),
      );
    }

    final duration = playerState.duration;
    final position = playerState.position;

    final maxSeconds = duration.inSeconds > 0
        ? duration.inSeconds.toDouble()
        : 1.0;

    final currentSeconds = position.inSeconds
        .clamp(0, duration.inSeconds > 0 ? duration.inSeconds : 1)
        .toDouble();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Now Playing'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
          ),
          child: Column(
            children: [
              const Spacer(),

              // Artwork
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.network(
                    track.image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return Container(
                        color: AppColors.surface,
                        child: const Icon(
                          Icons.music_note_rounded,
                          color: AppColors.primary,
                          size: 100,
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Song title
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  track.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Artist
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  track.artistName,
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.65),
                    fontSize: 16,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Progress slider
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.primary,
                  inactiveTrackColor:
                  AppColors.white.withValues(alpha: 0.2),
                  thumbColor: AppColors.primary,
                  overlayColor:
                  AppColors.primary.withValues(alpha: 0.15),
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 6,
                  ),
                ),
                child: Slider(
                  min: 0,
                  max: maxSeconds,
                  value: currentSeconds,
                  onChanged: (value) {
                    ref
                        .read(audioPlayerProvider.notifier)
                        .seek(
                      Duration(
                        milliseconds: (value * 1000).round(),
                      ),
                    );
                  },
                ),
              ),

              // Time
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(position),
                      style: TextStyle(
                        color:
                        AppColors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      _formatDuration(duration),
                      style: TextStyle(
                        color:
                        AppColors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () {
                      ref
                          .read(audioPlayerProvider.notifier)
                          .previous();
                    },
                    icon: const Icon(
                      Icons.skip_previous_rounded,
                      color: AppColors.white,
                      size: 42,
                    ),
                  ),

                  const SizedBox(width: 20),

                  Container(
                    width: 68,
                    height: 68,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () {
                        ref
                            .read(
                          audioPlayerProvider.notifier,
                        )
                            .playPause();
                      },
                      icon: Icon(
                        playerState.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: AppColors.background,
                        size: 38,
                      ),
                    ),
                  ),

                  const SizedBox(width: 20),

                  IconButton(
                    onPressed: () {
                      ref
                          .read(audioPlayerProvider.notifier)
                          .next();
                    },
                    icon: const Icon(
                      Icons.skip_next_rounded,
                      color: AppColors.white,
                      size: 42,
                    ),
                  ),
                ],
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}