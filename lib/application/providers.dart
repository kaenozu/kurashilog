import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../infrastructure/database/app_database_handle.dart';
import '../infrastructure/database/resettable_kurashilog_repository.dart';
import '../infrastructure/parsers/record_validator.dart';
import '../infrastructure/parsers/records_parser.dart';
import '../infrastructure/platform/app_platform.dart';
import '../infrastructure/platform/external_map_opener.dart';
import 'analysis/analysis_coordinator.dart';
import 'repositories/kurashilog_repository.dart';
import 'use_cases/dashboard_use_case.dart';
import 'use_cases/data_management_use_case.dart';
import 'use_cases/comparison_use_case.dart';
import 'use_cases/import_use_case.dart';
import 'use_cases/insight_evidence_use_case.dart';
import 'use_cases/milestones_use_case.dart';
import 'use_cases/places_use_case.dart';
import 'use_cases/settings_use_case.dart';

/// 起動時にmain()でoverrideする。
final appDatabaseHandleProvider = Provider<AppDatabaseHandle>(
  (ref) => throw UnimplementedError('main() で override してください'),
);

final repositoryProvider = Provider<KurashilogRepository>(
  (ref) => ResettableKurashilogRepository(ref.watch(appDatabaseHandleProvider)),
);

final platformProvider = Provider<AppPlatform>((ref) => AppPlatform());

final analysisCoordinatorProvider = Provider<AnalysisCoordinator>(
  (ref) => AnalysisCoordinator(repository: ref.watch(repositoryProvider)),
);

final importUseCaseProvider = Provider<ImportUseCase>(
  (ref) => ImportUseCase(
    repository: ref.watch(repositoryProvider),
    platform: ref.watch(platformProvider),
    analysis: ref.watch(analysisCoordinatorProvider),
    parser: const RecordsTimelineParser(),
    validator: const RecordValidator(),
  ),
);

final dashboardUseCaseProvider = Provider<DashboardUseCase>(
  (ref) => DashboardUseCase(
    repository: ref.watch(repositoryProvider),
    analysis: ref.watch(analysisCoordinatorProvider),
    settings: ref.watch(settingsUseCaseProvider),
  ),
);

final placesUseCaseProvider = Provider<PlacesUseCase>(
  (ref) => PlacesUseCase(
    repository: ref.watch(repositoryProvider),
    analysis: ref.watch(analysisCoordinatorProvider),
  ),
);

final comparisonUseCaseProvider = Provider<ComparisonUseCase>(
  (ref) => ComparisonUseCase(repository: ref.watch(repositoryProvider)),
);

final insightEvidenceUseCaseProvider = Provider<InsightEvidenceUseCase>(
  (ref) => InsightEvidenceUseCase(repository: ref.watch(repositoryProvider)),
);

final milestonesUseCaseProvider = Provider<MilestonesUseCase>(
  (ref) => MilestonesUseCase(repository: ref.watch(repositoryProvider)),
);

final settingsUseCaseProvider = Provider<SettingsUseCase>(
  (ref) => SettingsUseCase(repository: ref.watch(repositoryProvider)),
);

final appSettingsProvider = FutureProvider<AppSettingsData>(
  (ref) => ref.watch(settingsUseCaseProvider).load(),
);

final dataManagementUseCaseProvider = Provider<DataManagementUseCase>(
  (ref) => DataManagementUseCase(repository: ref.watch(repositoryProvider)),
);

final externalMapOpenerProvider = Provider<ExternalMapOpener>(
  (ref) => const ExternalMapOpener(),
);

/// ホームで表示する月（YYYY-MM）。
final selectedMonthProvider = StateProvider<String>(
  (ref) => _currentYearMonth(),
);

/// ダッシュボード再読込トリガー。
final dashboardRefreshProvider = StateProvider<int>((ref) => 0);

/// メインシェルのタブ（0: ホーム / 1: カレンダー / 2: 比較 / 3: 地点 / 4: 設定）。
final appTabProvider = StateProvider<int>((ref) => 0);

String _currentYearMonth() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}';
}
