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
    final id = int.tryParse(json['id'].toString()) ?? 0;
    final duration = int.tryParse(json['duration'].toString()) ?? 0;

    return TrackModel(
      id: id,
      name: json['name']?.toString() ?? '',
      duration: duration,
      artistName: json['artist_name']?.toString() ?? '',
      albumName: json['album_name']?.toString() ?? '',
      albumImage: json['album_image']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      audio: json['audio']?.toString() ?? '',
    );
  }
}
