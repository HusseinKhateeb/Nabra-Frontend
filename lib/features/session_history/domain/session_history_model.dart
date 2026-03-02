class SessionHistory {
  final String id;
  final String userId;
  final String inputType;
  final String outputType;
  final String status;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int durationSeconds;
  final String? resultText;
  final String? resultAudioUrl;
  final double? accuracyScore;
  final String? deviceInfo;
  final String? modelVersion;
  final bool? isOffline;

  SessionHistory({
    required this.id,
    required this.userId,
    required this.inputType,
    required this.outputType,
    required this.status,
    required this.startedAt,
    this.endedAt,
    required this.durationSeconds,
    this.resultText,
    this.resultAudioUrl,
    this.accuracyScore,
    this.deviceInfo,
    this.modelVersion,
    this.isOffline,
  });

  factory SessionHistory.fromJson(Map<String, dynamic> json) {
    return SessionHistory(
      id: (json['id'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      inputType: (json['inputType'] ?? '').toString(),
      outputType: (json['outputType'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: json['endedAt'] != null
          ? DateTime.parse(json['endedAt'] as String)
          : null,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      resultText: json['resultText'] as String?,
      resultAudioUrl: json['resultAudioUrl'] as String?,
      accuracyScore: (json['accuracyScore'] as num?)?.toDouble(),
      deviceInfo: json['deviceInfo'] as String?,
      modelVersion: json['modelVersion'] as String?,
      isOffline: json['isOffline'] as bool?,
    );
  }

  Map<String, dynamic> toStartRequestJson() {
    return {
      'inputType': inputType,
      'outputType': outputType,
      if (deviceInfo != null) 'deviceInfo': deviceInfo,
      if (modelVersion != null) 'modelVersion': modelVersion,
      if (isOffline != null) 'isOffline': isOffline,
    };
  }

  Map<String, dynamic> toStopRequestJson() {
    return {
      if (resultText != null) 'resultText': resultText,
      if (resultAudioUrl != null) 'resultAudioUrl': resultAudioUrl,
      if (accuracyScore != null) 'accuracyScore': accuracyScore,
    };
  }

  SessionHistory copyWith({
    String? id,
    String? userId,
    String? inputType,
    String? outputType,
    String? status,
    DateTime? startedAt,
    DateTime? endedAt,
    int? durationSeconds,
    String? resultText,
    String? resultAudioUrl,
    double? accuracyScore,
    String? deviceInfo,
    String? modelVersion,
    bool? isOffline,
  }) {
    return SessionHistory(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      inputType: inputType ?? this.inputType,
      outputType: outputType ?? this.outputType,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      resultText: resultText ?? this.resultText,
      resultAudioUrl: resultAudioUrl ?? this.resultAudioUrl,
      accuracyScore: accuracyScore ?? this.accuracyScore,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      modelVersion: modelVersion ?? this.modelVersion,
      isOffline: isOffline ?? this.isOffline,
    );
  }

  String get sessionId => id;
  DateTime get startTime => startedAt;
  DateTime? get endTime => endedAt;
  int get duration => durationSeconds;
  String? get notes => resultText;
  String? get activityType => inputType;
}
