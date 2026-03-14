// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_preferences.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

VibrationSettings _$VibrationSettingsFromJson(Map<String, dynamic> json) {
  return _VibrationSettings.fromJson(json);
}

/// @nodoc
mixin _$VibrationSettings {
  int get duration => throw _privateConstructorUsedError;
  int get pattern => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $VibrationSettingsCopyWith<VibrationSettings> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VibrationSettingsCopyWith<$Res> {
  factory $VibrationSettingsCopyWith(
          VibrationSettings value, $Res Function(VibrationSettings) then) =
      _$VibrationSettingsCopyWithImpl<$Res, VibrationSettings>;
  @useResult
  $Res call({int duration, int pattern});
}

/// @nodoc
class _$VibrationSettingsCopyWithImpl<$Res, $Val extends VibrationSettings>
    implements $VibrationSettingsCopyWith<$Res> {
  _$VibrationSettingsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? duration = null,
    Object? pattern = null,
  }) {
    return _then(_value.copyWith(
      duration: null == duration
          ? _value.duration
          : duration // ignore: cast_nullable_to_non_nullable
              as int,
      pattern: null == pattern
          ? _value.pattern
          : pattern // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$VibrationSettingsImplCopyWith<$Res>
    implements $VibrationSettingsCopyWith<$Res> {
  factory _$$VibrationSettingsImplCopyWith(_$VibrationSettingsImpl value,
          $Res Function(_$VibrationSettingsImpl) then) =
      __$$VibrationSettingsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int duration, int pattern});
}

/// @nodoc
class __$$VibrationSettingsImplCopyWithImpl<$Res>
    extends _$VibrationSettingsCopyWithImpl<$Res, _$VibrationSettingsImpl>
    implements _$$VibrationSettingsImplCopyWith<$Res> {
  __$$VibrationSettingsImplCopyWithImpl(_$VibrationSettingsImpl _value,
      $Res Function(_$VibrationSettingsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? duration = null,
    Object? pattern = null,
  }) {
    return _then(_$VibrationSettingsImpl(
      duration: null == duration
          ? _value.duration
          : duration // ignore: cast_nullable_to_non_nullable
              as int,
      pattern: null == pattern
          ? _value.pattern
          : pattern // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$VibrationSettingsImpl implements _VibrationSettings {
  const _$VibrationSettingsImpl({this.duration = 50, this.pattern = 1});

  factory _$VibrationSettingsImpl.fromJson(Map<String, dynamic> json) =>
      _$$VibrationSettingsImplFromJson(json);

  @override
  @JsonKey()
  final int duration;
  @override
  @JsonKey()
  final int pattern;

  @override
  String toString() {
    return 'VibrationSettings(duration: $duration, pattern: $pattern)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VibrationSettingsImpl &&
            (identical(other.duration, duration) ||
                other.duration == duration) &&
            (identical(other.pattern, pattern) || other.pattern == pattern));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, duration, pattern);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$VibrationSettingsImplCopyWith<_$VibrationSettingsImpl> get copyWith =>
      __$$VibrationSettingsImplCopyWithImpl<_$VibrationSettingsImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VibrationSettingsImplToJson(
      this,
    );
  }
}

abstract class _VibrationSettings implements VibrationSettings {
  const factory _VibrationSettings({final int duration, final int pattern}) =
      _$VibrationSettingsImpl;

  factory _VibrationSettings.fromJson(Map<String, dynamic> json) =
      _$VibrationSettingsImpl.fromJson;

  @override
  int get duration;
  @override
  int get pattern;
  @override
  @JsonKey(ignore: true)
  _$$VibrationSettingsImplCopyWith<_$VibrationSettingsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UserPreferences _$UserPreferencesFromJson(Map<String, dynamic> json) {
  return _UserPreferences.fromJson(json);
}

/// @nodoc
mixin _$UserPreferences {
  bool get notificationsEnabled => throw _privateConstructorUsedError;
  bool get communitySeismographEnabled => throw _privateConstructorUsedError;
  List<NotificationProfile> get notificationProfiles =>
      throw _privateConstructorUsedError;
  int get themeMode => throw _privateConstructorUsedError;
  TimeWindow get timeWindow => throw _privateConstructorUsedError;
  String get earthquakeProvider => throw _privateConstructorUsedError;
  List<String> get subscribedTopics => throw _privateConstructorUsedError;
  VibrationSettings get successVibration => throw _privateConstructorUsedError;
  VibrationSettings get errorVibration => throw _privateConstructorUsedError;
  double get mapButtonScale => throw _privateConstructorUsedError;
  double get smallMarkerScale => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UserPreferencesCopyWith<UserPreferences> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserPreferencesCopyWith<$Res> {
  factory $UserPreferencesCopyWith(
          UserPreferences value, $Res Function(UserPreferences) then) =
      _$UserPreferencesCopyWithImpl<$Res, UserPreferences>;
  @useResult
  $Res call(
      {bool notificationsEnabled,
      bool communitySeismographEnabled,
      List<NotificationProfile> notificationProfiles,
      int themeMode,
      TimeWindow timeWindow,
      String earthquakeProvider,
      List<String> subscribedTopics,
      VibrationSettings successVibration,
      VibrationSettings errorVibration,
      double mapButtonScale,
      double smallMarkerScale});

  $VibrationSettingsCopyWith<$Res> get successVibration;
  $VibrationSettingsCopyWith<$Res> get errorVibration;
}

/// @nodoc
class _$UserPreferencesCopyWithImpl<$Res, $Val extends UserPreferences>
    implements $UserPreferencesCopyWith<$Res> {
  _$UserPreferencesCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? notificationsEnabled = null,
    Object? communitySeismographEnabled = null,
    Object? notificationProfiles = null,
    Object? themeMode = null,
    Object? timeWindow = null,
    Object? earthquakeProvider = null,
    Object? subscribedTopics = null,
    Object? successVibration = null,
    Object? errorVibration = null,
    Object? mapButtonScale = null,
    Object? smallMarkerScale = null,
  }) {
    return _then(_value.copyWith(
      notificationsEnabled: null == notificationsEnabled
          ? _value.notificationsEnabled
          : notificationsEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      communitySeismographEnabled: null == communitySeismographEnabled
          ? _value.communitySeismographEnabled
          : communitySeismographEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      notificationProfiles: null == notificationProfiles
          ? _value.notificationProfiles
          : notificationProfiles // ignore: cast_nullable_to_non_nullable
              as List<NotificationProfile>,
      themeMode: null == themeMode
          ? _value.themeMode
          : themeMode // ignore: cast_nullable_to_non_nullable
              as int,
      timeWindow: null == timeWindow
          ? _value.timeWindow
          : timeWindow // ignore: cast_nullable_to_non_nullable
              as TimeWindow,
      earthquakeProvider: null == earthquakeProvider
          ? _value.earthquakeProvider
          : earthquakeProvider // ignore: cast_nullable_to_non_nullable
              as String,
      subscribedTopics: null == subscribedTopics
          ? _value.subscribedTopics
          : subscribedTopics // ignore: cast_nullable_to_non_nullable
              as List<String>,
      successVibration: null == successVibration
          ? _value.successVibration
          : successVibration // ignore: cast_nullable_to_non_nullable
              as VibrationSettings,
      errorVibration: null == errorVibration
          ? _value.errorVibration
          : errorVibration // ignore: cast_nullable_to_non_nullable
              as VibrationSettings,
      mapButtonScale: null == mapButtonScale
          ? _value.mapButtonScale
          : mapButtonScale // ignore: cast_nullable_to_non_nullable
              as double,
      smallMarkerScale: null == smallMarkerScale
          ? _value.smallMarkerScale
          : smallMarkerScale // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $VibrationSettingsCopyWith<$Res> get successVibration {
    return $VibrationSettingsCopyWith<$Res>(_value.successVibration, (value) {
      return _then(_value.copyWith(successVibration: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $VibrationSettingsCopyWith<$Res> get errorVibration {
    return $VibrationSettingsCopyWith<$Res>(_value.errorVibration, (value) {
      return _then(_value.copyWith(errorVibration: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$UserPreferencesImplCopyWith<$Res>
    implements $UserPreferencesCopyWith<$Res> {
  factory _$$UserPreferencesImplCopyWith(_$UserPreferencesImpl value,
          $Res Function(_$UserPreferencesImpl) then) =
      __$$UserPreferencesImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool notificationsEnabled,
      bool communitySeismographEnabled,
      List<NotificationProfile> notificationProfiles,
      int themeMode,
      TimeWindow timeWindow,
      String earthquakeProvider,
      List<String> subscribedTopics,
      VibrationSettings successVibration,
      VibrationSettings errorVibration,
      double mapButtonScale,
      double smallMarkerScale});

  @override
  $VibrationSettingsCopyWith<$Res> get successVibration;
  @override
  $VibrationSettingsCopyWith<$Res> get errorVibration;
}

/// @nodoc
class __$$UserPreferencesImplCopyWithImpl<$Res>
    extends _$UserPreferencesCopyWithImpl<$Res, _$UserPreferencesImpl>
    implements _$$UserPreferencesImplCopyWith<$Res> {
  __$$UserPreferencesImplCopyWithImpl(
      _$UserPreferencesImpl _value, $Res Function(_$UserPreferencesImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? notificationsEnabled = null,
    Object? communitySeismographEnabled = null,
    Object? notificationProfiles = null,
    Object? themeMode = null,
    Object? timeWindow = null,
    Object? earthquakeProvider = null,
    Object? subscribedTopics = null,
    Object? successVibration = null,
    Object? errorVibration = null,
    Object? mapButtonScale = null,
    Object? smallMarkerScale = null,
  }) {
    return _then(_$UserPreferencesImpl(
      notificationsEnabled: null == notificationsEnabled
          ? _value.notificationsEnabled
          : notificationsEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      communitySeismographEnabled: null == communitySeismographEnabled
          ? _value.communitySeismographEnabled
          : communitySeismographEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      notificationProfiles: null == notificationProfiles
          ? _value._notificationProfiles
          : notificationProfiles // ignore: cast_nullable_to_non_nullable
              as List<NotificationProfile>,
      themeMode: null == themeMode
          ? _value.themeMode
          : themeMode // ignore: cast_nullable_to_non_nullable
              as int,
      timeWindow: null == timeWindow
          ? _value.timeWindow
          : timeWindow // ignore: cast_nullable_to_non_nullable
              as TimeWindow,
      earthquakeProvider: null == earthquakeProvider
          ? _value.earthquakeProvider
          : earthquakeProvider // ignore: cast_nullable_to_non_nullable
              as String,
      subscribedTopics: null == subscribedTopics
          ? _value._subscribedTopics
          : subscribedTopics // ignore: cast_nullable_to_non_nullable
              as List<String>,
      successVibration: null == successVibration
          ? _value.successVibration
          : successVibration // ignore: cast_nullable_to_non_nullable
              as VibrationSettings,
      errorVibration: null == errorVibration
          ? _value.errorVibration
          : errorVibration // ignore: cast_nullable_to_non_nullable
              as VibrationSettings,
      mapButtonScale: null == mapButtonScale
          ? _value.mapButtonScale
          : mapButtonScale // ignore: cast_nullable_to_non_nullable
              as double,
      smallMarkerScale: null == smallMarkerScale
          ? _value.smallMarkerScale
          : smallMarkerScale // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserPreferencesImpl implements _UserPreferences {
  const _$UserPreferencesImpl(
      {this.notificationsEnabled = true,
      this.communitySeismographEnabled = false,
      final List<NotificationProfile> notificationProfiles = const [],
      this.themeMode = 0,
      this.timeWindow = TimeWindow.day,
      this.earthquakeProvider = 'usgs',
      final List<String> subscribedTopics = const [],
      this.successVibration = const VibrationSettings(),
      this.errorVibration = const VibrationSettings(duration: 100, pattern: 3),
      this.mapButtonScale = 1.0,
      this.smallMarkerScale = 1.0})
      : _notificationProfiles = notificationProfiles,
        _subscribedTopics = subscribedTopics;

  factory _$UserPreferencesImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserPreferencesImplFromJson(json);

  @override
  @JsonKey()
  final bool notificationsEnabled;
  @override
  @JsonKey()
  final bool communitySeismographEnabled;
  final List<NotificationProfile> _notificationProfiles;
  @override
  @JsonKey()
  List<NotificationProfile> get notificationProfiles {
    if (_notificationProfiles is EqualUnmodifiableListView)
      return _notificationProfiles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_notificationProfiles);
  }

  @override
  @JsonKey()
  final int themeMode;
  @override
  @JsonKey()
  final TimeWindow timeWindow;
  @override
  @JsonKey()
  final String earthquakeProvider;
  final List<String> _subscribedTopics;
  @override
  @JsonKey()
  List<String> get subscribedTopics {
    if (_subscribedTopics is EqualUnmodifiableListView)
      return _subscribedTopics;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_subscribedTopics);
  }

  @override
  @JsonKey()
  final VibrationSettings successVibration;
  @override
  @JsonKey()
  final VibrationSettings errorVibration;
  @override
  @JsonKey()
  final double mapButtonScale;
  @override
  @JsonKey()
  final double smallMarkerScale;

  @override
  String toString() {
    return 'UserPreferences(notificationsEnabled: $notificationsEnabled, communitySeismographEnabled: $communitySeismographEnabled, notificationProfiles: $notificationProfiles, themeMode: $themeMode, timeWindow: $timeWindow, earthquakeProvider: $earthquakeProvider, subscribedTopics: $subscribedTopics, successVibration: $successVibration, errorVibration: $errorVibration, mapButtonScale: $mapButtonScale, smallMarkerScale: $smallMarkerScale)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserPreferencesImpl &&
            (identical(other.notificationsEnabled, notificationsEnabled) ||
                other.notificationsEnabled == notificationsEnabled) &&
            (identical(other.communitySeismographEnabled,
                    communitySeismographEnabled) ||
                other.communitySeismographEnabled ==
                    communitySeismographEnabled) &&
            const DeepCollectionEquality()
                .equals(other._notificationProfiles, _notificationProfiles) &&
            (identical(other.themeMode, themeMode) ||
                other.themeMode == themeMode) &&
            (identical(other.timeWindow, timeWindow) ||
                other.timeWindow == timeWindow) &&
            (identical(other.earthquakeProvider, earthquakeProvider) ||
                other.earthquakeProvider == earthquakeProvider) &&
            const DeepCollectionEquality()
                .equals(other._subscribedTopics, _subscribedTopics) &&
            (identical(other.successVibration, successVibration) ||
                other.successVibration == successVibration) &&
            (identical(other.errorVibration, errorVibration) ||
                other.errorVibration == errorVibration) &&
            (identical(other.mapButtonScale, mapButtonScale) ||
                other.mapButtonScale == mapButtonScale) &&
            (identical(other.smallMarkerScale, smallMarkerScale) ||
                other.smallMarkerScale == smallMarkerScale));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      notificationsEnabled,
      communitySeismographEnabled,
      const DeepCollectionEquality().hash(_notificationProfiles),
      themeMode,
      timeWindow,
      earthquakeProvider,
      const DeepCollectionEquality().hash(_subscribedTopics),
      successVibration,
      errorVibration,
      mapButtonScale,
      smallMarkerScale);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UserPreferencesImplCopyWith<_$UserPreferencesImpl> get copyWith =>
      __$$UserPreferencesImplCopyWithImpl<_$UserPreferencesImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserPreferencesImplToJson(
      this,
    );
  }
}

abstract class _UserPreferences implements UserPreferences {
  const factory _UserPreferences(
      {final bool notificationsEnabled,
      final bool communitySeismographEnabled,
      final List<NotificationProfile> notificationProfiles,
      final int themeMode,
      final TimeWindow timeWindow,
      final String earthquakeProvider,
      final List<String> subscribedTopics,
      final VibrationSettings successVibration,
      final VibrationSettings errorVibration,
      final double mapButtonScale,
      final double smallMarkerScale}) = _$UserPreferencesImpl;

  factory _UserPreferences.fromJson(Map<String, dynamic> json) =
      _$UserPreferencesImpl.fromJson;

  @override
  bool get notificationsEnabled;
  @override
  bool get communitySeismographEnabled;
  @override
  List<NotificationProfile> get notificationProfiles;
  @override
  int get themeMode;
  @override
  TimeWindow get timeWindow;
  @override
  String get earthquakeProvider;
  @override
  List<String> get subscribedTopics;
  @override
  VibrationSettings get successVibration;
  @override
  VibrationSettings get errorVibration;
  @override
  double get mapButtonScale;
  @override
  double get smallMarkerScale;
  @override
  @JsonKey(ignore: true)
  _$$UserPreferencesImplCopyWith<_$UserPreferencesImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
