import 'dart:io';

import 'package:dio/dio.dart';

import '../../../core/config/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../domain/avsr_models.dart';

class LipReadingApi {
  LipReadingApi(this._client);

  final DioClient _client;

  Future<AvsrFusionResponse> fuseFiles({
    required File audioFile,
    required File videoFile,
    int topK = 5,
  }) async {
    final FormData formData = FormData.fromMap({
      'audioFile': await MultipartFile.fromFile(
        audioFile.path,
        filename: audioFile.uri.pathSegments.last,
      ),
      'videoFile': await MultipartFile.fromFile(
        videoFile.path,
        filename: videoFile.uri.pathSegments.last,
      ),
      'topK': topK,
    });

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
