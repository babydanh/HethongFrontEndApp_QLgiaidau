/// The signed-in user's own international (DUPR) rating.
abstract class ExternalRatingRepository {
  /// Rating for [categoryId] + [matchType] (`SINGLES|DOUBLES|MIXED_DOUBLES`),
  /// or null when the user has none on file.
  Future<double?> getMyDuprRating({
    required String categoryId,
    required String matchType,
  });

  /// Self-declares (upserts) the rating.
  Future<void> saveMyDuprRating({
    required String categoryId,
    required String matchType,
    required double value,
  });
}
