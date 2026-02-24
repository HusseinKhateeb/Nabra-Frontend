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

  factory AvsrFusionResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> predictionsRaw =
        (json['lipTopPredictions'] as List<dynamic>?) ?? <dynamic>[];

    final dynamic similarityRaw = json['similarity'];
    final dynamic lipConfidenceRaw = json['lipConfidence'];

    return AvsrFusionResponse(
      finalWord: (json['finalWord'] as String?)?.trim() ?? '',
      matchedLipWord: (json['matchedLipWord'] as String?)?.trim() ?? '',
      audioText: (json['audioText'] as String?)?.trim() ?? '',
      similarity: similarityRaw is num ? similarityRaw.toDouble() : 0,
      lipConfidence: lipConfidenceRaw is num ? lipConfidenceRaw.toDouble() : 0,
      lipTopPredictions: predictionsRaw
          .whereType<Map<String, dynamic>>()
          .map(AvsrTopPrediction.fromJson)
          .toList(),
      fusionReason: (json['fusionReason'] as String?)?.trim() ?? '',
    );
  }
}
