import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/violation_report.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyReportsState {
  final List<ViolationReport> reports;
  final int page;
  final int totalPages;

  const MyReportsState({
    required this.reports,
    required this.page,
    required this.totalPages,
  });
}

class MyReportsController extends AsyncNotifier<MyReportsState> {
  static const _pageSize = 10;
  final Map<int, String?> _cursorByPage = <int, String?>{1: null};

  @override
  Future<MyReportsState> build() => _loadPage(1);

  Future<void> loadPage(int page) async {
    if (page < 1) return;
    state = const AsyncLoading();
    try {
      state = AsyncData(await _loadPage(page));
    } catch (error, stack) {
      state = AsyncError(error, stack);
    }
  }

  Future<MyReportsState> _loadPage(int page) async {
    final result = await ref.read(reportRepositoryProvider).getMine(
          cursor: _cursorByPage[page],
          limit: _pageSize,
        );
    _cursorByPage[page + 1] = result.nextCursor;
    final inferredTotalPages = result.nextCursor == null ? page : page + 1;
    return MyReportsState(
      reports: result.items,
      page: page,
      totalPages: result.totalPages > inferredTotalPages
          ? result.totalPages
          : inferredTotalPages,
    );
  }
}

final myReportsProvider = AsyncNotifierProvider<MyReportsController, MyReportsState>(
  MyReportsController.new,
);
