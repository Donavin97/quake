import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/circle.dart';
import '../models/circle_member.dart';
import 'service_providers.dart';

part 'circle_provider.freezed.dart';
part 'circle_provider.g.dart';

@freezed
class CircleState with _$CircleState {
  const factory CircleState({
    @Default([]) List<SafetyCircle> circles,
    @Default(false) bool isLoading,
  }) = _CircleState;
}

@riverpod
class Circle extends _$Circle {
  @override
  CircleState build() {
    _init();
    return const CircleState();
  }

  void _init() {
    final circleService = ref.read(circleServiceProvider);
    circleService.getMyCircles().listen((updatedCircles) {
      state = state.copyWith(circles: updatedCircles);
    });
  }

  Future<void> createCircle(String name) async {
    state = state.copyWith(isLoading: true);
    try {
      final circleService = ref.read(circleServiceProvider);
      await circleService.createCircle(name);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> joinCircle(String inviteCode) async {
    state = state.copyWith(isLoading: true);
    try {
      final circleService = ref.read(circleServiceProvider);
      await circleService.joinCircle(inviteCode);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> leaveCircle(String circleId) async {
    state = state.copyWith(isLoading: true);
    try {
      final circleService = ref.read(circleServiceProvider);
      await circleService.leaveCircle(circleId);
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> updateSafetyStatus(String circleId, SafetyStatus status, {String? earthquakeId, double? lat, double? lon}) async {
    final circleService = ref.read(circleServiceProvider);
    await circleService.updateSafetyStatus(circleId, status, earthquakeId: earthquakeId, lat: lat, lon: lon);
  }
}
