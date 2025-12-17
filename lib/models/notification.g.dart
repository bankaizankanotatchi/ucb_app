// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NotificationTechAdapter extends TypeAdapter<NotificationTech> {
  @override
  final int typeId = 8;

  @override
  NotificationTech read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NotificationTech(
      id: fields[0] as String,
      titre: fields[1] as String,
      message: fields[2] as String,
      type: fields[3] as String,
      date: fields[4] as DateTime,
      lue: fields[5] as bool,
      interventionId: fields[6] as String?,
      refrigerateurId: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, NotificationTech obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.titre)
      ..writeByte(2)
      ..write(obj.message)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.lue)
      ..writeByte(6)
      ..write(obj.interventionId)
      ..writeByte(7)
      ..write(obj.refrigerateurId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationTechAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
