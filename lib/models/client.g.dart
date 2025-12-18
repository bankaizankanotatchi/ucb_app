// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ClientAdapter extends TypeAdapter<Client> {
  @override
  final int typeId = 9;

  @override
  Client read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Client(
      id: fields[0] as String,
      nom: fields[1] as String,
      contact: fields[2] as String?,
      telephone: fields[3] as String,
      email: fields[4] as String,
      adresse: fields[5] as String,
      latitude: fields[6] as double,
      longitude: fields[7] as double,
      type: fields[8] as String,
      refrigerateurIds: (fields[9] as List).cast<String>(),
      dateInscription: fields[10] as DateTime,
      photos: (fields[11] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, Client obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nom)
      ..writeByte(2)
      ..write(obj.contact)
      ..writeByte(3)
      ..write(obj.telephone)
      ..writeByte(4)
      ..write(obj.email)
      ..writeByte(5)
      ..write(obj.adresse)
      ..writeByte(6)
      ..write(obj.latitude)
      ..writeByte(7)
      ..write(obj.longitude)
      ..writeByte(8)
      ..write(obj.type)
      ..writeByte(9)
      ..write(obj.refrigerateurIds)
      ..writeByte(10)
      ..write(obj.dateInscription)
      ..writeByte(11)
      ..write(obj.photos);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClientAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
