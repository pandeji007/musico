import '../entities/track.dart';

abstract class MusicRepository {
  Future<List<Track>> getTracks({
    int offset = 0,
  });

  Future<List<Track>> searchTracks({
    required String query,
    int offset = 0,
  });
}