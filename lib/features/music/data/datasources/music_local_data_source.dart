import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/track_model.dart';

class MusicLocalDataSource {
  static const String _boxName = 'music_cache';
  static const String _audioBoxName = 'music_audio_cache';
  static const String _tracksKey = 'tracks';

  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<String>(_boxName);
    }

    if (!Hive.isBoxOpen(_audioBoxName)) {
      await Hive.openBox<Uint8List>(_audioBoxName);
    }
  }

  Box<String> get _box => Hive.box<String>(_boxName);
  Box<Uint8List> get _audioBox => Hive.box<Uint8List>(_audioBoxName);

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

  Uint8List? getCachedAudio(String audioUrl) {
    return _audioBox.get(audioUrl);
  }

  Future<Uint8List?> cacheAudio(String audioUrl) async {
    try {
      final response = await Dio().get<List<int>>(
        audioUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      final data = response.data;
      if (data == null || data.isEmpty) {
        return null;
      }

      final audio = Uint8List.fromList(data);
      await _audioBox.put(audioUrl, audio);
      return audio;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearCache() async {
    await _box.delete(_tracksKey);
  }
}
