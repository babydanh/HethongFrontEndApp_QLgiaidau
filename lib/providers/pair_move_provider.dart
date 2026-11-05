import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_pair_move_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/pair_move_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final pairMoveRepositoryProvider = Provider<PairMoveRepository>(
  (ref) => ApiPairMoveRepository(ref.watch(dioClientProvider)),
);
