import 'package:hive/hive.dart';

/// Registro de auditoria: toda ação relevante do sistema é gravada aqui.
class AppEvent {
  AppEvent({
    required this.id,
    required this.title,
    this.detail = '',
    this.category = 'geral',
    DateTime? at,
  }) : at = at ?? DateTime.now();

  final String id;
  final String title;
  final String detail;
  final String category; // cliente | emprestimo | pagamento | sistema
  final DateTime at;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'detail': detail,
        'category': category,
        'at': at.toIso8601String(),
      };

  factory AppEvent.fromJson(Map<String, dynamic> j) => AppEvent(
        id: j['id'] as String,
        title: j['title'] as String,
        detail: (j['detail'] ?? '') as String,
        category: (j['category'] ?? 'geral') as String,
        at: DateTime.parse(j['at'] as String),
      );
}

class AppEventAdapter extends TypeAdapter<AppEvent> {
  @override
  final int typeId = 5;

  @override
  AppEvent read(BinaryReader reader) {
    final n = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < n; i++) reader.readByte(): reader.read(),
    };
    return AppEvent(
      id: fields[0] as String,
      title: fields[1] as String,
      detail: (fields[2] ?? '') as String,
      category: (fields[3] ?? 'geral') as String,
      at: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, AppEvent obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.detail)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.at);
  }
}
