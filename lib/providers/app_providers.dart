import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/data/models/match_model.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';

export 'package:app_quanly_giaidau/core/di/di.dart';
export 'query_providers.dart';

final liveMatchesProvider = FutureProvider<List<MatchModel>>((ref) async {
  final matchRepo = ref.watch(matchRepositoryProvider);
  return await matchRepo.getMatches(status: "ONGOING", publicOnly: true);
});
