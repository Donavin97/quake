// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'earthquake_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$EarthquakeState {
  List<Earthquake> get allEarthquakes => throw _privateConstructorUsedError;
  List<Earthquake> get displayEarthquakes => throw _privateConstructorUsedError;
  List<Earthquake> get archiveEarthquakes => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;
  DateTime? get lastUpdated => throw _privateConstructorUsedError;
  SortCriterion get sortCriterion => throw _privateConstructorUsedError;
  bool get isProcessing => throw _privateConstructorUsedError;
  bool get isInitializing => throw _privateConstructorUsedError;
  bool get isSearchingArchive => throw _privateConstructorUsedError;
  bool get isArchiveMode => throw _privateConstructorUsedError;
  NotificationProfile? get filterNotificationProfile =>
      throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $EarthquakeStateCopyWith<EarthquakeState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EarthquakeStateCopyWith<$Res> {
  factory $EarthquakeStateCopyWith(
          EarthquakeState value, $Res Function(EarthquakeState) then) =
      _$EarthquakeStateCopyWithImpl<$Res, EarthquakeState>;
  @useResult
  $Res call(
      {List<Earthquake> allEarthquakes,
      List<Earthquake> displayEarthquakes,
      List<Earthquake> archiveEarthquakes,
      String? error,
      DateTime? lastUpdated,
      SortCriterion sortCriterion,
      bool isProcessing,
      bool isInitializing,
      bool isSearchingArchive,
      bool isArchiveMode,
      NotificationProfile? filterNotificationProfile});

  $NotificationProfileCopyWith<$Res>? get filterNotificationProfile;
}

/// @nodoc
class _$EarthquakeStateCopyWithImpl<$Res, $Val extends EarthquakeState>
    implements $EarthquakeStateCopyWith<$Res> {
  _$EarthquakeStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? allEarthquakes = null,
    Object? displayEarthquakes = null,
    Object? archiveEarthquakes = null,
    Object? error = freezed,
    Object? lastUpdated = freezed,
    Object? sortCriterion = null,
    Object? isProcessing = null,
    Object? isInitializing = null,
    Object? isSearchingArchive = null,
    Object? isArchiveMode = null,
    Object? filterNotificationProfile = freezed,
  }) {
    return _then(_value.copyWith(
      allEarthquakes: null == allEarthquakes
          ? _value.allEarthquakes
          : allEarthquakes // ignore: cast_nullable_to_non_nullable
              as List<Earthquake>,
      displayEarthquakes: null == displayEarthquakes
          ? _value.displayEarthquakes
          : displayEarthquakes // ignore: cast_nullable_to_non_nullable
              as List<Earthquake>,
      archiveEarthquakes: null == archiveEarthquakes
          ? _value.archiveEarthquakes
          : archiveEarthquakes // ignore: cast_nullable_to_non_nullable
              as List<Earthquake>,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      lastUpdated: freezed == lastUpdated
          ? _value.lastUpdated
          : lastUpdated // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      sortCriterion: null == sortCriterion
          ? _value.sortCriterion
          : sortCriterion // ignore: cast_nullable_to_non_nullable
              as SortCriterion,
      isProcessing: null == isProcessing
          ? _value.isProcessing
          : isProcessing // ignore: cast_nullable_to_non_nullable
              as bool,
      isInitializing: null == isInitializing
          ? _value.isInitializing
          : isInitializing // ignore: cast_nullable_to_non_nullable
              as bool,
      isSearchingArchive: null == isSearchingArchive
          ? _value.isSearchingArchive
          : isSearchingArchive // ignore: cast_nullable_to_non_nullable
              as bool,
      isArchiveMode: null == isArchiveMode
          ? _value.isArchiveMode
          : isArchiveMode // ignore: cast_nullable_to_non_nullable
              as bool,
      filterNotificationProfile: freezed == filterNotificationProfile
          ? _value.filterNotificationProfile
          : filterNotificationProfile // ignore: cast_nullable_to_non_nullable
              as NotificationProfile?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $NotificationProfileCopyWith<$Res>? get filterNotificationProfile {
    if (_value.filterNotificationProfile == null) {
      return null;
    }

    return $NotificationProfileCopyWith<$Res>(_value.filterNotificationProfile!,
        (value) {
      return _then(_value.copyWith(filterNotificationProfile: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$EarthquakeStateImplCopyWith<$Res>
    implements $EarthquakeStateCopyWith<$Res> {
  factory _$$EarthquakeStateImplCopyWith(_$EarthquakeStateImpl value,
          $Res Function(_$EarthquakeStateImpl) then) =
      __$$EarthquakeStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<Earthquake> allEarthquakes,
      List<Earthquake> displayEarthquakes,
      List<Earthquake> archiveEarthquakes,
      String? error,
      DateTime? lastUpdated,
      SortCriterion sortCriterion,
      bool isProcessing,
      bool isInitializing,
      bool isSearchingArchive,
      bool isArchiveMode,
      NotificationProfile? filterNotificationProfile});

  @override
  $NotificationProfileCopyWith<$Res>? get filterNotificationProfile;
}

/// @nodoc
class __$$EarthquakeStateImplCopyWithImpl<$Res>
    extends _$EarthquakeStateCopyWithImpl<$Res, _$EarthquakeStateImpl>
    implements _$$EarthquakeStateImplCopyWith<$Res> {
  __$$EarthquakeStateImplCopyWithImpl(
      _$EarthquakeStateImpl _value, $Res Function(_$EarthquakeStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? allEarthquakes = null,
    Object? displayEarthquakes = null,
    Object? archiveEarthquakes = null,
    Object? error = freezed,
    Object? lastUpdated = freezed,
    Object? sortCriterion = null,
    Object? isProcessing = null,
    Object? isInitializing = null,
    Object? isSearchingArchive = null,
    Object? isArchiveMode = null,
    Object? filterNotificationProfile = freezed,
  }) {
    return _then(_$EarthquakeStateImpl(
      allEarthquakes: null == allEarthquakes
          ? _value._allEarthquakes
          : allEarthquakes // ignore: cast_nullable_to_non_nullable
              as List<Earthquake>,
      displayEarthquakes: null == displayEarthquakes
          ? _value._displayEarthquakes
          : displayEarthquakes // ignore: cast_nullable_to_non_nullable
              as List<Earthquake>,
      archiveEarthquakes: null == archiveEarthquakes
          ? _value._archiveEarthquakes
          : archiveEarthquakes // ignore: cast_nullable_to_non_nullable
              as List<Earthquake>,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      lastUpdated: freezed == lastUpdated
          ? _value.lastUpdated
          : lastUpdated // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      sortCriterion: null == sortCriterion
          ? _value.sortCriterion
          : sortCriterion // ignore: cast_nullable_to_non_nullable
              as SortCriterion,
      isProcessing: null == isProcessing
          ? _value.isProcessing
          : isProcessing // ignore: cast_nullable_to_non_nullable
              as bool,
      isInitializing: null == isInitializing
          ? _value.isInitializing
          : isInitializing // ignore: cast_nullable_to_non_nullable
              as bool,
      isSearchingArchive: null == isSearchingArchive
          ? _value.isSearchingArchive
          : isSearchingArchive // ignore: cast_nullable_to_non_nullable
              as bool,
      isArchiveMode: null == isArchiveMode
          ? _value.isArchiveMode
          : isArchiveMode // ignore: cast_nullable_to_non_nullable
              as bool,
      filterNotificationProfile: freezed == filterNotificationProfile
          ? _value.filterNotificationProfile
          : filterNotificationProfile // ignore: cast_nullable_to_non_nullable
              as NotificationProfile?,
    ));
  }
}

/// @nodoc

class _$EarthquakeStateImpl
    with DiagnosticableTreeMixin
    implements _EarthquakeState {
  const _$EarthquakeStateImpl(
      {final List<Earthquake> allEarthquakes = const [],
      final List<Earthquake> displayEarthquakes = const [],
      final List<Earthquake> archiveEarthquakes = const [],
      this.error,
      this.lastUpdated,
      this.sortCriterion = SortCriterion.date,
      this.isProcessing = false,
      this.isInitializing = false,
      this.isSearchingArchive = false,
      this.isArchiveMode = false,
      this.filterNotificationProfile})
      : _allEarthquakes = allEarthquakes,
        _displayEarthquakes = displayEarthquakes,
        _archiveEarthquakes = archiveEarthquakes;

  final List<Earthquake> _allEarthquakes;
  @override
  @JsonKey()
  List<Earthquake> get allEarthquakes {
    if (_allEarthquakes is EqualUnmodifiableListView) return _allEarthquakes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_allEarthquakes);
  }

  final List<Earthquake> _displayEarthquakes;
  @override
  @JsonKey()
  List<Earthquake> get displayEarthquakes {
    if (_displayEarthquakes is EqualUnmodifiableListView)
      return _displayEarthquakes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_displayEarthquakes);
  }

  final List<Earthquake> _archiveEarthquakes;
  @override
  @JsonKey()
  List<Earthquake> get archiveEarthquakes {
    if (_archiveEarthquakes is EqualUnmodifiableListView)
      return _archiveEarthquakes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_archiveEarthquakes);
  }

  @override
  final String? error;
  @override
  final DateTime? lastUpdated;
  @override
  @JsonKey()
  final SortCriterion sortCriterion;
  @override
  @JsonKey()
  final bool isProcessing;
  @override
  @JsonKey()
  final bool isInitializing;
  @override
  @JsonKey()
  final bool isSearchingArchive;
  @override
  @JsonKey()
  final bool isArchiveMode;
  @override
  final NotificationProfile? filterNotificationProfile;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'EarthquakeState(allEarthquakes: $allEarthquakes, displayEarthquakes: $displayEarthquakes, archiveEarthquakes: $archiveEarthquakes, error: $error, lastUpdated: $lastUpdated, sortCriterion: $sortCriterion, isProcessing: $isProcessing, isInitializing: $isInitializing, isSearchingArchive: $isSearchingArchive, isArchiveMode: $isArchiveMode, filterNotificationProfile: $filterNotificationProfile)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'EarthquakeState'))
      ..add(DiagnosticsProperty('allEarthquakes', allEarthquakes))
      ..add(DiagnosticsProperty('displayEarthquakes', displayEarthquakes))
      ..add(DiagnosticsProperty('archiveEarthquakes', archiveEarthquakes))
      ..add(DiagnosticsProperty('error', error))
      ..add(DiagnosticsProperty('lastUpdated', lastUpdated))
      ..add(DiagnosticsProperty('sortCriterion', sortCriterion))
      ..add(DiagnosticsProperty('isProcessing', isProcessing))
      ..add(DiagnosticsProperty('isInitializing', isInitializing))
      ..add(DiagnosticsProperty('isSearchingArchive', isSearchingArchive))
      ..add(DiagnosticsProperty('isArchiveMode', isArchiveMode))
      ..add(DiagnosticsProperty(
          'filterNotificationProfile', filterNotificationProfile));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EarthquakeStateImpl &&
            const DeepCollectionEquality()
                .equals(other._allEarthquakes, _allEarthquakes) &&
            const DeepCollectionEquality()
                .equals(other._displayEarthquakes, _displayEarthquakes) &&
            const DeepCollectionEquality()
                .equals(other._archiveEarthquakes, _archiveEarthquakes) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.lastUpdated, lastUpdated) ||
                other.lastUpdated == lastUpdated) &&
            (identical(other.sortCriterion, sortCriterion) ||
                other.sortCriterion == sortCriterion) &&
            (identical(other.isProcessing, isProcessing) ||
                other.isProcessing == isProcessing) &&
            (identical(other.isInitializing, isInitializing) ||
                other.isInitializing == isInitializing) &&
            (identical(other.isSearchingArchive, isSearchingArchive) ||
                other.isSearchingArchive == isSearchingArchive) &&
            (identical(other.isArchiveMode, isArchiveMode) ||
                other.isArchiveMode == isArchiveMode) &&
            (identical(other.filterNotificationProfile,
                    filterNotificationProfile) ||
                other.filterNotificationProfile == filterNotificationProfile));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_allEarthquakes),
      const DeepCollectionEquality().hash(_displayEarthquakes),
      const DeepCollectionEquality().hash(_archiveEarthquakes),
      error,
      lastUpdated,
      sortCriterion,
      isProcessing,
      isInitializing,
      isSearchingArchive,
      isArchiveMode,
      filterNotificationProfile);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$EarthquakeStateImplCopyWith<_$EarthquakeStateImpl> get copyWith =>
      __$$EarthquakeStateImplCopyWithImpl<_$EarthquakeStateImpl>(
          this, _$identity);
}

abstract class _EarthquakeState implements EarthquakeState {
  const factory _EarthquakeState(
          {final List<Earthquake> allEarthquakes,
          final List<Earthquake> displayEarthquakes,
          final List<Earthquake> archiveEarthquakes,
          final String? error,
          final DateTime? lastUpdated,
          final SortCriterion sortCriterion,
          final bool isProcessing,
          final bool isInitializing,
          final bool isSearchingArchive,
          final bool isArchiveMode,
          final NotificationProfile? filterNotificationProfile}) =
      _$EarthquakeStateImpl;

  @override
  List<Earthquake> get allEarthquakes;
  @override
  List<Earthquake> get displayEarthquakes;
  @override
  List<Earthquake> get archiveEarthquakes;
  @override
  String? get error;
  @override
  DateTime? get lastUpdated;
  @override
  SortCriterion get sortCriterion;
  @override
  bool get isProcessing;
  @override
  bool get isInitializing;
  @override
  bool get isSearchingArchive;
  @override
  bool get isArchiveMode;
  @override
  NotificationProfile? get filterNotificationProfile;
  @override
  @JsonKey(ignore: true)
  _$$EarthquakeStateImplCopyWith<_$EarthquakeStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
