import 'package:hive/hive.dart';

class SermonNote extends HiveObject {
  String id;
  String title;
  String speaker;
  String event; // church/event name (optional)
  DateTime date;
  String content;
  DateTime createdAt;
  DateTime updatedAt;
  String? linkedRecordingId; // optional link to a sermon recording

  SermonNote({
    required this.id,
    required this.title,
    this.speaker = '',
    this.event = '',
    required this.date,
    this.content = '',
    required this.createdAt,
    required this.updatedAt,
    this.linkedRecordingId,
  });

  SermonNote copyWith({
    String? id,
    String? title,
    String? speaker,
    String? event,
    DateTime? date,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? linkedRecordingId,
  }) {
    return SermonNote(
      id: id ?? this.id,
      title: title ?? this.title,
      speaker: speaker ?? this.speaker,
      event: event ?? this.event,
      date: date ?? this.date,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      linkedRecordingId: linkedRecordingId ?? this.linkedRecordingId,
    );
  }
}

class SermonNoteAdapter extends TypeAdapter<SermonNote> {
  @override
  final int typeId = 1;

  @override
  SermonNote read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return SermonNote(
      id: fields[0] as String,
      title: fields[1] as String,
      speaker: fields[2] as String? ?? '',
      event: fields[3] as String? ?? '',
      date: fields[4] as DateTime,
      content: fields[5] as String? ?? '',
      createdAt: fields[6] as DateTime,
      updatedAt: fields[7] as DateTime,
      linkedRecordingId: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SermonNote obj) {
    writer
      ..writeByte(9) // number of fields
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.speaker)
      ..writeByte(3)
      ..write(obj.event)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.content)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt)
      ..writeByte(8)
      ..write(obj.linkedRecordingId);
  }
}
