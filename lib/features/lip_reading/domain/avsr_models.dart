class AvsrTopPrediction {
  const AvsrTopPrediction({
    required this.word,
    required this.confidence,
  });

  final String word;
  final double confidence;

  factory AvsrTopPrediction.fromJson(Map<String, dynamic> json) {
    final dynamic confidenceRaw = json['confidence'];
    return AvsrTopPrediction(
      word: (json['word'] as String?)?.trim() ?? '',
      confidence: confidenceRaw is num ? confidenceRaw.toDouble() : 0,
    );
  }

  static AvsrTopPrediction? fromDynamic(dynamic value) {
    if (value is Map<String, dynamic>) {
      return AvsrTopPrediction.fromJson(value);
    }

    if (value is List && value.length >= 2) {
      final dynamic wordRaw = value[0];
      final dynamic confRaw = value[1];
      final String word = wordRaw?.toString().trim() ?? '';
      final double confidence = confRaw is num ? confRaw.toDouble() : 0;
      return AvsrTopPrediction(word: word, confidence: confidence);
    }

    return null;
  }
}

class AvsrFusionResponse {
  const AvsrFusionResponse({
    required this.finalWord,
    required this.matchedLipWord,
    required this.audioText,
    required this.similarity,
    required this.lipConfidence,
    required this.lipTopPredictions,
    required this.fusionReason,
  });

  final String finalWord;
  final String matchedLipWord;
  final String audioText;
  final double similarity;
  final double lipConfidence;
  final List<AvsrTopPrediction> lipTopPredictions;
  final String fusionReason;

  factory AvsrFusionResponse.fromRawOutput(String output) {
    final String normalized = output.trim();
    return AvsrFusionResponse(
      finalWord: normalized,
      matchedLipWord: '',
      audioText: '',
      similarity: 0,
      lipConfidence: 0,
      lipTopPredictions: const <AvsrTopPrediction>[],
      fusionReason: 'Backend returned plain text output.',
    );
  }

  factory AvsrFusionResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> predictionsRaw =
      (json['lipTopPredictions'] as List<dynamic>?) ??
      (json['lip_top'] as List<dynamic>?) ??
      <dynamic>[];

    final dynamic similarityRaw = json['similarity'];
    final dynamic fusedConfidenceRaw = json['fused_conf'];
    final dynamic lipConfidenceRaw = json['lipConfidence'] ?? json['lip_conf'];

    final String finalWord =
      ((json['finalWord'] ?? json['fused_word']) as String?)?.trim() ?? '';
    final String matchedLipWord =
      ((json['matchedLipWord'] ?? json['lip_word']) as String?)?.trim() ?? '';
    final String audioText =
      ((json['audioText'] ?? json['audio_text']) as String?)?.trim() ?? '';

    final double finalConfidence = fusedConfidenceRaw is num
      ? fusedConfidenceRaw.toDouble()
      : (lipConfidenceRaw is num ? lipConfidenceRaw.toDouble() : 0);

    final List<AvsrTopPrediction> topPredictions = predictionsRaw
      .map(AvsrTopPrediction.fromDynamic)
      .whereType<AvsrTopPrediction>()
      .toList();

    return AvsrFusionResponse(
      finalWord: finalWord,
      matchedLipWord: matchedLipWord,
      audioText: audioText,
      similarity: similarityRaw is num ? similarityRaw.toDouble() : 0,
      lipConfidence: finalConfidence,
      lipTopPredictions: topPredictions,
      fusionReason: ((json['fusionReason'] ?? json['fusion_reason']) as String?)?.trim() ?? '',
    );
  }
}
