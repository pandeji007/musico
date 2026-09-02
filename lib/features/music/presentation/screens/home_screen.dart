import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuneflow/features/music/domain/entities/track.dart';
import 'package:tuneflow/features/music/presentation/providers/audio_player_provider.dart';
import 'package:tuneflow/features/music/presentation/screens/playing_screen.dart';
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
  final TextEditingController _searchController = TextEditingController();

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
    _searchController.dispose();

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
              const SizedBox(height: 20),
              _buildHeader(),
              const SizedBox(height: 22),
              _buildSearchField(),
              const SizedBox(height: 20),
              Expanded(child: _buildMusicList(state)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const MiniPlayer(),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.graphic_eq_rounded,
            color: AppColors.primary,
            size: 40,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset('assets/nameicon.png', width: 120, height: 60),
            Text(
              'Find your next favorite track',
              style: TextStyle(
                color: AppColors.white.withOpacity(0.55),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white.withOpacity(0.08)),
      ),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: _searchController,
        builder: (context, value, _) {
          return TextField(
            controller: _searchController,
            onChanged: (value) {
              ref.read(musicProvider.notifier).search(value);
            },
            style: const TextStyle(color: AppColors.white, fontSize: 15),
            decoration: InputDecoration(
              fillColor: Colors.transparent,
              hintText: 'Search music...',
              hintStyle: TextStyle(color: AppColors.white.withOpacity(0.5)),
              prefixIcon: const Icon(Icons.search, color: AppColors.primary),
              suffixIcon: value.text.isEmpty
                  ? null
                  : IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: AppColors.white.withOpacity(0.6),
                        size: 20,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(musicProvider.notifier).search('');
                      },
                    ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMusicList(MusicState state) {
    if (state.isLoading && state.tracks.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.errorMessage != null && state.tracks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              color: AppColors.white.withOpacity(0.4),
              size: 40,
            ),
            const SizedBox(height: 12),
            const Text(
              'Something went wrong',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Check your connection and try again',
              style: TextStyle(
                color: AppColors.white.withOpacity(0.5),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                ref.read(musicProvider.notifier).loadTracks();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.tracks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.music_off_rounded,
              color: AppColors.white.withOpacity(0.4),
              size: 40,
            ),
            const SizedBox(height: 12),
            const Text(
              'No music found',
              style: TextStyle(color: AppColors.white, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      itemCount: state.tracks.length + (state.isLoadingMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index >= state.tracks.length) {
          return const Padding(
            padding: EdgeInsets.all(5),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        final track = state.tracks[index];

        return _TrackCard(track: track, playlist: state.tracks);
      },
    );
  }
}

class _TrackCard extends ConsumerWidget {
  final Track track;
  final List<Track> playlist;

  const _TrackCard({required this.track, required this.playlist});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.transparent,
      // borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          ref
              .read(audioPlayerProvider.notifier)
              .playTrack(track, playlist: playlist);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NowPlayingScreen()),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 3),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  track.image,
                  width: 80,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return Container(
                      width: 80,
                      height: 70,
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
                        color: AppColors.white.withOpacity(0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    ref
                        .read(audioPlayerProvider.notifier)
                        .playTrack(track, playlist: playlist);
                  },
                  icon: const Icon(
                    Icons.play_arrow_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
