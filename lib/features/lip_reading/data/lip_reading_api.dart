import 'dart:convert';
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
  }) async {
    final Map<String, dynamic> data = {
      'audioFile': await MultipartFile.fromFile(
        audioFile.path,
        filename: audioFile.uri.pathSegments.last,
      ),
      'videoFile': await MultipartFile.fromFile(
        videoFile.path,
        filename: videoFile.uri.pathSegments.last,
      ),
    };
    final FormData formData = FormData.fromMap(data);

    try {
      final Response<dynamic> res = await _client.dio.post(
        ApiEndpoints.lipReadingAvsrFuseFiles,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          responseType: ResponseType.plain,
          sendTimeout: const Duration(minutes: 5),
          receiveTimeout: const Duration(minutes: 5),
        ),
      );

      return _parseFusionResponse(res.data);
    } on DioException catch (error) {
      final int? statusCode = error.response?.statusCode;
      final String backendMessage = _extractErrorMessage(error.response?.data);
      final String fallbackMessage = (error.message ?? '').trim();
      final String innerError = (error.error?.toString() ?? '').trim();
      final String requestMethod = error.requestOptions.method;
      final String requestUri = error.requestOptions.uri.toString();
      final String detail = backendMessage.isNotEmpty
          ? backendMessage
        : (fallbackMessage.isNotEmpty
          ? fallbackMessage
          : (innerError.isNotEmpty ? innerError : 'Request failed.'));

      final String message;
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          message = 'Request timed out. Please try again.';
          break;
        case DioExceptionType.connectionError:
          message = 'Cannot reach server. Check network and API base URL. [$requestMethod $requestUri] $detail';
          break;
        case DioExceptionType.badResponse:
          if (statusCode != null) {
            message = 'Server error ($statusCode): $detail';
          } else {
            message = 'Server returned an invalid response: $detail';
          }
          break;
        case DioExceptionType.cancel:
          message = 'Request was cancelled.';
          break;
        case DioExceptionType.badCertificate:
          message = 'Secure connection failed (certificate error). [$requestMethod $requestUri] $detail';
          break;
        case DioExceptionType.unknown:
          message = 'Request failed. [$requestMethod $requestUri] $detail';
          break;
      }
      throw Exception(message);
    }
  }

  String _extractErrorMessage(dynamic body) {
    if (body == null) return '';

    if (body is String) {
      final String trimmed = body.trim();
      if (trimmed.isEmpty) return '';
      try {
        final dynamic decoded = jsonDecode(trimmed);
        if (decoded is Map<String, dynamic>) {
          final String fromJson = _extractErrorMessageFromMap(decoded);
          if (fromJson.isNotEmpty) {
            return fromJson;
          }
        }
      } catch (_) {
        // Keep raw string
      }
      return trimmed;
    }

    if (body is Map<String, dynamic>) {
      return _extractErrorMessageFromMap(body);
    }

    return body.toString().trim();
  }

  String _extractErrorMessageFromMap(Map<String, dynamic> body) {
    final List<String> knownKeys = <String>['message', 'error', 'detail', 'title'];
    for (final key in knownKeys) {
      final dynamic value = body[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    final dynamic errors = body['errors'];
    if (errors is List) {
      final String merged = errors.map((e) => e.toString()).join(' | ').trim();
      if (merged.isNotEmpty) {
        return merged;
      }
    }

    return body.toString().trim();
  }

  AvsrFusionResponse _parseFusionResponse(dynamic body) {
    if (body is Map<String, dynamic>) {
      return AvsrFusionResponse.fromJson(body);
    }

    if (body is String) {
      final String trimmed = body.trim();
      try {
        final dynamic decoded = jsonDecode(trimmed);
        if (decoded is Map<String, dynamic>) {
          return AvsrFusionResponse.fromJson(decoded);
        }
      } catch (_) {
        // fall through to raw-output fallback model
      }

      return AvsrFusionResponse.fromRawOutput(trimmed);
    }

    return AvsrFusionResponse.fromRawOutput(body?.toString() ?? '');
  }
}
