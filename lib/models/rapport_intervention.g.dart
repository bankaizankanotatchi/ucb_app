// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rapport_intervention.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RapportInterventionAdapter extends TypeAdapter<RapportIntervention> {
  @override
  final int typeId = 4;

  @override
  RapportIntervention read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RapportIntervention(
      id: fields[0] as String,
      interventionId: fields[1] as String,
      technicienId: fields[2] as String,
      dateRapport: fields[3] as DateTime,
      problemeDiagnostique: fields[4] as String,
      actionsRealisees: fields[5] as String,
      piecesUtilisees: (fields[6] as List).cast<String>(),
      tempsPasse: fields[7] as double,
      photosAvant: (fields[8] as List).cast<String>(),
      photosApres: (fields[9] as List).cast<String>(),
      signaturePath: fields[10] as String?,
      observations: fields[11] as String,
      clientSatisfait: fields[12] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, RapportIntervention obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.interventionId)
      ..writeByte(2)
      ..write(obj.technicienId)
      ..writeByte(3)
      ..write(obj.dateRapport)
      ..writeByte(4)
      ..write(obj.problemeDiagnostique)
      ..writeByte(5)
      ..write(obj.actionsRealisees)
      ..writeByte(6)
      ..write(obj.piecesUtilisees)
      ..writeByte(7)
      ..write(obj.tempsPasse)
      ..writeByte(8)
      ..write(obj.photosAvant)
      ..writeByte(9)
      ..write(obj.photosApres)
      ..writeByte(10)
      ..write(obj.signaturePath)
      ..writeByte(11)
      ..write(obj.observations)
      ..writeByte(12)
      ..write(obj.clientSatisfait);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RapportInterventionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
