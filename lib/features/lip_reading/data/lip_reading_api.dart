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
    int frameCount = 25,
    bool fast = false,
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
      'wait': 'true',
      'timeoutSeconds': '240',
      'frameCount': frameCount.toString(),
      'fast': fast.toString(),
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
      final String friendlyDetail = _toUserFriendlyMessage(detail);

      final String message;
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          message = 'Request timed out. Please try again.';
          break;
        case DioExceptionType.connectionError:
          message = 'Cannot reach server. Check network and API base URL. [$requestMethod $requestUri] $friendlyDetail';
          break;
        case DioExceptionType.badResponse:
          if (statusCode != null) {
            message = 'Server error ($statusCode): $friendlyDetail';
          } else {
            message = 'Server returned an invalid response: $friendlyDetail';
          }
          break;
        case DioExceptionType.cancel:
          message = 'Request was cancelled.';
          break;
        case DioExceptionType.badCertificate:
          message = 'Secure connection failed (certificate error). [$requestMethod $requestUri] $friendlyDetail';
          break;
        case DioExceptionType.unknown:
          message = 'Request failed. [$requestMethod $requestUri] $friendlyDetail';
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
      final dynamic ok = body['ok'];
      if (ok is bool) {
        if (!ok) {
          final String error = (body['error'] as String?)?.trim() ?? 'AVSR worker failed.';
          throw Exception(_toUserFriendlyMessage(error));
        }

        final String rawOutput = (body['rawOutput'] as String?)?.trim() ?? '';
        final Map<String, dynamic>? decodedRaw = _tryDecodeJsonObjectFromText(rawOutput);
        if (decodedRaw != null) {
          return AvsrFusionResponse.fromJson(decodedRaw);
        }
        return AvsrFusionResponse.fromRawOutput(rawOutput);
      }

      return AvsrFusionResponse.fromJson(body);
    }

    if (body is String) {
      final String trimmed = body.trim();
      final Map<String, dynamic>? decoded = _tryDecodeJsonObjectFromText(trimmed);
      if (decoded != null) {
        return _parseFusionResponse(decoded);
      }

      final String friendly = _toUserFriendlyMessage(trimmed);
      if (friendly != trimmed) {
        throw Exception(friendly);
      }

      return AvsrFusionResponse.fromRawOutput(trimmed);
    }

    return AvsrFusionResponse.fromRawOutput(body?.toString() ?? '');
  }

  Map<String, dynamic>? _tryDecodeJsonObjectFromText(String text) {
    if (text.isEmpty) return null;

    try {
      final dynamic direct = jsonDecode(text);
      if (direct is Map<String, dynamic>) {
        return direct;
      }
    } catch (_) {
      // Try extracting JSON suffix from mixed logs + JSON content.
    }

    int start = text.indexOf('{');
    while (start != -1) {
      final String candidate = text.substring(start).trim();
      try {
        final dynamic decoded = jsonDecode(candidate);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      } catch (_) {
        // Move to next possible JSON object start.
      }
      start = text.indexOf('{', start + 1);
    }

    return null;
  }

  String _toUserFriendlyMessage(String message) {
    final String normalized = message.toLowerCase();
    if (normalized.contains('no face detected in video frames')) {
      return 'No face was detected. Please keep your full face visible, look at the camera directly, and record in good lighting.';
    }
    return message;
  }
}
