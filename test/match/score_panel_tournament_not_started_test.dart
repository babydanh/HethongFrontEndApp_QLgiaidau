import 'package:app_quanly_giaidau/domain/repositories/match_repository.dart';
import 'package:app_quanly_giaidau/features/match/notifiers/score_panel_notifier.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps tournament-not-started to dedicated localized notifier message', () {
    final vi = lookupAppLocalizations(const Locale('vi'));
    final en = lookupAppLocalizations(const Locale('en'));

    expect(
      scorePanelWriteErrorMessage(vi, const TournamentNotStartedException()),
      vi.scorePanel_tournamentNotStarted,
    );
    expect(
      scorePanelWriteErrorMessage(en, const TournamentNotStartedException()),
      en.scorePanel_tournamentNotStarted,
    );
    expect(scorePanelWriteErrorMessage(vi, Exception('409')), isNull);
  });
}
