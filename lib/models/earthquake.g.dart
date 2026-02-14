// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'earthquake.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EarthquakeAdapter extends TypeAdapter<Earthquake> {
  @override
  final int typeId = 0;

  @override
  Earthquake read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Earthquake(
      id: fields[0] as String,
      magnitude: fields[1] as double,
      place: fields[2] as String,
      time: fields[3] as DateTime,
      latitude: fields[4] as double,
      longitude: fields[5] as double,
      source: fields[6] as EarthquakeSource,
      provider: fields[7] as String,
      distance: fields[8] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, Earthquake obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.magnitude)
      ..writeByte(2)
      ..write(obj.place)
      ..writeByte(3)
      ..write(obj.time)
      ..writeByte(4)
      ..write(obj.latitude)
      ..writeByte(5)
      ..write(obj.longitude)
      ..writeByte(6)
      ..write(obj.source)
      ..writeByte(7)
      ..write(obj.provider)
      ..writeByte(8)
      ..write(obj.distance);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EarthquakeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EarthquakeSourceAdapter extends TypeAdapter<EarthquakeSource> {
  @override
  final int typeId = 1;

  @override
  EarthquakeSource read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return EarthquakeSource.usgs;
      case 1:
        return EarthquakeSource.emsc;
      default:
        return EarthquakeSource.usgs;
    }
  }

  @override
  void write(BinaryWriter writer, EarthquakeSource obj) {
    switch (obj) {
      case EarthquakeSource.usgs:
        writer.writeByte(0);
        break;
      case EarthquakeSource.emsc:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EarthquakeSourceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
