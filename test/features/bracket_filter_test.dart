import 'package:flutter_test/flutter_test.dart';
import 'package:app_quanly_giaidau/features/bracket/widgets/bracket_filter_bottom_sheet.dart';

void main() {
  group('BracketFilterState unit tests', () {
    test('default state has zero active filters', () {
      const state = BracketFilterState();
      expect(state.activeCount, 0);
      expect(state.hasActiveFilters, isFalse);
    });

    test('counts active filters correctly for each dimension', () {
      var state = const BracketFilterState(matchFilter: 'live');
      expect(state.activeCount, 1);
      expect(state.hasActiveFilters, isTrue);

      state = state.copyWith(selectedBranch: 'winners');
      expect(state.activeCount, 2);

      state = state.copyWith(selectedGroup: 'Bảng A');
      expect(state.activeCount, 3);

      state = state.copyWith(selectedLeg: 2);
      expect(state.activeCount, 4);

      state = state.copyWith(selectedRound: 3);
      expect(state.activeCount, 5);
    });

    test('ignores empty or "all" values in activeCount', () {
      const state = BracketFilterState(
        matchFilter: 'all',
        selectedBranch: 'all',
        selectedGroup: 'all',
        selectedLeg: 0,
        selectedRound: 0,
      );
      expect(state.activeCount, 0);
      expect(state.hasActiveFilters, isFalse);
    });

    test('copyWith produces expected updated state', () {
      const initial = BracketFilterState(matchFilter: 'live', selectedRound: 1);
      final updated = initial.copyWith(matchFilter: 'completed');

      expect(updated.matchFilter, 'completed');
      expect(updated.selectedRound, 1);
      expect(updated.selectedBranch, '');
    });
  });
}
