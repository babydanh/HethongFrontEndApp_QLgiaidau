import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/data/repositories/api/api_match_recording_catalog_repository.dart';
import 'package:app_quanly_giaidau/domain/repositories/match_recording_catalog_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final matchRecordingCatalogRepositoryProvider =
    Provider<IMatchRecordingCatalogRepository>((ref) {
      return ApiMatchRecordingCatalogRepository(ref.watch(dioClientProvider));
    });
