import 'package:tuneflow/features/music/data/datasources/music_source.dart';

import '../../domain/entities/track.dart';
import '../../domain/repositories/music_repository.dart';

class MusicRepositoryImpl implements MusicRepository {
  final MusicRemoteDataSource remoteDataSource;

  MusicRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<List<Track>> getTracks({
    int offset = 0,
  }) async {
    final tracks = await remoteDataSource.getTracks(
      offset: offset,
    );

    return tracks.map<Track>((track) => track).toList();
  }

  @override
  Future<List<Track>> searchTracks({
    required String query,
    int offset = 0,
  }) async {
    final tracks = await remoteDataSource.searchTracks(
      query: query,
      offset: offset,
    );

    return tracks.map<Track>((track) => track).toList();
  }
}