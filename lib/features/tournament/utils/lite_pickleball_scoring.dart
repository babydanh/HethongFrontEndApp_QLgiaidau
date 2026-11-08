import 'package:app_quanly_giaidau/core/config/app_constants.dart';

/// Scoring rule a Lite pickleball tournament is created with
/// (`pickleballScoring` of `POST /tournaments/lite`). Side-out is the default,
/// the same as the backend when the field is missing.
enum LitePickleballScoring {
  sideOut('SIDE_OUT'),
  rally('RALLY');

  const LitePickleballScoring(this.apiValue);
  final String apiValue;
}

/// The request field for [sport]; empty for every sport but pickleball, so no
/// other sport ever sends `pickleballScoring`.
Map<String, dynamic> litePickleballScoringPayload({
  required String sport,
  required LitePickleballScoring scoring,
}) => sport == AppConstants.sportPickleball
    ? {'pickleballScoring': scoring.apiValue}
    : const {};
