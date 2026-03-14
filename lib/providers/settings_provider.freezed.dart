// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'settings_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$SettingsState {
  bool get isLoaded => throw _privateConstructorUsedError;
  UserPreferences get userPreferences => throw _privateConstructorUsedError;
  NotificationProfile? get activeNotificationProfile =>
      throw _privateConstructorUsedError;
  ThemeMode get themeMode => throw _privateConstructorUsedError;
  TimeWindow get timeWindow => throw _privateConstructorUsedError;
  String get earthquakeProvider => throw _privateConstructorUsedError;
  Set<String> get subscribedTopics => throw _privateConstructorUsedError;
  bool get showPlates => throw _privateConstructorUsedError;
  bool get showFaults => throw _privateConstructorUsedError;
  bool get showFeltRadius => throw _privateConstructorUsedError;
  double get mapButtonScale => throw _privateConstructorUsedError;
  double get smallMarkerScale => throw _privateConstructorUsedError;
  DateTime? get lastSynced => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $SettingsStateCopyWith<SettingsState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SettingsStateCopyWith<$Res> {
  factory $SettingsStateCopyWith(
          SettingsState value, $Res Function(SettingsState) then) =
      _$SettingsStateCopyWithImpl<$Res, SettingsState>;
  @useResult
  $Res call(
      {bool isLoaded,
      UserPreferences userPreferences,
      NotificationProfile? activeNotificationProfile,
      ThemeMode themeMode,
      TimeWindow timeWindow,
      String earthquakeProvider,
      Set<String> subscribedTopics,
      bool showPlates,
      bool showFaults,
      bool showFeltRadius,
      double mapButtonScale,
      double smallMarkerScale,
      DateTime? lastSynced});

  $UserPreferencesCopyWith<$Res> get userPreferences;
  $NotificationProfileCopyWith<$Res>? get activeNotificationProfile;
}

/// @nodoc
class _$SettingsStateCopyWithImpl<$Res, $Val extends SettingsState>
    implements $SettingsStateCopyWith<$Res> {
  _$SettingsStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoaded = null,
    Object? userPreferences = null,
    Object? activeNotificationProfile = freezed,
    Object? themeMode = null,
    Object? timeWindow = null,
    Object? earthquakeProvider = null,
    Object? subscribedTopics = null,
    Object? showPlates = null,
    Object? showFaults = null,
    Object? showFeltRadius = null,
    Object? mapButtonScale = null,
    Object? smallMarkerScale = null,
    Object? lastSynced = freezed,
  }) {
    return _then(_value.copyWith(
      isLoaded: null == isLoaded
          ? _value.isLoaded
          : isLoaded // ignore: cast_nullable_to_non_nullable
              as bool,
      userPreferences: null == userPreferences
          ? _value.userPreferences
          : userPreferences // ignore: cast_nullable_to_non_nullable
              as UserPreferences,
      activeNotificationProfile: freezed == activeNotificationProfile
          ? _value.activeNotificationProfile
          : activeNotificationProfile // ignore: cast_nullable_to_non_nullable
              as NotificationProfile?,
      themeMode: null == themeMode
          ? _value.themeMode
          : themeMode // ignore: cast_nullable_to_non_nullable
              as ThemeMode,
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
              as Set<String>,
      showPlates: null == showPlates
          ? _value.showPlates
          : showPlates // ignore: cast_nullable_to_non_nullable
              as bool,
      showFaults: null == showFaults
          ? _value.showFaults
          : showFaults // ignore: cast_nullable_to_non_nullable
              as bool,
      showFeltRadius: null == showFeltRadius
          ? _value.showFeltRadius
          : showFeltRadius // ignore: cast_nullable_to_non_nullable
              as bool,
      mapButtonScale: null == mapButtonScale
          ? _value.mapButtonScale
          : mapButtonScale // ignore: cast_nullable_to_non_nullable
              as double,
      smallMarkerScale: null == smallMarkerScale
          ? _value.smallMarkerScale
          : smallMarkerScale // ignore: cast_nullable_to_non_nullable
              as double,
      lastSynced: freezed == lastSynced
          ? _value.lastSynced
          : lastSynced // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $UserPreferencesCopyWith<$Res> get userPreferences {
    return $UserPreferencesCopyWith<$Res>(_value.userPreferences, (value) {
      return _then(_value.copyWith(userPreferences: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $NotificationProfileCopyWith<$Res>? get activeNotificationProfile {
    if (_value.activeNotificationProfile == null) {
      return null;
    }

    return $NotificationProfileCopyWith<$Res>(_value.activeNotificationProfile!,
        (value) {
      return _then(_value.copyWith(activeNotificationProfile: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$SettingsStateImplCopyWith<$Res>
    implements $SettingsStateCopyWith<$Res> {
  factory _$$SettingsStateImplCopyWith(
          _$SettingsStateImpl value, $Res Function(_$SettingsStateImpl) then) =
      __$$SettingsStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool isLoaded,
      UserPreferences userPreferences,
      NotificationProfile? activeNotificationProfile,
      ThemeMode themeMode,
      TimeWindow timeWindow,
      String earthquakeProvider,
      Set<String> subscribedTopics,
      bool showPlates,
      bool showFaults,
      bool showFeltRadius,
      double mapButtonScale,
      double smallMarkerScale,
      DateTime? lastSynced});

  @override
  $UserPreferencesCopyWith<$Res> get userPreferences;
  @override
  $NotificationProfileCopyWith<$Res>? get activeNotificationProfile;
}

/// @nodoc
class __$$SettingsStateImplCopyWithImpl<$Res>
    extends _$SettingsStateCopyWithImpl<$Res, _$SettingsStateImpl>
    implements _$$SettingsStateImplCopyWith<$Res> {
  __$$SettingsStateImplCopyWithImpl(
      _$SettingsStateImpl _value, $Res Function(_$SettingsStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoaded = null,
    Object? userPreferences = null,
    Object? activeNotificationProfile = freezed,
    Object? themeMode = null,
    Object? timeWindow = null,
    Object? earthquakeProvider = null,
    Object? subscribedTopics = null,
    Object? showPlates = null,
    Object? showFaults = null,
    Object? showFeltRadius = null,
    Object? mapButtonScale = null,
    Object? smallMarkerScale = null,
    Object? lastSynced = freezed,
  }) {
    return _then(_$SettingsStateImpl(
      isLoaded: null == isLoaded
          ? _value.isLoaded
          : isLoaded // ignore: cast_nullable_to_non_nullable
              as bool,
      userPreferences: null == userPreferences
          ? _value.userPreferences
          : userPreferences // ignore: cast_nullable_to_non_nullable
              as UserPreferences,
      activeNotificationProfile: freezed == activeNotificationProfile
          ? _value.activeNotificationProfile
          : activeNotificationProfile // ignore: cast_nullable_to_non_nullable
              as NotificationProfile?,
      themeMode: null == themeMode
          ? _value.themeMode
          : themeMode // ignore: cast_nullable_to_non_nullable
              as ThemeMode,
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
              as Set<String>,
      showPlates: null == showPlates
          ? _value.showPlates
          : showPlates // ignore: cast_nullable_to_non_nullable
              as bool,
      showFaults: null == showFaults
          ? _value.showFaults
          : showFaults // ignore: cast_nullable_to_non_nullable
              as bool,
      showFeltRadius: null == showFeltRadius
          ? _value.showFeltRadius
          : showFeltRadius // ignore: cast_nullable_to_non_nullable
              as bool,
      mapButtonScale: null == mapButtonScale
          ? _value.mapButtonScale
          : mapButtonScale // ignore: cast_nullable_to_non_nullable
              as double,
      smallMarkerScale: null == smallMarkerScale
          ? _value.smallMarkerScale
          : smallMarkerScale // ignore: cast_nullable_to_non_nullable
              as double,
      lastSynced: freezed == lastSynced
          ? _value.lastSynced
          : lastSynced // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc

class _$SettingsStateImpl implements _SettingsState {
  const _$SettingsStateImpl(
      {this.isLoaded = false,
      this.userPreferences = const UserPreferences(),
      this.activeNotificationProfile,
      this.themeMode = ThemeMode.system,
      this.timeWindow = TimeWindow.day,
      this.earthquakeProvider = 'usgs',
      final Set<String> subscribedTopics = const {},
      this.showPlates = true,
      this.showFaults = true,
      this.showFeltRadius = true,
      this.mapButtonScale = 1.0,
      this.smallMarkerScale = 1.0,
      this.lastSynced})
      : _subscribedTopics = subscribedTopics;

  @override
  @JsonKey()
  final bool isLoaded;
  @override
  @JsonKey()
  final UserPreferences userPreferences;
  @override
  final NotificationProfile? activeNotificationProfile;
  @override
  @JsonKey()
  final ThemeMode themeMode;
  @override
  @JsonKey()
  final TimeWindow timeWindow;
  @override
  @JsonKey()
  final String earthquakeProvider;
  final Set<String> _subscribedTopics;
  @override
  @JsonKey()
  Set<String> get subscribedTopics {
    if (_subscribedTopics is EqualUnmodifiableSetView) return _subscribedTopics;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_subscribedTopics);
  }

  @override
  @JsonKey()
  final bool showPlates;
  @override
  @JsonKey()
  final bool showFaults;
  @override
  @JsonKey()
  final bool showFeltRadius;
  @override
  @JsonKey()
  final double mapButtonScale;
  @override
  @JsonKey()
  final double smallMarkerScale;
  @override
  final DateTime? lastSynced;

  @override
  String toString() {
    return 'SettingsState(isLoaded: $isLoaded, userPreferences: $userPreferences, activeNotificationProfile: $activeNotificationProfile, themeMode: $themeMode, timeWindow: $timeWindow, earthquakeProvider: $earthquakeProvider, subscribedTopics: $subscribedTopics, showPlates: $showPlates, showFaults: $showFaults, showFeltRadius: $showFeltRadius, mapButtonScale: $mapButtonScale, smallMarkerScale: $smallMarkerScale, lastSynced: $lastSynced)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SettingsStateImpl &&
            (identical(other.isLoaded, isLoaded) ||
                other.isLoaded == isLoaded) &&
            (identical(other.userPreferences, userPreferences) ||
                other.userPreferences == userPreferences) &&
            (identical(other.activeNotificationProfile,
                    activeNotificationProfile) ||
                other.activeNotificationProfile == activeNotificationProfile) &&
            (identical(other.themeMode, themeMode) ||
                other.themeMode == themeMode) &&
            (identical(other.timeWindow, timeWindow) ||
                other.timeWindow == timeWindow) &&
            (identical(other.earthquakeProvider, earthquakeProvider) ||
                other.earthquakeProvider == earthquakeProvider) &&
            const DeepCollectionEquality()
                .equals(other._subscribedTopics, _subscribedTopics) &&
            (identical(other.showPlates, showPlates) ||
                other.showPlates == showPlates) &&
            (identical(other.showFaults, showFaults) ||
                other.showFaults == showFaults) &&
            (identical(other.showFeltRadius, showFeltRadius) ||
                other.showFeltRadius == showFeltRadius) &&
            (identical(other.mapButtonScale, mapButtonScale) ||
                other.mapButtonScale == mapButtonScale) &&
            (identical(other.smallMarkerScale, smallMarkerScale) ||
                other.smallMarkerScale == smallMarkerScale) &&
            (identical(other.lastSynced, lastSynced) ||
                other.lastSynced == lastSynced));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      isLoaded,
      userPreferences,
      activeNotificationProfile,
      themeMode,
      timeWindow,
      earthquakeProvider,
      const DeepCollectionEquality().hash(_subscribedTopics),
      showPlates,
      showFaults,
      showFeltRadius,
      mapButtonScale,
      smallMarkerScale,
      lastSynced);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SettingsStateImplCopyWith<_$SettingsStateImpl> get copyWith =>
      __$$SettingsStateImplCopyWithImpl<_$SettingsStateImpl>(this, _$identity);
}

abstract class _SettingsState implements SettingsState {
  const factory _SettingsState(
      {final bool isLoaded,
      final UserPreferences userPreferences,
      final NotificationProfile? activeNotificationProfile,
      final ThemeMode themeMode,
      final TimeWindow timeWindow,
      final String earthquakeProvider,
      final Set<String> subscribedTopics,
      final bool showPlates,
      final bool showFaults,
      final bool showFeltRadius,
      final double mapButtonScale,
      final double smallMarkerScale,
      final DateTime? lastSynced}) = _$SettingsStateImpl;

  @override
  bool get isLoaded;
  @override
  UserPreferences get userPreferences;
  @override
  NotificationProfile? get activeNotificationProfile;
  @override
  ThemeMode get themeMode;
  @override
  TimeWindow get timeWindow;
  @override
  String get earthquakeProvider;
  @override
  Set<String> get subscribedTopics;
  @override
  bool get showPlates;
  @override
  bool get showFaults;
  @override
  bool get showFeltRadius;
  @override
  double get mapButtonScale;
  @override
  double get smallMarkerScale;
  @override
  DateTime? get lastSynced;
  @override
  @JsonKey(ignore: true)
  _$$SettingsStateImplCopyWith<_$SettingsStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
