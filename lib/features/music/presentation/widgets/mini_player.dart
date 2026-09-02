import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuneflow/features/music/presentation/screens/playing_screen.dart';

import '../../../../core/constants/app_colors.dart';
import '../providers/audio_player_provider.dart';

class MiniPlayer extends ConsumerWidget {
  final VoidCallback? onTap;

  const MiniPlayer({super.key, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(audioPlayerProvider);
    final track = playerState.currentTrack;

    // Don't show the mini player until a track has been selected.
    if (track == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap:
          onTap ??
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NowPlayingScreen()),
            );
          },
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 80,
          child: Stack(
            children: [
              // Progress bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: LinearProgressIndicator(
                    minHeight: 3,
                    value: playerState.duration.inMilliseconds > 0
                        ? (playerState.position.inMilliseconds /
                                  playerState.duration.inMilliseconds)
                              .clamp(0.0, 1.0)
                        : 0.0,
                    backgroundColor: AppColors.white.withValues(alpha: 0.15),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
              ),

              // Main content
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Row(
                  children: [
                    // Artwork
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        track.image,
                        width: 58,
                        height: 58,
                        cacheWidth: 120,
                        cacheHeight: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) {
                          return Container(
                            width: 58,
                            height: 58,
                            color: AppColors.background,
                            child: const Icon(
                              Icons.music_note,
                              color: AppColors.primary,
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Track information
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            track.artistName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.white.withValues(alpha: 0.65),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Play / Pause
                    IconButton(
                      onPressed: () {
                        ref.read(audioPlayerProvider.notifier).playPause();
                      },
                      icon: Icon(
                        playerState.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: AppColors.primary,
                        size: 32,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
