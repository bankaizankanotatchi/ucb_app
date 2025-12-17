// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checklist.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChecklistAdapter extends TypeAdapter<Checklist> {
  @override
  final int typeId = 5;

  @override
  Checklist read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Checklist(
      id: fields[0] as String,
      interventionId: fields[1] as String,
      type: fields[2] as String,
      items: (fields[3] as List).cast<ChecklistItem>(),
      dateCompletion: fields[4] as DateTime,
      complete: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Checklist obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.interventionId)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.items)
      ..writeByte(4)
      ..write(obj.dateCompletion)
      ..writeByte(5)
      ..write(obj.complete);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChecklistAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ChecklistItemAdapter extends TypeAdapter<ChecklistItem> {
  @override
  final int typeId = 6;

  @override
  ChecklistItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChecklistItem(
      id: fields[0] as String,
      description: fields[1] as String,
      verifie: fields[2] as bool,
      observation: fields[3] as String?,
      photos: (fields[4] as List).cast<String>(),
      obligatoire: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ChecklistItem obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.verifie)
      ..writeByte(3)
      ..write(obj.observation)
      ..writeByte(4)
      ..write(obj.photos)
      ..writeByte(5)
      ..write(obj.obligatoire);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChecklistItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
