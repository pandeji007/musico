import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/track_model.dart';

class MusicLocalDataSource {
  static const String _boxName = 'music_cache';
  static const String _tracksKey = 'tracks';

  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<String>(_boxName);
    }
  }

  Box<String> get _box => Hive.box<String>(_boxName);

  Future<void> cacheTracks(List<TrackModel> tracks) async {
    final data = tracks
        .map(
          (track) => {
            'id': track.id,
            'name': track.name,
            'duration': track.duration,
            'artist_name': track.artistName,
            'album_name': track.albumName,
            'album_image': track.albumImage,
            'image': track.image,
            'audio': track.audio,
          },
        )
        .toList();

    await _box.put(_tracksKey, jsonEncode(data));
  }

  List<TrackModel> getCachedTracks() {
    final cachedData = _box.get(_tracksKey);

    if (cachedData == null || cachedData.isEmpty) {
      return [];
    }

    final List<dynamic> data = jsonDecode(cachedData);

    return data
        .map((item) => TrackModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> clearCache() async {
    await _box.delete(_tracksKey);
  }
}
