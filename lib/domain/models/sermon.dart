class Sermon {
  final String id;
  final String title;
  final String speaker;
  final String seriesName;
  final String durationFormatted;
  final int totalDurationSeconds;
  final int currentPositionSeconds;
  final String audioUrl;
  final String thumbnailUrl;
  final String date;
  final bool isFeatured;
  final bool isListening;
  final String summaryNotes;

  const Sermon({
    required this.id,
    required this.title,
    required this.speaker,
    required this.seriesName,
    required this.durationFormatted,
    required this.totalDurationSeconds,
    this.currentPositionSeconds = 0,
    required this.audioUrl,
    required this.thumbnailUrl,
    required this.date,
    this.isFeatured = false,
    this.isListening = false,
    required this.summaryNotes,
  });

  double get progress => totalDurationSeconds > 0 
      ? (currentPositionSeconds / totalDurationSeconds).clamp(0.0, 1.0) 
      : 0.0;

  Sermon copyWith({
    String? id,
    String? title,
    String? speaker,
    String? seriesName,
    String? durationFormatted,
    int? totalDurationSeconds,
    int? currentPositionSeconds,
    String? audioUrl,
    String? thumbnailUrl,
    String? date,
    bool? isFeatured,
    bool? isListening,
    String? summaryNotes,
  }) {
    return Sermon(
      id: id ?? this.id,
      title: title ?? this.title,
      speaker: speaker ?? this.speaker,
      seriesName: seriesName ?? this.seriesName,
      durationFormatted: durationFormatted ?? this.durationFormatted,
      totalDurationSeconds: totalDurationSeconds ?? this.totalDurationSeconds,
      currentPositionSeconds: currentPositionSeconds ?? this.currentPositionSeconds,
      audioUrl: audioUrl ?? this.audioUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      date: date ?? this.date,
      isFeatured: isFeatured ?? this.isFeatured,
      isListening: isListening ?? this.isListening,
      summaryNotes: summaryNotes ?? this.summaryNotes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'speaker': speaker,
      'seriesName': seriesName,
      'durationFormatted': durationFormatted,
      'totalDurationSeconds': totalDurationSeconds,
      'currentPositionSeconds': currentPositionSeconds,
      'audioUrl': audioUrl,
      'thumbnailUrl': thumbnailUrl,
      'date': date,
      'isFeatured': isFeatured,
      'isListening': isListening,
      'summaryNotes': summaryNotes,
    };
  }

  factory Sermon.fromJson(Map<String, dynamic> json) {
    return Sermon(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      speaker: json['speaker'] ?? '',
      seriesName: json['seriesName'] ?? '',
      durationFormatted: json['durationFormatted'] ?? '0:00',
      totalDurationSeconds: json['totalDurationSeconds'] ?? 0,
      currentPositionSeconds: json['currentPositionSeconds'] ?? 0,
      audioUrl: json['audioUrl'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      date: json['date'] ?? '',
      isFeatured: json['isFeatured'] ?? false,
      isListening: json['isListening'] ?? false,
      summaryNotes: json['summaryNotes'] ?? '',
    );
  }
}
