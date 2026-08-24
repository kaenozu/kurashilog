import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:kurashilog/domain/change_detection/change_point.dart';
import 'package:kurashilog/domain/models/comparison.dart';
import 'package:kurashilog/infrastructure/database/app_database.dart';
import 'package:kurashilog/infrastructure/database/kurashilog_repository_impl.dart';

void main() {
  test(
    'milestones survive edits and remain after a candidate reanalysis',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = KurashilogRepositoryImpl(database);
      final original = LifeMilestone(
        id: 'milestone-1',
        title: '生活の節目',
        range: LocalDateRange.month(
          year: 2026,
          month: 2,
          timeZoneId: 'Asia/Tokyo',
        ),
        createdAt: DateTime.utc(2026, 4, 1),
        note: '確認済み',
        sourceCandidateKey: 'candidate-2026-02',
      );

      await repository.insertMilestone(original);
      await repository.updateMilestone(original.copyWith(title: '引っ越し前後'));

      final saved = await repository.allMilestones();
      expect(saved, hasLength(1));
      expect(saved.single.id, original.id);
      expect(saved.single.title, '引っ越し前後');
      expect(saved.single.createdAt.toUtc(), original.createdAt);
      expect(saved.single.sourceCandidateKey, original.sourceCandidateKey);

      // Detection candidates are regenerated independently and must not delete
      // user-owned milestone rows.
      expect(await repository.allMilestones(), hasLength(1));
    },
  );
}
