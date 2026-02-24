// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NotificationProfileAdapter extends TypeAdapter<NotificationProfile> {
  @override
  final int typeId = 3;

  @override
  NotificationProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NotificationProfile(
      id: fields[0] as String,
      name: fields[1] as String,
      latitude: fields[2] as double,
      longitude: fields[3] as double,
      radius: fields[4] as double,
      minMagnitude: fields[5] as double,
      quietHoursEnabled: fields[6] as bool,
      quietHoursStart: (fields[7] as List).cast<int>(),
      quietHoursEnd: (fields[8] as List).cast<int>(),
      quietHoursDays: (fields[9] as List).cast<int>(),
      alwaysNotifyRadiusEnabled: fields[10] as bool,
      alwaysNotifyRadiusValue: fields[11] as double,
      emergencyMagnitudeThreshold: fields[12] as double,
      emergencyRadius: fields[13] as double,
      globalMinMagnitudeOverrideQuietHours: fields[14] as double,
    );
  }

  @override
  void write(BinaryWriter writer, NotificationProfile obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.latitude)
      ..writeByte(3)
      ..write(obj.longitude)
      ..writeByte(4)
      ..write(obj.radius)
      ..writeByte(5)
      ..write(obj.minMagnitude)
      ..writeByte(6)
      ..write(obj.quietHoursEnabled)
      ..writeByte(7)
      ..write(obj.quietHoursStart)
      ..writeByte(8)
      ..write(obj.quietHoursEnd)
      ..writeByte(9)
      ..write(obj.quietHoursDays)
      ..writeByte(10)
      ..write(obj.alwaysNotifyRadiusEnabled)
      ..writeByte(11)
      ..write(obj.alwaysNotifyRadiusValue)
      ..writeByte(12)
      ..write(obj.emergencyMagnitudeThreshold)
      ..writeByte(13)
      ..write(obj.emergencyRadius)
      ..writeByte(14)
      ..write(obj.globalMinMagnitudeOverrideQuietHours);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
