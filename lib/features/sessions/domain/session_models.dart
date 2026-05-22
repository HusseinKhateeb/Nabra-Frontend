enum SessionStatus { active, completed, failed }

enum SessionOutputType { text, voice }

enum SessionInputType { live, recorded }

class PageQueryParams {
  const PageQueryParams({
    this.page = 0,
    this.size = 10,
    this.sort = 'startedAt,desc',
  });

  final int page;
  final int size;
  final String sort;
}

SessionStatus? sessionStatusFromApi(String? value) {
  switch ((value ?? '').toUpperCase()) {
    case 'ACTIVE':
      return SessionStatus.active;
    case 'COMPLETED':
      return SessionStatus.completed;
    case 'FAILED':
      return SessionStatus.failed;
    default:
      return null;
  }
}

SessionOutputType? sessionOutputTypeFromApi(String? value) {
  switch ((value ?? '').toUpperCase()) {
    case 'TEXT':
      return SessionOutputType.text;
    case 'VOICE':
      return SessionOutputType.voice;
    default:
      return null;
  }
}

SessionInputType? sessionInputTypeFromApi(String? value) {
  switch ((value ?? '').toUpperCase()) {
    case 'LIVE':
      return SessionInputType.live;
    case 'RECORDED':
      return SessionInputType.recorded;
    default:
      return null;
  }
}

String sessionStatusToApi(SessionStatus value) {
  switch (value) {
    case SessionStatus.active:
      return 'ACTIVE';
    case SessionStatus.completed:
      return 'COMPLETED';
    case SessionStatus.failed:
      return 'FAILED';
  }
}

String sessionOutputTypeToApi(SessionOutputType value) {
  switch (value) {
    case SessionOutputType.text:
      return 'TEXT';
    case SessionOutputType.voice:
      return 'VOICE';
  }
}

String sessionInputTypeToApi(SessionInputType value) {
  switch (value) {
    case SessionInputType.live:
      return 'LIVE';
    case SessionInputType.recorded:
      return 'RECORDED';
  }
}

class SessionResponse {
  const SessionResponse({
    required this.id,
    required this.userId,
    required this.inputType,
    required this.outputType,
    required this.status,
    required this.startedAt,
    this.endedAt,
    this.durationSeconds,
    this.resultText,
    this.resultAudioUrl,
    this.accuracyScore,
    this.deviceInfo,
    this.modelVersion,
    this.isOffline,
    this.content,
  });

  final String id;
  final String userId;
  final SessionInputType? inputType;
  final SessionOutputType? outputType;
  final SessionStatus? status;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int? durationSeconds;
  final String? resultText;
  final String? resultAudioUrl;
  final double? accuracyScore;
  final String? deviceInfo;
  final String? modelVersion;
  final bool? isOffline;
  final SessionContent? content;

  factory SessionResponse.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      final String asText = value.toString().trim();
      if (asText.isEmpty) return null;
      return DateTime.tryParse(asText);
    }

    return SessionResponse(
      id: (json['id'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      inputType: sessionInputTypeFromApi(json['inputType']?.toString()),
      outputType: sessionOutputTypeFromApi(json['outputType']?.toString()),
      status: sessionStatusFromApi(json['status']?.toString()),
      startedAt: parseDate(json['startedAt']),
      endedAt: parseDate(json['endedAt']),
      durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
      resultText: json['resultText']?.toString(),
      resultAudioUrl: json['resultAudioUrl']?.toString(),
      accuracyScore: (json['accuracyScore'] as num?)?.toDouble(),
      deviceInfo: json['deviceInfo']?.toString(),
      modelVersion: json['modelVersion']?.toString(),
      isOffline: json['isOffline'] as bool?,
      content: SessionContent.fromDynamic(json['content']),
    );
  }
}

class SessionContent {
  const SessionContent({
    this.source,
    this.status,
    this.result,
    this.error,
    this.legacyText,
  });

  final String? source;
  final String? status;
  final AvsrSessionResult? result;
  final String? error;
  final String? legacyText;

  factory SessionContent.fromDynamic(dynamic raw) {
    if (raw is! Map<String, dynamic>) {
      return const SessionContent();
    }

    return SessionContent(
      source: raw['source']?.toString(),
      status: raw['status']?.toString(),
      result: raw['result'] is Map<String, dynamic>
          ? AvsrSessionResult.fromJson(raw['result'] as Map<String, dynamic>)
          : null,
      error: raw['error']?.toString(),
      legacyText: raw['text']?.toString(),
    );
  }
}

class AvsrSessionResult {
  const AvsrSessionResult({
    this.audioText,
    this.lipWord,
    this.lipConf,
    this.fusedWord,
    this.fusedConf,
    this.fusionReason,
  });

  final String? audioText;
  final String? lipWord;
  final double? lipConf;
  final String? fusedWord;
  final double? fusedConf;
  final String? fusionReason;

  factory AvsrSessionResult.fromJson(Map<String, dynamic> json) {
    return AvsrSessionResult(
      audioText: json['audio_text']?.toString(),
      lipWord: json['lip_word']?.toString(),
      lipConf: (json['lip_conf'] as num?)?.toDouble(),
      fusedWord: json['fused_word']?.toString(),
      fusedConf: (json['fused_conf'] as num?)?.toDouble(),
      fusionReason: json['fusion_reason']?.toString(),
    );
  }
}

class SessionFilters {
  const SessionFilters({
    this.from,
    this.to,
    this.minDuration,
    this.maxDuration,
    this.sort = 'startedAt,desc',
  });

  final DateTime? from;
  final DateTime? to;
  final int? minDuration;
  final int? maxDuration;
  final String sort;

  SessionFilters copyWith({
    DateTime? from,
    DateTime? to,
    int? minDuration,
    int? maxDuration,
    String? sort,
    bool clearFrom = false,
    bool clearTo = false,
    bool clearMinDuration = false,
    bool clearMaxDuration = false,
  }) {
    return SessionFilters(
      from: clearFrom ? null : (from ?? this.from),
      to: clearTo ? null : (to ?? this.to),
      minDuration: clearMinDuration ? null : (minDuration ?? this.minDuration),
      maxDuration: clearMaxDuration ? null : (maxDuration ?? this.maxDuration),
      sort: sort ?? this.sort,
    );
  }

  static const SessionFilters initial = SessionFilters();
}

class PageResponse<T> {
  const PageResponse({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.size,
    required this.number,
    required this.first,
    required this.last,
    required this.numberOfElements,
    required this.empty,
  });

  final List<T> content;
  final int totalElements;
  final int totalPages;
  final int size;
  final int number;
  final bool first;
  final bool last;
  final int numberOfElements;
  final bool empty;

  factory PageResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> item) mapper,
  ) {
    final List<dynamic> rawContent = (json['content'] as List?) ?? const <dynamic>[];
    return PageResponse<T>(
      content: rawContent
          .whereType<Map<String, dynamic>>()
          .map<T>(mapper)
          .toList(growable: false),
      totalElements: (json['totalElements'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
      size: (json['size'] as num?)?.toInt() ?? rawContent.length,
      number: (json['number'] as num?)?.toInt() ?? 0,
      first: (json['first'] as bool?) ?? true,
      last: (json['last'] as bool?) ?? true,
      numberOfElements: (json['numberOfElements'] as num?)?.toInt() ?? rawContent.length,
      empty: (json['empty'] as bool?) ?? rawContent.isEmpty,
    );
  }
}
