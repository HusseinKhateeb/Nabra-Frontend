class SessionHistory {
  final String id;
  final String sessionId;
  final String userId;
  final DateTime startTime;
  final DateTime? endTime;
  final int duration; // in seconds
  final String status; // e.g., 'ACTIVE', 'COMPLETED', 'PAUSED'
  final String? notes;
  final String? activityType;
  final Map<String, dynamic>? metadata; // For additional data from backend

  SessionHistory({
    required this.id,
    required this.sessionId,
    required this.userId,
    required this.startTime,
    this.endTime,
    required this.duration,
    required this.status,
    this.notes,
    this.activityType,
    this.metadata,
  });

  factory SessionHistory.fromJson(Map<String, dynamic> json) {
    return SessionHistory(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String,
      userId: json['userId'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      duration: json['duration'] as int,
      status: json['status'] as String,
      notes: json['notes'] as String?,
      activityType: json['activityType'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionId': sessionId,
      'userId': userId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'duration': duration,
      'status': status,
      'notes': notes,
      'activityType': activityType,
      'metadata': metadata,
    };
  }

  SessionHistory copyWith({
    String? id,
    String? sessionId,
    String? userId,
    DateTime? startTime,
    DateTime? endTime,
    int? duration,
    String? status,
    String? notes,
    String? activityType,
    Map<String, dynamic>? metadata,
  }) {
    return SessionHistory(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      activityType: activityType ?? this.activityType,
      metadata: metadata ?? this.metadata,
    );
  }
}
