import '../domain/session_models.dart';

String formatSessionDateTime(DateTime? value) {
  if (value == null) return '-';
  final DateTime local = value.toLocal();
  final String y = local.year.toString();
  final String m = local.month.toString().padLeft(2, '0');
  final String d = local.day.toString().padLeft(2, '0');
  final String h = local.hour.toString().padLeft(2, '0');
  final String min = local.minute.toString().padLeft(2, '0');
  return '$y-$m-$d $h:$min';
}

String formatDurationSeconds(int? seconds) {
  if (seconds == null || seconds < 0) return '-';
  final int hours = seconds ~/ 3600;
  final int minutes = (seconds % 3600) ~/ 60;
  final int sec = seconds % 60;

  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }
  return '${minutes.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
}

String safeText(String? value) {
  final String trimmed = (value ?? '').trim();
  return trimmed.isEmpty ? '-' : trimmed;
}

String statusLabel(SessionStatus? status) {
  switch (status) {
    case SessionStatus.active:
      return 'نشطة';
    case SessionStatus.completed:
      return 'مكتملة';
    case SessionStatus.failed:
      return 'فاشلة';
    case null:
      return '-';
  }
}

String inputTypeLabel(SessionInputType? inputType) {
  if (inputType == null) return '-';
  return sessionInputTypeToApi(inputType);
}

String outputTypeLabel(SessionOutputType? outputType) {
  if (outputType == null) return '-';
  return sessionOutputTypeToApi(outputType);
}
