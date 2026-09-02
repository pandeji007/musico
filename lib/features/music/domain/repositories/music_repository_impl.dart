import 'package:tuneflow/features/music/data/datasources/music_local_data_source.dart';
import 'package:tuneflow/features/music/data/datasources/music_source.dart';
import '../../domain/entities/track.dart';
import '../../domain/repositories/music_repository.dart';

class MusicRepositoryImpl implements MusicRepository {
  final MusicRemoteDataSource remoteDataSource;
  final MusicLocalDataSource localDataSource;

  MusicRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<List<Track>> getTracks({int offset = 0}) async {
    await localDataSource.init();

    try {
      final tracks = await remoteDataSource.getTracks(offset: offset);

      if (tracks.isNotEmpty) {
        if (offset == 0) {
          await localDataSource.cacheTracks(tracks);
        } else {
          final cachedTracks = localDataSource.getCachedTracks();

          await localDataSource.cacheTracks([...cachedTracks, ...tracks]);
        }
      }

      return tracks;
    } catch (e) {
      // Use cached tracks when the API is unavailable.
      final cachedTracks = localDataSource.getCachedTracks();

      if (offset < cachedTracks.length) {
        return cachedTracks.skip(offset).take(20).toList();
      }

      rethrow;
    }
  }

  @override
  Future<List<Track>> searchTracks({
    required String query,
    int offset = 0,
  }) async {
    return remoteDataSource.searchTracks(query: query, offset: offset);
  }
}
