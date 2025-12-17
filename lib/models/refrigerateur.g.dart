// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'refrigerateur.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RefrigerateurAdapter extends TypeAdapter<Refrigerateur> {
  @override
  final int typeId = 2;

  @override
  Refrigerateur read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Refrigerateur(
      id: fields[0] as String,
      codeQR: fields[1] as String,
      numeroSerie: fields[2] as String,
      marque: fields[3] as String,
      modele: fields[4] as String,
      type: fields[5] as String,
      clientId: fields[6] as String,
      adresse: fields[7] as String,
      latitude: fields[8] as double,
      longitude: fields[9] as double,
      statut: fields[10] as String,
      dateInstallation: fields[11] as DateTime?,
      dateDerniereMaintenance: fields[12] as DateTime?,
      caracteristiques: (fields[13] as Map).cast<String, dynamic>(),
      photosAvantReparation: (fields[14] as List).cast<String>(),
      photosPendantReparation: (fields[15] as List).cast<String>(),
      photosApresReparation: (fields[16] as List).cast<String>(),
      dateDernieresPhotos: fields[17] as DateTime?,
      dernierTechnicienPhotos: fields[18] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Refrigerateur obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.codeQR)
      ..writeByte(2)
      ..write(obj.numeroSerie)
      ..writeByte(3)
      ..write(obj.marque)
      ..writeByte(4)
      ..write(obj.modele)
      ..writeByte(5)
      ..write(obj.type)
      ..writeByte(6)
      ..write(obj.clientId)
      ..writeByte(7)
      ..write(obj.adresse)
      ..writeByte(8)
      ..write(obj.latitude)
      ..writeByte(9)
      ..write(obj.longitude)
      ..writeByte(10)
      ..write(obj.statut)
      ..writeByte(11)
      ..write(obj.dateInstallation)
      ..writeByte(12)
      ..write(obj.dateDerniereMaintenance)
      ..writeByte(13)
      ..write(obj.caracteristiques)
      ..writeByte(14)
      ..write(obj.photosAvantReparation)
      ..writeByte(15)
      ..write(obj.photosPendantReparation)
      ..writeByte(16)
      ..write(obj.photosApresReparation)
      ..writeByte(17)
      ..write(obj.dateDernieresPhotos)
      ..writeByte(18)
      ..write(obj.dernierTechnicienPhotos);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RefrigerateurAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
