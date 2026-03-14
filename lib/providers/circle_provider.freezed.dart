// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'circle_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$CircleState {
  List<SafetyCircle> get circles => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $CircleStateCopyWith<CircleState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CircleStateCopyWith<$Res> {
  factory $CircleStateCopyWith(
          CircleState value, $Res Function(CircleState) then) =
      _$CircleStateCopyWithImpl<$Res, CircleState>;
  @useResult
  $Res call({List<SafetyCircle> circles, bool isLoading});
}

/// @nodoc
class _$CircleStateCopyWithImpl<$Res, $Val extends CircleState>
    implements $CircleStateCopyWith<$Res> {
  _$CircleStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? circles = null,
    Object? isLoading = null,
  }) {
    return _then(_value.copyWith(
      circles: null == circles
          ? _value.circles
          : circles // ignore: cast_nullable_to_non_nullable
              as List<SafetyCircle>,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CircleStateImplCopyWith<$Res>
    implements $CircleStateCopyWith<$Res> {
  factory _$$CircleStateImplCopyWith(
          _$CircleStateImpl value, $Res Function(_$CircleStateImpl) then) =
      __$$CircleStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<SafetyCircle> circles, bool isLoading});
}

/// @nodoc
class __$$CircleStateImplCopyWithImpl<$Res>
    extends _$CircleStateCopyWithImpl<$Res, _$CircleStateImpl>
    implements _$$CircleStateImplCopyWith<$Res> {
  __$$CircleStateImplCopyWithImpl(
      _$CircleStateImpl _value, $Res Function(_$CircleStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? circles = null,
    Object? isLoading = null,
  }) {
    return _then(_$CircleStateImpl(
      circles: null == circles
          ? _value._circles
          : circles // ignore: cast_nullable_to_non_nullable
              as List<SafetyCircle>,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$CircleStateImpl implements _CircleState {
  const _$CircleStateImpl(
      {final List<SafetyCircle> circles = const [], this.isLoading = false})
      : _circles = circles;

  final List<SafetyCircle> _circles;
  @override
  @JsonKey()
  List<SafetyCircle> get circles {
    if (_circles is EqualUnmodifiableListView) return _circles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_circles);
  }

  @override
  @JsonKey()
  final bool isLoading;

  @override
  String toString() {
    return 'CircleState(circles: $circles, isLoading: $isLoading)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CircleStateImpl &&
            const DeepCollectionEquality().equals(other._circles, _circles) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, const DeepCollectionEquality().hash(_circles), isLoading);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CircleStateImplCopyWith<_$CircleStateImpl> get copyWith =>
      __$$CircleStateImplCopyWithImpl<_$CircleStateImpl>(this, _$identity);
}

abstract class _CircleState implements CircleState {
  const factory _CircleState(
      {final List<SafetyCircle> circles,
      final bool isLoading}) = _$CircleStateImpl;

  @override
  List<SafetyCircle> get circles;
  @override
  bool get isLoading;
  @override
  @JsonKey(ignore: true)
  _$$CircleStateImplCopyWith<_$CircleStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
