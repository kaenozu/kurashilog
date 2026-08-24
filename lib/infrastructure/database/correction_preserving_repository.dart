import 'kurashilog_repository_impl.dart';

/// Production repository wired through [ResettableKurashilogRepository].
///
/// Correction preservation on cluster rebuild (exclusive exact-key-first
/// matching of labels and privacy modes, applied in a single INSERT batch)
/// lives in [KurashilogRepositoryImpl.replaceAllClusters]. This subclass
/// remains as the production wiring point and keeps the historical name.
class CorrectionPreservingRepository extends KurashilogRepositoryImpl {
  CorrectionPreservingRepository(super.database);
}
