// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'historique_localisation.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HistoriqueLocalisationAdapter
    extends TypeAdapter<HistoriqueLocalisation> {
  @override
  final int typeId = 11;

  @override
  HistoriqueLocalisation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HistoriqueLocalisation(
      id: fields[0] as String,
      technicienId: fields[1] as String,
      latitude: fields[2] as double,
      longitude: fields[3] as double,
      timestamp: fields[4] as DateTime,
      interventionId: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, HistoriqueLocalisation obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.technicienId)
      ..writeByte(2)
      ..write(obj.latitude)
      ..writeByte(3)
      ..write(obj.longitude)
      ..writeByte(4)
      ..write(obj.timestamp)
      ..writeByte(5)
      ..write(obj.interventionId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HistoriqueLocalisationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
