// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'piece_detachee.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PieceDetacheeAdapter extends TypeAdapter<PieceDetachee> {
  @override
  final int typeId = 7;

  @override
  PieceDetachee read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PieceDetachee(
      id: fields[0] as String,
      reference: fields[1] as String,
      nom: fields[2] as String,
      categorie: fields[3] as String,
      quantiteStock: fields[4] as int,
      seuilMin: fields[5] as int,
      prixUnitaire: fields[6] as double,
      modelesCompatibles: (fields[7] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, PieceDetachee obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.reference)
      ..writeByte(2)
      ..write(obj.nom)
      ..writeByte(3)
      ..write(obj.categorie)
      ..writeByte(4)
      ..write(obj.quantiteStock)
      ..writeByte(5)
      ..write(obj.seuilMin)
      ..writeByte(6)
      ..write(obj.prixUnitaire)
      ..writeByte(7)
      ..write(obj.modelesCompatibles);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PieceDetacheeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
