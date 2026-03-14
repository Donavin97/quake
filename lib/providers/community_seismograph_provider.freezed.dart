// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'community_seismograph_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$CommunitySeismographState {
  bool get isRecording => throw _privateConstructorUsedError;
  bool get isEnabled => throw _privateConstructorUsedError;
  bool get isSettling => throw _privateConstructorUsedError;
  DateTime? get lastHeartbeat => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $CommunitySeismographStateCopyWith<CommunitySeismographState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CommunitySeismographStateCopyWith<$Res> {
  factory $CommunitySeismographStateCopyWith(CommunitySeismographState value,
          $Res Function(CommunitySeismographState) then) =
      _$CommunitySeismographStateCopyWithImpl<$Res, CommunitySeismographState>;
  @useResult
  $Res call(
      {bool isRecording,
      bool isEnabled,
      bool isSettling,
      DateTime? lastHeartbeat});
}

/// @nodoc
class _$CommunitySeismographStateCopyWithImpl<$Res,
        $Val extends CommunitySeismographState>
    implements $CommunitySeismographStateCopyWith<$Res> {
  _$CommunitySeismographStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isRecording = null,
    Object? isEnabled = null,
    Object? isSettling = null,
    Object? lastHeartbeat = freezed,
  }) {
    return _then(_value.copyWith(
      isRecording: null == isRecording
          ? _value.isRecording
          : isRecording // ignore: cast_nullable_to_non_nullable
              as bool,
      isEnabled: null == isEnabled
          ? _value.isEnabled
          : isEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      isSettling: null == isSettling
          ? _value.isSettling
          : isSettling // ignore: cast_nullable_to_non_nullable
              as bool,
      lastHeartbeat: freezed == lastHeartbeat
          ? _value.lastHeartbeat
          : lastHeartbeat // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CommunitySeismographStateImplCopyWith<$Res>
    implements $CommunitySeismographStateCopyWith<$Res> {
  factory _$$CommunitySeismographStateImplCopyWith(
          _$CommunitySeismographStateImpl value,
          $Res Function(_$CommunitySeismographStateImpl) then) =
      __$$CommunitySeismographStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool isRecording,
      bool isEnabled,
      bool isSettling,
      DateTime? lastHeartbeat});
}

/// @nodoc
class __$$CommunitySeismographStateImplCopyWithImpl<$Res>
    extends _$CommunitySeismographStateCopyWithImpl<$Res,
        _$CommunitySeismographStateImpl>
    implements _$$CommunitySeismographStateImplCopyWith<$Res> {
  __$$CommunitySeismographStateImplCopyWithImpl(
      _$CommunitySeismographStateImpl _value,
      $Res Function(_$CommunitySeismographStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isRecording = null,
    Object? isEnabled = null,
    Object? isSettling = null,
    Object? lastHeartbeat = freezed,
  }) {
    return _then(_$CommunitySeismographStateImpl(
      isRecording: null == isRecording
          ? _value.isRecording
          : isRecording // ignore: cast_nullable_to_non_nullable
              as bool,
      isEnabled: null == isEnabled
          ? _value.isEnabled
          : isEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      isSettling: null == isSettling
          ? _value.isSettling
          : isSettling // ignore: cast_nullable_to_non_nullable
              as bool,
      lastHeartbeat: freezed == lastHeartbeat
          ? _value.lastHeartbeat
          : lastHeartbeat // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc

class _$CommunitySeismographStateImpl implements _CommunitySeismographState {
  const _$CommunitySeismographStateImpl(
      {this.isRecording = false,
      this.isEnabled = false,
      this.isSettling = false,
      this.lastHeartbeat});

  @override
  @JsonKey()
  final bool isRecording;
  @override
  @JsonKey()
  final bool isEnabled;
  @override
  @JsonKey()
  final bool isSettling;
  @override
  final DateTime? lastHeartbeat;

  @override
  String toString() {
    return 'CommunitySeismographState(isRecording: $isRecording, isEnabled: $isEnabled, isSettling: $isSettling, lastHeartbeat: $lastHeartbeat)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CommunitySeismographStateImpl &&
            (identical(other.isRecording, isRecording) ||
                other.isRecording == isRecording) &&
            (identical(other.isEnabled, isEnabled) ||
                other.isEnabled == isEnabled) &&
            (identical(other.isSettling, isSettling) ||
                other.isSettling == isSettling) &&
            (identical(other.lastHeartbeat, lastHeartbeat) ||
                other.lastHeartbeat == lastHeartbeat));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, isRecording, isEnabled, isSettling, lastHeartbeat);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CommunitySeismographStateImplCopyWith<_$CommunitySeismographStateImpl>
      get copyWith => __$$CommunitySeismographStateImplCopyWithImpl<
          _$CommunitySeismographStateImpl>(this, _$identity);
}

abstract class _CommunitySeismographState implements CommunitySeismographState {
  const factory _CommunitySeismographState(
      {final bool isRecording,
      final bool isEnabled,
      final bool isSettling,
      final DateTime? lastHeartbeat}) = _$CommunitySeismographStateImpl;

  @override
  bool get isRecording;
  @override
  bool get isEnabled;
  @override
  bool get isSettling;
  @override
  DateTime? get lastHeartbeat;
  @override
  @JsonKey(ignore: true)
  _$$CommunitySeismographStateImplCopyWith<_$CommunitySeismographStateImpl>
      get copyWith => throw _privateConstructorUsedError;
}
