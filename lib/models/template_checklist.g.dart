// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'template_checklist.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TemplateChecklistAdapter extends TypeAdapter<TemplateChecklist> {
  @override
  final int typeId = 12;

  @override
  TemplateChecklist read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TemplateChecklist(
      id: fields[0] as String,
      nom: fields[1] as String,
      typePanne: fields[2] as String,
      items: (fields[3] as List).cast<TemplateItem>(),
    );
  }

  @override
  void write(BinaryWriter writer, TemplateChecklist obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nom)
      ..writeByte(2)
      ..write(obj.typePanne)
      ..writeByte(3)
      ..write(obj.items);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TemplateChecklistAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TemplateItemAdapter extends TypeAdapter<TemplateItem> {
  @override
  final int typeId = 13;

  @override
  TemplateItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TemplateItem(
      id: fields[0] as String,
      description: fields[1] as String,
      obligatoire: fields[2] as bool,
      ordre: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, TemplateItem obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.obligatoire)
      ..writeByte(3)
      ..write(obj.ordre);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TemplateItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
