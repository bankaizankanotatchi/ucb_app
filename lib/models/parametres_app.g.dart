// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'parametres_app.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ParametresAppAdapter extends TypeAdapter<ParametresApp> {
  @override
  final int typeId = 10;

  @override
  ParametresApp read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ParametresApp(
      langue: fields[0] as String,
      notifications: fields[1] as bool,
      gpsAuto: fields[2] as bool,
      modeHorsLigne: fields[3] as bool,
      derniereSession: fields[4] as String,
      derniereSynchro: fields[5] as DateTime,
      tokenNotification: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ParametresApp obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.langue)
      ..writeByte(1)
      ..write(obj.notifications)
      ..writeByte(2)
      ..write(obj.gpsAuto)
      ..writeByte(3)
      ..write(obj.modeHorsLigne)
      ..writeByte(4)
      ..write(obj.derniereSession)
      ..writeByte(5)
      ..write(obj.derniereSynchro)
      ..writeByte(6)
      ..write(obj.tokenNotification);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParametresAppAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
