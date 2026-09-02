import 'package:tuneflow/features/music/data/datasources/music_source.dart';
import 'package:tuneflow/features/music/data/datasources/music_local_data_source.dart';
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

      if (offset == 0 && tracks.isNotEmpty) {
        try {
          await localDataSource.cacheTracks(tracks);
        } catch (e) {
          // Handle caching error, but don't fail the entire operation
        }
      }

      return tracks.map<Track>((track) => track).toList();
    } catch (_) {
      if (offset == 0) {
        return localDataSource.getCachedTracks();
      }

      rethrow;
    }
  }

  @override
  Future<List<Track>> searchTracks({
    required String query,
    int offset = 0,
  }) async {
    await localDataSource.init();

    try {
      final tracks = await remoteDataSource.searchTracks(
        query: query,
        offset: offset,
      );

      return tracks.map<Track>((track) => track).toList();
    } catch (_) {
      if (offset != 0) {
        rethrow;
      }

      final normalizedQuery = query.toLowerCase();
      return localDataSource.getCachedTracks().where((track) {
        return track.name.toLowerCase().contains(normalizedQuery) ||
            track.artistName.toLowerCase().contains(normalizedQuery) ||
            track.albumName.toLowerCase().contains(normalizedQuery);
      }).toList();
    }
  }
}
