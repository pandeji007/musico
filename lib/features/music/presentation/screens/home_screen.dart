import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuneflow/features/music/domain/entities/track.dart';
import 'package:tuneflow/features/music/presentation/providers/audio_player_provider.dart';
import 'package:tuneflow/features/music/presentation/widgets/mini_player.dart';

import '../../../../core/constants/app_colors.dart';
import '../providers/music_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(musicProvider.notifier).loadTracks();
    });

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      ref.read(musicProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(musicProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              const Text(
                'TuneFlow',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                onChanged: (value) {
                  ref.read(musicProvider.notifier).search(value);
                },
                style: const TextStyle(
                  color: AppColors.white,
                ),
                decoration: const InputDecoration(
                  hintText: 'Search music...',
                  hintStyle: TextStyle(
                    color: AppColors.white,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppColors.primary,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                'Music',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 16),

              Expanded(
                child: _buildMusicList(state),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const MiniPlayer(),
    );
  }

  Widget _buildMusicList(MusicState state) {
    if (state.isLoading && state.tracks.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      );
    }

    if (state.errorMessage != null && state.tracks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Something went wrong',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 12),

            TextButton(
              onPressed: () {
                ref.read(musicProvider.notifier).loadTracks();
              },
              child: const Text(
                'Retry',
                style: TextStyle(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (state.tracks.isEmpty) {
      return const Center(
        child: Text(
          'No music found',
          style: TextStyle(
            color: AppColors.white,
          ),
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      itemCount: state.tracks.length +
          (state.isLoadingMore ? 1 : 0),
      separatorBuilder: (_, __) {
        return const SizedBox(height: 12);
      },
      itemBuilder: (context, index) {
        if (index >= state.tracks.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            ),
          );
        }

        final track = state.tracks[index];

        return _TrackCard(
          track: track,
          playlist: state.tracks,
        );
      },
    );
  }
}

class _TrackCard extends ConsumerWidget {
  final Track track;
  final List<Track> playlist;

  const _TrackCard({
    required this.track,
    required this.playlist,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              track.image,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return Container(
                  width: 64,
                  height: 64,
                  color: AppColors.background,
                  child: const Icon(
                    Icons.music_note,
                    color: AppColors.primary,
                  ),
                );
              },
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  track.artistName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            onPressed: () {
              ref
                  .read(audioPlayerProvider.notifier)
                  .playTrack(
                    track,
                    playlist: playlist,
                  );
            },
            icon: const Icon(
              Icons.play_arrow_rounded,
              color: AppColors.primary,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }
}
