import '../repositories/kurashilog_repository.dart';

/// 週の開始曜日。
enum WeekStart { sunday, monday }

/// 距離単位。
enum DistanceUnit { km, m }

/// アプリ設定（設計書 FR-120 設定）。
class AppSettingsData {
  const AppSettingsData({
    required this.weekStart,
    required this.distanceUnit,
  });

  final WeekStart weekStart;
  final DistanceUnit distanceUnit;
}

class SettingsUseCase {
  const SettingsUseCase({required this.repository});

  final KurashilogRepository repository;

  static const _weekStartKey = 'weekStart';
  static const _distanceUnitKey = 'distanceUnit';
  static const _onboardingDoneKey = 'onboardingDone';

  Future<AppSettingsData> load() async {
    final ws = await repository.getSetting(_weekStartKey);
    final du = await repository.getSetting(_distanceUnitKey);
    return AppSettingsData(
      weekStart: ws?.value == '0' ? WeekStart.sunday : WeekStart.monday,
      distanceUnit: du?.value == 'm' ? DistanceUnit.m : DistanceUnit.km,
    );
  }

  Future<void> setWeekStart(WeekStart value) =>
      repository.setSetting(_weekStartKey, value == WeekStart.sunday ? '0' : '1');

  Future<void> setDistanceUnit(DistanceUnit value) =>
      repository.setSetting(_distanceUnitKey, value == DistanceUnit.m ? 'm' : 'km');

  Future<bool> isOnboardingDone() async {
    final v = await repository.getSetting(_onboardingDoneKey);
    return v?.value == '1';
  }

  Future<void> setOnboardingDone() =>
      repository.setSetting(_onboardingDoneKey, '1');

  Future<void> resetOnboarding() =>
      repository.setSetting(_onboardingDoneKey, '0');
}
