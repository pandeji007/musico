import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuneflow/features/music/presentation/screens/playing_screen.dart';

import '../../../../core/constants/app_colors.dart';
import '../providers/audio_player_provider.dart';

class MiniPlayer extends ConsumerWidget {
  final VoidCallback? onTap;

  const MiniPlayer({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(audioPlayerProvider);
    final track = playerState.currentTrack;

    // Don't show the mini player until a track has been selected.
    if (track == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onTap ??
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NowPlayingScreen(),
              ),
            );
          },
      child: SafeArea(
        top: false,
        child: Container(
          height: 76,
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(
              top: BorderSide(
                color: AppColors.primary,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              // Artwork
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  track.image,
                  width: 58,
                  height: 58,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
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
      ),
    );
  }
}
