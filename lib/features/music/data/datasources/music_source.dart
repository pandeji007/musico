import 'package:tuneflow/core/constants/app_config.dart';
import '../../../../core/network/dio_client.dart';
import '../models/track_model.dart';

class MusicRemoteDataSource {
  final DioClient dioClient;

  MusicRemoteDataSource({required this.dioClient});

  Future<List<TrackModel>> getTracks({int offset = 0}) async {
    try {
      final response = await dioClient.dio.get(
        ApiConstants.tracksEndpoint,
        queryParameters: {
          'client_id': ApiConstants.clientId,
          'format': 'json',
          'limit': ApiConstants.pageSize,
          'offset': offset,
        },
      );


      final results = response.data['results'];

      if (results is! List) {
        throw Exception('Invalid API response');
      }

      return results
          .map((json) => TrackModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch tracks: $e');
    }
  }

  Future<List<TrackModel>> searchTracks({
    required String query,
    int offset = 0,
  }) async {
    try {
      final response = await dioClient.dio.get(
        ApiConstants.tracksEndpoint,
        queryParameters: {
          'client_id': ApiConstants.clientId,
          'format': 'json',
          'namesearch': query,
          'limit': ApiConstants.pageSize,
          'offset': offset,
        },
      );


      final results = response.data['results'];

      if (results is! List) {
        throw Exception('Invalid API response');
      }

      return results
          .map((json) => TrackModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to search tracks: $e');
    }
  }
}
