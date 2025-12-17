// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'technicien.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TechnicienAdapter extends TypeAdapter<Technicien> {
  @override
  final int typeId = 1;

  @override
  Technicien read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Technicien(
      id: fields[0] as String,
      matricule: fields[1] as String,
      nom: fields[2] as String,
      prenom: fields[3] as String,
      telephone: fields[4] as String,
      email: fields[5] as String,
      motDePasse: fields[6] as String,
      specialite: fields[7] as String,
      createdAt: fields[8] as DateTime,
      zoneAffectation: fields[9] as String?,
      actif: fields[10] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Technicien obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.matricule)
      ..writeByte(2)
      ..write(obj.nom)
      ..writeByte(3)
      ..write(obj.prenom)
      ..writeByte(4)
      ..write(obj.telephone)
      ..writeByte(5)
      ..write(obj.email)
      ..writeByte(6)
      ..write(obj.motDePasse)
      ..writeByte(7)
      ..write(obj.specialite)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.zoneAffectation)
      ..writeByte(10)
      ..write(obj.actif);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TechnicienAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
