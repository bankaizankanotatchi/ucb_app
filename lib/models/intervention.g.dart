// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'intervention.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InterventionAdapter extends TypeAdapter<Intervention> {
  @override
  final int typeId = 3;

  @override
  Intervention read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Intervention(
      id: fields[0] as String,
      code: fields[1] as String,
      type: fields[2] as String,
      priorite: fields[3] as int,
      statut: fields[4] as String,
      dateCreation: fields[5] as DateTime,
      datePlanifiee: fields[6] as DateTime,
      dateDebut: fields[7] as DateTime?,
      dateFin: fields[8] as DateTime?,
      technicienIds: (fields[9] as List).cast<String>(),
      refrigerateurIds: (fields[10] as List).cast<String>(),
      description: fields[11] as String,
      rapportId: fields[12] as String?,
      checklistId: fields[13] as String?,
      clientId: fields[14] as String,
      synchronise: fields[15] as bool,
      updatedAt: fields[16] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Intervention obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.code)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.priorite)
      ..writeByte(4)
      ..write(obj.statut)
      ..writeByte(5)
      ..write(obj.dateCreation)
      ..writeByte(6)
      ..write(obj.datePlanifiee)
      ..writeByte(7)
      ..write(obj.dateDebut)
      ..writeByte(8)
      ..write(obj.dateFin)
      ..writeByte(9)
      ..write(obj.technicienIds)
      ..writeByte(10)
      ..write(obj.refrigerateurIds)
      ..writeByte(11)
      ..write(obj.description)
      ..writeByte(12)
      ..write(obj.rapportId)
      ..writeByte(13)
      ..write(obj.checklistId)
      ..writeByte(14)
      ..write(obj.clientId)
      ..writeByte(15)
      ..write(obj.synchronise)
      ..writeByte(16)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InterventionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
