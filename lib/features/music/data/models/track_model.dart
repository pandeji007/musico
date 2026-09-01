import '../../domain/entities/track.dart';

class TrackModel extends Track {
  const TrackModel({
    required super.id,
    required super.name,
    required super.duration,
    required super.artistName,
    required super.albumName,
    required super.albumImage,
    required super.image,
    required super.audio,
  });

  factory TrackModel.fromJson(Map<String, dynamic> json) {
    return TrackModel(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      duration: _parseInt(json['duration']),
      artistName: json['artist_name']?.toString() ?? '',
      albumName: json['album_name']?.toString() ?? '',
      albumImage: json['album_image']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      audio: json['audio']?.toString() ?? '',
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ?? 0;
    }

    return 0;
  }
}