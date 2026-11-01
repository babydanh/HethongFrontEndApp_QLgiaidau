import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/community_invite_model.dart';
import 'package:app_quanly_giaidau/domain/entities/community.dart';
import 'package:app_quanly_giaidau/features/community/screens/club_invites_screen.dart';
import 'package:app_quanly_giaidau/features/community/screens/edit_club_screen.dart';
import 'package:app_quanly_giaidau/features/community/widgets/community_skeletons.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget home, {List<Override> overrides = const []}) =>
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('vi'),
        home: home,
      ),
    );

void main() {
  testWidgets('invites screen shows list skeleton while loading', (
    tester,
  ) async {
    final completer = Completer<List<CommunityInviteModel>>();
    await tester.pumpWidget(
      _app(
        const ClubInvitesScreen(),
        overrides: [
          myCommunityInvitesProvider.overrideWith((ref) => completer.future),
        ],
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(CommunityListSkeleton), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);

    completer.complete(const []);
    await tester.pumpAndSettle();
    expect(find.byType(CommunityListSkeleton), findsNothing);
  });

  testWidgets('edit club screen shows form skeleton while loading', (
    tester,
  ) async {
    final completer = Completer<Community?>();
    await tester.pumpWidget(
      _app(
        const EditClubScreen(clubId: 'c1'),
        overrides: [
          communityDetailProvider.overrideWith((ref, id) => completer.future),
        ],
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(CommunityFormSkeleton), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });

  const skeletons = <String, Widget>{
    'settings sheet': CommunitySettingsSheetSkeleton(),
    'chat': CommunityChatSkeleton(),
    'form': CommunityFormSkeleton(),
    'feed': CommunityFeedSkeleton(),
    'gallery': CommunityGallerySkeleton(),
    'list': CommunityListSkeleton(),
  };
  const sizes = <Size>[Size(360, 640), Size(412, 915), Size(820, 1180)];

  for (final entry in skeletons.entries) {
    for (final size in sizes) {
      testWidgets('${entry.key} skeleton renders at ${size.width.toInt()}x'
          '${size.height.toInt()} without overflow', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          _app(Scaffold(body: SizedBox.expand(child: entry.value))),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
