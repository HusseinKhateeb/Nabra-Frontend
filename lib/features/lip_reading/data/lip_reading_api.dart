import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/config/api_endpoints.dart';
import '../../../core/network/token_storage.dart';
import '../../../core/router/app_router.dart';
import '../../../core/router/app_routes.dart';
import '../domain/avsr_models.dart';

class LipReadingUploadResult {
  const LipReadingUploadResult({
    required this.success,
    required this.message,
    this.jobId,
    this.statusEndpoint,
    this.statusCode,
    this.responseBody,
    this.responseJson,
  });

  final bool success;
  final String message;
  final String? jobId;
  final String? statusEndpoint;
  final int? statusCode;
  final String? responseBody;
  final Map<String, dynamic>? responseJson;
}

class LipReadingApi {
  LipReadingApi(this._tokenStorage);

  final TokenStorage _tokenStorage;

  Future<AvsrFusionResponse> fuseFiles({
    required File audioFile,
    required File videoFile,
    int frameCount = 25,
    bool fast = false,
    void Function(String phase)? onPhase,
  }) async {
    final LipReadingUploadResult result = await uploadFuseFilesMultipart(
      audioFile: audioFile,
      videoFile: videoFile,
      onPhase: onPhase,
    );

    if (!result.success) {
      throw Exception(result.message);
    }

    if (result.responseJson != null) {
      return _parseFusionResponse(result.responseJson!);
    }

    return _parseFusionResponse(result.responseBody ?? '');
  }

  Future<void> _validateFileForUpload(File file, String label) async {
    final bool exists = await file.exists();
    if (!exists) {
      throw Exception('$label file does not exist: ${file.path}');
    }
    final int size = await file.length();
    debugPrint('[LipReading][Upload] $label path=${file.path}, size=$size bytes');
    if (size <= 0) {
      throw Exception('$label file is empty: ${file.path}');
    }
  }

  Future<LipReadingUploadResult> uploadFuseFilesMultipart({
    required File audioFile,
    required File videoFile,
    void Function(String phase)? onPhase,
  }) async {
    try {
      onPhase?.call('uploading');
      await _validateFileForUpload(audioFile, 'audioFile');
      await _validateFileForUpload(videoFile, 'videoFile');

      final String token = (await _tokenStorage.readAccessToken() ?? '').trim();
      if (token.isEmpty) {
        appRouter.go(AppRoutes.login);
        return const LipReadingUploadResult(
          success: false,
          message: 'Session expired. Please login again.',
        );
      }

      final Uri uri = Uri.parse(
        '${AppConfig.apiBaseUrl}${ApiEndpoints.lipReadingAvsrFuseFiles}',
      );

      final http.MultipartRequest request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        // Do not set Content-Type manually; MultipartRequest sets boundary.
        ..fields['wait'] = 'false'
        ..fields['timeoutSeconds'] = '300'
        ..fields['fast'] = 'false';

      request.files.add(
        await http.MultipartFile.fromPath('audioFile', audioFile.path),
      );
      request.files.add(
        await http.MultipartFile.fromPath('videoFile', videoFile.path),
      );

      final http.StreamedResponse streamed = await request
          .send()
          .timeout(const Duration(minutes: 6));

      final String body = await streamed.stream.bytesToString();
      debugPrint('[LipReading][Upload] url=$uri, status=${streamed.statusCode}, body=$body');

      final Map<String, dynamic>? decodedJson =
          _tryDecodeJsonObjectFromText(body);

      if (streamed.statusCode == 202) {
        final String? jobIdRaw = decodedJson == null
          ? null
          : decodedJson['jobId']?.toString().trim();
        final String? statusEndpointRaw = decodedJson == null
          ? null
          : decodedJson['statusEndpoint']?.toString().trim();

        final String? jobId =
          (jobIdRaw != null && jobIdRaw.isNotEmpty) ? jobIdRaw : null;
        final String? statusEndpoint =
          (statusEndpointRaw != null && statusEndpointRaw.isNotEmpty)
            ? statusEndpointRaw
            : null;

        if (jobId == null) {
          onPhase?.call('failed');
          return LipReadingUploadResult(
            success: false,
            message: 'Async job started but no jobId returned.',
            statusCode: streamed.statusCode,
            responseBody: body,
            responseJson: decodedJson,
          );
        }

        onPhase?.call('processing');
        return _pollFuseFilesJob(
          token: token,
          jobId: jobId,
          statusEndpoint: statusEndpoint,
          onPhase: onPhase,
        );
      }

      if (streamed.statusCode >= 200 && streamed.statusCode < 300) {
        onPhase?.call('completed');
        return LipReadingUploadResult(
          success: true,
          message: 'Upload completed.',
          jobId: decodedJson?['jobId']?.toString(),
          statusEndpoint: decodedJson?['statusEndpoint']?.toString(),
          statusCode: streamed.statusCode,
          responseBody: body,
          responseJson: decodedJson,
        );
      }

      onPhase?.call('failed');

      return LipReadingUploadResult(
        success: false,
        message:
            'Server error (${streamed.statusCode}): ${_extractErrorMessage(decodedJson ?? body)}',
        jobId: decodedJson?['jobId']?.toString(),
        statusEndpoint: decodedJson?['statusEndpoint']?.toString(),
        statusCode: streamed.statusCode,
        responseBody: body,
        responseJson: decodedJson,
      );
    } on SocketException {
      onPhase?.call('failed');
      return const LipReadingUploadResult(
        success: false,
        message: 'Cannot connect to server. Check network and backend status.',
      );
    } on TimeoutException {
      onPhase?.call('failed');
      return const LipReadingUploadResult(
        success: false,
        message: 'Upload timed out. Please try again with shorter recording.',
      );
    } on IOException {
      onPhase?.call('failed');
      return const LipReadingUploadResult(
        success: false,
        message: 'Upload stream ended unexpectedly. Please retry.',
      );
    } catch (e) {
      onPhase?.call('failed');
      return LipReadingUploadResult(
        success: false,
        message: 'Upload failed: $e',
      );
    }
  }

  Future<LipReadingUploadResult> _pollFuseFilesJob({
    required String token,
    required String jobId,
    required String? statusEndpoint,
    void Function(String phase)? onPhase,
  }) async {
    final Uri uri = statusEndpoint != null && statusEndpoint.isNotEmpty
        ? (statusEndpoint.startsWith('http')
            ? Uri.parse(statusEndpoint)
            : Uri.parse('${AppConfig.apiBaseUrl}$statusEndpoint'))
        : Uri.parse(
            '${AppConfig.apiBaseUrl}${ApiEndpoints.lipReadingAvsrFuseFilesStatus(jobId)}',
          );

    const Duration pollInterval = Duration(seconds: 2);
    const int maxAttempts = 180;

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final http.Request req = http.Request('GET', uri)
          ..headers['Authorization'] = 'Bearer $token';

        final http.StreamedResponse streamed =
            await req.send().timeout(const Duration(seconds: 30));
        final String body = await streamed.stream.bytesToString();
        debugPrint(
          '[LipReading][Poll] attempt=$attempt status=${streamed.statusCode}, body=$body',
        );

        final Map<String, dynamic>? json = _tryDecodeJsonObjectFromText(body);

        if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
          onPhase?.call('failed');
          return LipReadingUploadResult(
            success: false,
            message:
                'Polling failed (${streamed.statusCode}): ${_extractErrorMessage(json ?? body)}',
            jobId: jobId,
            statusEndpoint: uri.toString(),
            statusCode: streamed.statusCode,
            responseBody: body,
            responseJson: json,
          );
        }

        final String status =
            ((json?['status'] ?? json?['jobStatus'] ?? json?['state'])
                        ?.toString() ??
                    '')
                .trim()
                .toUpperCase();

        if (status == 'COMPLETED' || status == 'SUCCESS' || status == 'DONE') {
          onPhase?.call('completed');
          final Map<String, dynamic>? resultJson = _extractResultObject(json);
          return LipReadingUploadResult(
            success: true,
            message: 'Processing completed.',
            jobId: jobId,
            statusEndpoint: uri.toString(),
            statusCode: streamed.statusCode,
            responseBody: body,
            responseJson: resultJson ?? json,
          );
        }

        if (status == 'FAILED' || status == 'ERROR' || status == 'CANCELLED') {
          onPhase?.call('failed');
          return LipReadingUploadResult(
            success: false,
            message: 'Processing failed: ${_extractErrorMessage(json ?? body)}',
            jobId: jobId,
            statusEndpoint: uri.toString(),
            statusCode: streamed.statusCode,
            responseBody: body,
            responseJson: json,
          );
        }
      } on SocketException {
        if (attempt == maxAttempts) {
          onPhase?.call('failed');
          return const LipReadingUploadResult(
            success: false,
            message: 'Connection lost while checking processing status.',
          );
        }
      } on TimeoutException {
        if (attempt == maxAttempts) {
          onPhase?.call('failed');
          return const LipReadingUploadResult(
            success: false,
            message: 'Timed out while waiting for processing result.',
          );
        }
      } on IOException {
        if (attempt == maxAttempts) {
          onPhase?.call('failed');
          return const LipReadingUploadResult(
            success: false,
            message: 'Unexpected stream end while polling result.',
          );
        }
      }

      await Future<void>.delayed(pollInterval);
    }

    onPhase?.call('failed');
    return const LipReadingUploadResult(
      success: false,
      message: 'Processing did not complete in time. Please try again.',
    );
  }

  Map<String, dynamic>? _extractResultObject(Map<String, dynamic>? root) {
    if (root == null) return null;
    final dynamic result = root['result'] ?? root['data'] ?? root['payload'];
    if (result is Map<String, dynamic>) {
      return result;
    }
    return root;
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
