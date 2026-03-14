// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'safety_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$SafetyState {
  Earthquake? get pendingSafetyCheck => throw _privateConstructorUsedError;
  Set<String> get processedQuakes => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $SafetyStateCopyWith<SafetyState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SafetyStateCopyWith<$Res> {
  factory $SafetyStateCopyWith(
          SafetyState value, $Res Function(SafetyState) then) =
      _$SafetyStateCopyWithImpl<$Res, SafetyState>;
  @useResult
  $Res call({Earthquake? pendingSafetyCheck, Set<String> processedQuakes});
}

/// @nodoc
class _$SafetyStateCopyWithImpl<$Res, $Val extends SafetyState>
    implements $SafetyStateCopyWith<$Res> {
  _$SafetyStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? pendingSafetyCheck = freezed,
    Object? processedQuakes = null,
  }) {
    return _then(_value.copyWith(
      pendingSafetyCheck: freezed == pendingSafetyCheck
          ? _value.pendingSafetyCheck
          : pendingSafetyCheck // ignore: cast_nullable_to_non_nullable
              as Earthquake?,
      processedQuakes: null == processedQuakes
          ? _value.processedQuakes
          : processedQuakes // ignore: cast_nullable_to_non_nullable
              as Set<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SafetyStateImplCopyWith<$Res>
    implements $SafetyStateCopyWith<$Res> {
  factory _$$SafetyStateImplCopyWith(
          _$SafetyStateImpl value, $Res Function(_$SafetyStateImpl) then) =
      __$$SafetyStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({Earthquake? pendingSafetyCheck, Set<String> processedQuakes});
}

/// @nodoc
class __$$SafetyStateImplCopyWithImpl<$Res>
    extends _$SafetyStateCopyWithImpl<$Res, _$SafetyStateImpl>
    implements _$$SafetyStateImplCopyWith<$Res> {
  __$$SafetyStateImplCopyWithImpl(
      _$SafetyStateImpl _value, $Res Function(_$SafetyStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? pendingSafetyCheck = freezed,
    Object? processedQuakes = null,
  }) {
    return _then(_$SafetyStateImpl(
      pendingSafetyCheck: freezed == pendingSafetyCheck
          ? _value.pendingSafetyCheck
          : pendingSafetyCheck // ignore: cast_nullable_to_non_nullable
              as Earthquake?,
      processedQuakes: null == processedQuakes
          ? _value._processedQuakes
          : processedQuakes // ignore: cast_nullable_to_non_nullable
              as Set<String>,
    ));
  }
}

/// @nodoc

class _$SafetyStateImpl implements _SafetyState {
  const _$SafetyStateImpl(
      {this.pendingSafetyCheck, final Set<String> processedQuakes = const {}})
      : _processedQuakes = processedQuakes;

  @override
  final Earthquake? pendingSafetyCheck;
  final Set<String> _processedQuakes;
  @override
  @JsonKey()
  Set<String> get processedQuakes {
    if (_processedQuakes is EqualUnmodifiableSetView) return _processedQuakes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_processedQuakes);
  }

  @override
  String toString() {
    return 'SafetyState(pendingSafetyCheck: $pendingSafetyCheck, processedQuakes: $processedQuakes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SafetyStateImpl &&
            (identical(other.pendingSafetyCheck, pendingSafetyCheck) ||
                other.pendingSafetyCheck == pendingSafetyCheck) &&
            const DeepCollectionEquality()
                .equals(other._processedQuakes, _processedQuakes));
  }

  @override
  int get hashCode => Object.hash(runtimeType, pendingSafetyCheck,
      const DeepCollectionEquality().hash(_processedQuakes));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SafetyStateImplCopyWith<_$SafetyStateImpl> get copyWith =>
      __$$SafetyStateImplCopyWithImpl<_$SafetyStateImpl>(this, _$identity);
}

abstract class _SafetyState implements SafetyState {
  const factory _SafetyState(
      {final Earthquake? pendingSafetyCheck,
      final Set<String> processedQuakes}) = _$SafetyStateImpl;

  @override
  Earthquake? get pendingSafetyCheck;
  @override
  Set<String> get processedQuakes;
  @override
  @JsonKey(ignore: true)
  _$$SafetyStateImplCopyWith<_$SafetyStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
