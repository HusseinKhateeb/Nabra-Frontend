import 'dart:io';

import 'package:dio/dio.dart';

import '../../../core/config/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../domain/avsr_models.dart';

class LipReadingApi {
  LipReadingApi(this._client);

  final DioClient _client;

  Future<AvsrFusionResponse> fuseFiles({
    File? audioFile,
    required File videoFile,
    int topK = 5,
  }) async {
    final Map<String, dynamic> data = {
      'videoFile': await MultipartFile.fromFile(
        videoFile.path,
        filename: videoFile.uri.pathSegments.last,
      ),
      'topK': topK,
    };
    if (audioFile != null) {
      data['audioFile'] = await MultipartFile.fromFile(
        audioFile.path,
        filename: audioFile.uri.pathSegments.last,
      );
    }
    final FormData formData = FormData.fromMap(data);

    final Response<dynamic> res = await _client.dio.post(
      ApiEndpoints.lipReadingAvsrFuseFiles,
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
      ),
    );

    return AvsrFusionResponse.fromJson(res.data as Map<String, dynamic>);
  }
}
