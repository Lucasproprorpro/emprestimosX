import 'package:hive/hive.dart';

import '../../core/constants/enums.dart';

/// Cliente / tomador. Serve tanto para pessoa física quanto comerciante
/// (modalidade Diário guarda dados extras do comércio).
class Client {
  Client({
    required this.id,
    required this.name,
    this.document = '',
    this.cpf,
    this.phone = '',
    this.address = '',
    this.photoPath,
    this.latitude,
    this.longitude,
    this.notes = '',
    this.businessName,
    this.businessType,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  String name;
  String document;
  String? cpf;
  String phone;
  String address;
  String? photoPath;
  double? latitude;
  double? longitude;
  String notes;

  // Campos do comércio (modalidade Diário).
  String? businessName;
  BusinessType? businessType;

  final DateTime createdAt;

  bool get hasLocation => latitude != null && longitude != null;

  Client copyWith({
    String? name,
    String? document,
    String? cpf,
    String? phone,
    String? address,
    String? photoPath,
    double? latitude,
    double? longitude,
    String? notes,
    String? businessName,
    BusinessType? businessType,
  }) {
    return Client(
      id: id,
      name: name ?? this.name,
      document: document ?? this.document,
      cpf: cpf ?? this.cpf,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      photoPath: photoPath ?? this.photoPath,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      notes: notes ?? this.notes,
      businessName: businessName ?? this.businessName,
      businessType: businessType ?? this.businessType,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'document': document,
        'cpf': cpf,
        'phone': phone,
        'address': address,
        'photoPath': photoPath,
        'latitude': latitude,
        'longitude': longitude,
        'notes': notes,
        'businessName': businessName,
        'businessType': businessType?.index,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Client.fromJson(Map<String, dynamic> j) => Client(
        id: j['id'] as String,
        name: j['name'] as String,
        document: (j['document'] ?? '') as String,
        cpf: j['cpf'] as String?,
        phone: (j['phone'] ?? '') as String,
        address: (j['address'] ?? '') as String,
        photoPath: j['photoPath'] as String?,
        latitude: (j['latitude'] as num?)?.toDouble(),
        longitude: (j['longitude'] as num?)?.toDouble(),
        notes: (j['notes'] ?? '') as String,
        businessName: j['businessName'] as String?,
        businessType: j['businessType'] == null
            ? null
            : BusinessType.values[j['businessType'] as int],
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}

class ClientAdapter extends TypeAdapter<Client> {
  @override
  final int typeId = 1;

  @override
  Client read(BinaryReader reader) {
    final n = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < n; i++) reader.readByte(): reader.read(),
    };
    return Client(
      id: fields[0] as String,
      name: fields[1] as String,
      document: (fields[2] ?? '') as String,
      cpf: fields[3] as String?,
      phone: (fields[4] ?? '') as String,
      address: (fields[5] ?? '') as String,
      photoPath: fields[6] as String?,
      latitude: fields[7] as double?,
      longitude: fields[8] as double?,
      notes: (fields[9] ?? '') as String,
      businessName: fields[10] as String?,
      businessType: fields[11] == null
          ? null
          : BusinessType.values[fields[11] as int],
      createdAt: fields[12] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Client obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.document)
      ..writeByte(3)
      ..write(obj.cpf)
      ..writeByte(4)
      ..write(obj.phone)
      ..writeByte(5)
      ..write(obj.address)
      ..writeByte(6)
      ..write(obj.photoPath)
      ..writeByte(7)
      ..write(obj.latitude)
      ..writeByte(8)
      ..write(obj.longitude)
      ..writeByte(9)
      ..write(obj.notes)
      ..writeByte(10)
      ..write(obj.businessName)
      ..writeByte(11)
      ..write(obj.businessType?.index)
      ..writeByte(12)
      ..write(obj.createdAt);
  }
}
