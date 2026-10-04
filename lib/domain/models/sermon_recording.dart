import 'package:hive/hive.dart';

class SermonRecording extends HiveObject {
  String id;
  String title;
  String filePath;
  int durationMs; // duration in milliseconds
  DateTime createdAt;
  DateTime updatedAt;
  String speaker;
  int fileSizeBytes;
  int lastPlaybackPositionMs; // for resuming playback
  String? linkedNoteId; // optional link to a sermon note

  SermonRecording({
    required this.id,
    required this.title,
    required this.filePath,
    required this.durationMs,
    required this.createdAt,
    required this.updatedAt,
    this.speaker = '',
    this.fileSizeBytes = 0,
    this.lastPlaybackPositionMs = 0,
    this.linkedNoteId,
  });

  String get durationFormatted {
    final duration = Duration(milliseconds: durationMs);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get fileSizeFormatted {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  SermonRecording copyWith({
    String? id,
    String? title,
    String? filePath,
    int? durationMs,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? speaker,
    int? fileSizeBytes,
    int? lastPlaybackPositionMs,
    String? linkedNoteId,
  }) {
    return SermonRecording(
      id: id ?? this.id,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      durationMs: durationMs ?? this.durationMs,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      speaker: speaker ?? this.speaker,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      lastPlaybackPositionMs: lastPlaybackPositionMs ?? this.lastPlaybackPositionMs,
      linkedNoteId: linkedNoteId ?? this.linkedNoteId,
    );
  }
}

class SermonRecordingAdapter extends TypeAdapter<SermonRecording> {
  @override
  final int typeId = 2;

  @override
  SermonRecording read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return SermonRecording(
      id: fields[0] as String,
      title: fields[1] as String,
      filePath: fields[2] as String,
      durationMs: fields[3] as int,
      createdAt: fields[4] as DateTime,
      updatedAt: fields[5] as DateTime,
      speaker: fields[6] as String? ?? '',
      fileSizeBytes: fields[7] as int? ?? 0,
      lastPlaybackPositionMs: fields[8] as int? ?? 0,
      linkedNoteId: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SermonRecording obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.filePath)
      ..writeByte(3)
      ..write(obj.durationMs)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt)
      ..writeByte(6)
      ..write(obj.speaker)
      ..writeByte(7)
      ..write(obj.fileSizeBytes)
      ..writeByte(8)
      ..write(obj.lastPlaybackPositionMs)
      ..writeByte(9)
      ..write(obj.linkedNoteId);
  }
}
