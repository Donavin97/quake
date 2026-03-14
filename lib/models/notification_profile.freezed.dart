// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notification_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

NotificationProfile _$NotificationProfileFromJson(Map<String, dynamic> json) {
  return _NotificationProfile.fromJson(json);
}

/// @nodoc
mixin _$NotificationProfile {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  double get latitude => throw _privateConstructorUsedError;
  double get longitude => throw _privateConstructorUsedError;
  double get radius => throw _privateConstructorUsedError;
  double get minMagnitude => throw _privateConstructorUsedError;
  bool get quietHoursEnabled => throw _privateConstructorUsedError;
  List<int> get quietHoursStart => throw _privateConstructorUsedError;
  List<int> get quietHoursEnd => throw _privateConstructorUsedError;
  List<int> get quietHoursDays => throw _privateConstructorUsedError;
  bool get alwaysNotifyRadiusEnabled => throw _privateConstructorUsedError;
  double get alwaysNotifyRadiusValue => throw _privateConstructorUsedError;
  double get emergencyMagnitudeThreshold => throw _privateConstructorUsedError;
  double get emergencyRadius => throw _privateConstructorUsedError;
  double get globalMinMagnitudeOverrideQuietHours =>
      throw _privateConstructorUsedError;
  String? get timezone => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $NotificationProfileCopyWith<NotificationProfile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NotificationProfileCopyWith<$Res> {
  factory $NotificationProfileCopyWith(
          NotificationProfile value, $Res Function(NotificationProfile) then) =
      _$NotificationProfileCopyWithImpl<$Res, NotificationProfile>;
  @useResult
  $Res call(
      {String id,
      String name,
      double latitude,
      double longitude,
      double radius,
      double minMagnitude,
      bool quietHoursEnabled,
      List<int> quietHoursStart,
      List<int> quietHoursEnd,
      List<int> quietHoursDays,
      bool alwaysNotifyRadiusEnabled,
      double alwaysNotifyRadiusValue,
      double emergencyMagnitudeThreshold,
      double emergencyRadius,
      double globalMinMagnitudeOverrideQuietHours,
      String? timezone});
}

/// @nodoc
class _$NotificationProfileCopyWithImpl<$Res, $Val extends NotificationProfile>
    implements $NotificationProfileCopyWith<$Res> {
  _$NotificationProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? latitude = null,
    Object? longitude = null,
    Object? radius = null,
    Object? minMagnitude = null,
    Object? quietHoursEnabled = null,
    Object? quietHoursStart = null,
    Object? quietHoursEnd = null,
    Object? quietHoursDays = null,
    Object? alwaysNotifyRadiusEnabled = null,
    Object? alwaysNotifyRadiusValue = null,
    Object? emergencyMagnitudeThreshold = null,
    Object? emergencyRadius = null,
    Object? globalMinMagnitudeOverrideQuietHours = null,
    Object? timezone = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      latitude: null == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double,
      longitude: null == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double,
      radius: null == radius
          ? _value.radius
          : radius // ignore: cast_nullable_to_non_nullable
              as double,
      minMagnitude: null == minMagnitude
          ? _value.minMagnitude
          : minMagnitude // ignore: cast_nullable_to_non_nullable
              as double,
      quietHoursEnabled: null == quietHoursEnabled
          ? _value.quietHoursEnabled
          : quietHoursEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      quietHoursStart: null == quietHoursStart
          ? _value.quietHoursStart
          : quietHoursStart // ignore: cast_nullable_to_non_nullable
              as List<int>,
      quietHoursEnd: null == quietHoursEnd
          ? _value.quietHoursEnd
          : quietHoursEnd // ignore: cast_nullable_to_non_nullable
              as List<int>,
      quietHoursDays: null == quietHoursDays
          ? _value.quietHoursDays
          : quietHoursDays // ignore: cast_nullable_to_non_nullable
              as List<int>,
      alwaysNotifyRadiusEnabled: null == alwaysNotifyRadiusEnabled
          ? _value.alwaysNotifyRadiusEnabled
          : alwaysNotifyRadiusEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      alwaysNotifyRadiusValue: null == alwaysNotifyRadiusValue
          ? _value.alwaysNotifyRadiusValue
          : alwaysNotifyRadiusValue // ignore: cast_nullable_to_non_nullable
              as double,
      emergencyMagnitudeThreshold: null == emergencyMagnitudeThreshold
          ? _value.emergencyMagnitudeThreshold
          : emergencyMagnitudeThreshold // ignore: cast_nullable_to_non_nullable
              as double,
      emergencyRadius: null == emergencyRadius
          ? _value.emergencyRadius
          : emergencyRadius // ignore: cast_nullable_to_non_nullable
              as double,
      globalMinMagnitudeOverrideQuietHours: null ==
              globalMinMagnitudeOverrideQuietHours
          ? _value.globalMinMagnitudeOverrideQuietHours
          : globalMinMagnitudeOverrideQuietHours // ignore: cast_nullable_to_non_nullable
              as double,
      timezone: freezed == timezone
          ? _value.timezone
          : timezone // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$NotificationProfileImplCopyWith<$Res>
    implements $NotificationProfileCopyWith<$Res> {
  factory _$$NotificationProfileImplCopyWith(_$NotificationProfileImpl value,
          $Res Function(_$NotificationProfileImpl) then) =
      __$$NotificationProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      double latitude,
      double longitude,
      double radius,
      double minMagnitude,
      bool quietHoursEnabled,
      List<int> quietHoursStart,
      List<int> quietHoursEnd,
      List<int> quietHoursDays,
      bool alwaysNotifyRadiusEnabled,
      double alwaysNotifyRadiusValue,
      double emergencyMagnitudeThreshold,
      double emergencyRadius,
      double globalMinMagnitudeOverrideQuietHours,
      String? timezone});
}

/// @nodoc
class __$$NotificationProfileImplCopyWithImpl<$Res>
    extends _$NotificationProfileCopyWithImpl<$Res, _$NotificationProfileImpl>
    implements _$$NotificationProfileImplCopyWith<$Res> {
  __$$NotificationProfileImplCopyWithImpl(_$NotificationProfileImpl _value,
      $Res Function(_$NotificationProfileImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? latitude = null,
    Object? longitude = null,
    Object? radius = null,
    Object? minMagnitude = null,
    Object? quietHoursEnabled = null,
    Object? quietHoursStart = null,
    Object? quietHoursEnd = null,
    Object? quietHoursDays = null,
    Object? alwaysNotifyRadiusEnabled = null,
    Object? alwaysNotifyRadiusValue = null,
    Object? emergencyMagnitudeThreshold = null,
    Object? emergencyRadius = null,
    Object? globalMinMagnitudeOverrideQuietHours = null,
    Object? timezone = freezed,
  }) {
    return _then(_$NotificationProfileImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      latitude: null == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double,
      longitude: null == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double,
      radius: null == radius
          ? _value.radius
          : radius // ignore: cast_nullable_to_non_nullable
              as double,
      minMagnitude: null == minMagnitude
          ? _value.minMagnitude
          : minMagnitude // ignore: cast_nullable_to_non_nullable
              as double,
      quietHoursEnabled: null == quietHoursEnabled
          ? _value.quietHoursEnabled
          : quietHoursEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      quietHoursStart: null == quietHoursStart
          ? _value._quietHoursStart
          : quietHoursStart // ignore: cast_nullable_to_non_nullable
              as List<int>,
      quietHoursEnd: null == quietHoursEnd
          ? _value._quietHoursEnd
          : quietHoursEnd // ignore: cast_nullable_to_non_nullable
              as List<int>,
      quietHoursDays: null == quietHoursDays
          ? _value._quietHoursDays
          : quietHoursDays // ignore: cast_nullable_to_non_nullable
              as List<int>,
      alwaysNotifyRadiusEnabled: null == alwaysNotifyRadiusEnabled
          ? _value.alwaysNotifyRadiusEnabled
          : alwaysNotifyRadiusEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      alwaysNotifyRadiusValue: null == alwaysNotifyRadiusValue
          ? _value.alwaysNotifyRadiusValue
          : alwaysNotifyRadiusValue // ignore: cast_nullable_to_non_nullable
              as double,
      emergencyMagnitudeThreshold: null == emergencyMagnitudeThreshold
          ? _value.emergencyMagnitudeThreshold
          : emergencyMagnitudeThreshold // ignore: cast_nullable_to_non_nullable
              as double,
      emergencyRadius: null == emergencyRadius
          ? _value.emergencyRadius
          : emergencyRadius // ignore: cast_nullable_to_non_nullable
              as double,
      globalMinMagnitudeOverrideQuietHours: null ==
              globalMinMagnitudeOverrideQuietHours
          ? _value.globalMinMagnitudeOverrideQuietHours
          : globalMinMagnitudeOverrideQuietHours // ignore: cast_nullable_to_non_nullable
              as double,
      timezone: freezed == timezone
          ? _value.timezone
          : timezone // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$NotificationProfileImpl implements _NotificationProfile {
  const _$NotificationProfileImpl(
      {required this.id,
      required this.name,
      required this.latitude,
      required this.longitude,
      required this.radius,
      required this.minMagnitude,
      this.quietHoursEnabled = false,
      final List<int> quietHoursStart = const [22, 0],
      final List<int> quietHoursEnd = const [6, 0],
      final List<int> quietHoursDays = const [0, 1, 2, 3, 4, 5, 6],
      this.alwaysNotifyRadiusEnabled = false,
      this.alwaysNotifyRadiusValue = 0.0,
      this.emergencyMagnitudeThreshold = 0.0,
      this.emergencyRadius = 0.0,
      this.globalMinMagnitudeOverrideQuietHours = 0.0,
      this.timezone})
      : _quietHoursStart = quietHoursStart,
        _quietHoursEnd = quietHoursEnd,
        _quietHoursDays = quietHoursDays;

  factory _$NotificationProfileImpl.fromJson(Map<String, dynamic> json) =>
      _$$NotificationProfileImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final double latitude;
  @override
  final double longitude;
  @override
  final double radius;
  @override
  final double minMagnitude;
  @override
  @JsonKey()
  final bool quietHoursEnabled;
  final List<int> _quietHoursStart;
  @override
  @JsonKey()
  List<int> get quietHoursStart {
    if (_quietHoursStart is EqualUnmodifiableListView) return _quietHoursStart;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_quietHoursStart);
  }

  final List<int> _quietHoursEnd;
  @override
  @JsonKey()
  List<int> get quietHoursEnd {
    if (_quietHoursEnd is EqualUnmodifiableListView) return _quietHoursEnd;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_quietHoursEnd);
  }

  final List<int> _quietHoursDays;
  @override
  @JsonKey()
  List<int> get quietHoursDays {
    if (_quietHoursDays is EqualUnmodifiableListView) return _quietHoursDays;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_quietHoursDays);
  }

  @override
  @JsonKey()
  final bool alwaysNotifyRadiusEnabled;
  @override
  @JsonKey()
  final double alwaysNotifyRadiusValue;
  @override
  @JsonKey()
  final double emergencyMagnitudeThreshold;
  @override
  @JsonKey()
  final double emergencyRadius;
  @override
  @JsonKey()
  final double globalMinMagnitudeOverrideQuietHours;
  @override
  final String? timezone;

  @override
  String toString() {
    return 'NotificationProfile(id: $id, name: $name, latitude: $latitude, longitude: $longitude, radius: $radius, minMagnitude: $minMagnitude, quietHoursEnabled: $quietHoursEnabled, quietHoursStart: $quietHoursStart, quietHoursEnd: $quietHoursEnd, quietHoursDays: $quietHoursDays, alwaysNotifyRadiusEnabled: $alwaysNotifyRadiusEnabled, alwaysNotifyRadiusValue: $alwaysNotifyRadiusValue, emergencyMagnitudeThreshold: $emergencyMagnitudeThreshold, emergencyRadius: $emergencyRadius, globalMinMagnitudeOverrideQuietHours: $globalMinMagnitudeOverrideQuietHours, timezone: $timezone)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NotificationProfileImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.radius, radius) || other.radius == radius) &&
            (identical(other.minMagnitude, minMagnitude) ||
                other.minMagnitude == minMagnitude) &&
            (identical(other.quietHoursEnabled, quietHoursEnabled) ||
                other.quietHoursEnabled == quietHoursEnabled) &&
            const DeepCollectionEquality()
                .equals(other._quietHoursStart, _quietHoursStart) &&
            const DeepCollectionEquality()
                .equals(other._quietHoursEnd, _quietHoursEnd) &&
            const DeepCollectionEquality()
                .equals(other._quietHoursDays, _quietHoursDays) &&
            (identical(other.alwaysNotifyRadiusEnabled,
                    alwaysNotifyRadiusEnabled) ||
                other.alwaysNotifyRadiusEnabled == alwaysNotifyRadiusEnabled) &&
            (identical(
                    other.alwaysNotifyRadiusValue, alwaysNotifyRadiusValue) ||
                other.alwaysNotifyRadiusValue == alwaysNotifyRadiusValue) &&
            (identical(other.emergencyMagnitudeThreshold,
                    emergencyMagnitudeThreshold) ||
                other.emergencyMagnitudeThreshold ==
                    emergencyMagnitudeThreshold) &&
            (identical(other.emergencyRadius, emergencyRadius) ||
                other.emergencyRadius == emergencyRadius) &&
            (identical(other.globalMinMagnitudeOverrideQuietHours,
                    globalMinMagnitudeOverrideQuietHours) ||
                other.globalMinMagnitudeOverrideQuietHours ==
                    globalMinMagnitudeOverrideQuietHours) &&
            (identical(other.timezone, timezone) ||
                other.timezone == timezone));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      latitude,
      longitude,
      radius,
      minMagnitude,
      quietHoursEnabled,
      const DeepCollectionEquality().hash(_quietHoursStart),
      const DeepCollectionEquality().hash(_quietHoursEnd),
      const DeepCollectionEquality().hash(_quietHoursDays),
      alwaysNotifyRadiusEnabled,
      alwaysNotifyRadiusValue,
      emergencyMagnitudeThreshold,
      emergencyRadius,
      globalMinMagnitudeOverrideQuietHours,
      timezone);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$NotificationProfileImplCopyWith<_$NotificationProfileImpl> get copyWith =>
      __$$NotificationProfileImplCopyWithImpl<_$NotificationProfileImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$NotificationProfileImplToJson(
      this,
    );
  }
}

abstract class _NotificationProfile implements NotificationProfile {
  const factory _NotificationProfile(
      {required final String id,
      required final String name,
      required final double latitude,
      required final double longitude,
      required final double radius,
      required final double minMagnitude,
      final bool quietHoursEnabled,
      final List<int> quietHoursStart,
      final List<int> quietHoursEnd,
      final List<int> quietHoursDays,
      final bool alwaysNotifyRadiusEnabled,
      final double alwaysNotifyRadiusValue,
      final double emergencyMagnitudeThreshold,
      final double emergencyRadius,
      final double globalMinMagnitudeOverrideQuietHours,
      final String? timezone}) = _$NotificationProfileImpl;

  factory _NotificationProfile.fromJson(Map<String, dynamic> json) =
      _$NotificationProfileImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  double get latitude;
  @override
  double get longitude;
  @override
  double get radius;
  @override
  double get minMagnitude;
  @override
  bool get quietHoursEnabled;
  @override
  List<int> get quietHoursStart;
  @override
  List<int> get quietHoursEnd;
  @override
  List<int> get quietHoursDays;
  @override
  bool get alwaysNotifyRadiusEnabled;
  @override
  double get alwaysNotifyRadiusValue;
  @override
  double get emergencyMagnitudeThreshold;
  @override
  double get emergencyRadius;
  @override
  double get globalMinMagnitudeOverrideQuietHours;
  @override
  String? get timezone;
  @override
  @JsonKey(ignore: true)
  _$$NotificationProfileImplCopyWith<_$NotificationProfileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
