import 'package:app_quanly_giaidau/domain/entities/live_overlay_kind.dart';
import 'package:app_quanly_giaidau/features/match/widgets/live_overlay_controls.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) {
  return MaterialApp(
    locale: const Locale('vi'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('liveOverlayToShow', () {
    test('shows only the overlay whose server flag is on', () {
      expect(
        liveOverlayToShow(
          h2hVisible: true,
          bracketVisible: false,
          matchEnded: false,
        ),
        LiveOverlayKind.h2h,
      );
      expect(
        liveOverlayToShow(
          h2hVisible: false,
          bracketVisible: true,
          matchEnded: false,
        ),
        LiveOverlayKind.bracket,
      );
      expect(
        liveOverlayToShow(
          h2hVisible: false,
          bracketVisible: false,
          matchEnded: false,
        ),
        isNull,
      );
    });

    test('prefers the bracket when the contract-breaking case sends both flags', () {
      // [INFERENCE] Hợp đồng server ép loại trừ; nếu cả hai cờ true thì hiện Sơ đồ.
      expect(
        liveOverlayToShow(
          h2hVisible: true,
          bracketVisible: true,
          matchEnded: false,
        ),
        LiveOverlayKind.bracket,
      );
    });

    test('hides every overlay once the match has ended', () {
      expect(
        liveOverlayToShow(
          h2hVisible: true,
          bracketVisible: false,
          matchEnded: true,
        ),
        isNull,
      );
      expect(
        liveOverlayToShow(
          h2hVisible: false,
          bracketVisible: true,
          matchEnded: true,
        ),
        isNull,
      );
    });
  });

  group('LiveOverlayToggleChips', () {
    testWidgets('tapping H2H while off asks the server to show it', (
      tester,
    ) async {
      final calls = <(LiveOverlayKind, bool)>[];
      await tester.pumpWidget(
        _host(
          LiveOverlayToggleChips(
            h2hVisible: false,
            bracketVisible: false,
            bracketAvailable: true,
            matchEnded: false,
            pendingKind: null,
            onToggle: (kind, visible) => calls.add((kind, visible)),
          ),
        ),
      );

      await tester.tap(find.text('H2H'));
      expect(calls, [(LiveOverlayKind.h2h, true)]);
    });

    testWidgets('tapping Sơ đồ while it is on asks the server to hide it', (
      tester,
    ) async {
      final calls = <(LiveOverlayKind, bool)>[];
      await tester.pumpWidget(
        _host(
          LiveOverlayToggleChips(
            h2hVisible: false,
            bracketVisible: true,
            bracketAvailable: true,
            matchEnded: false,
            pendingKind: null,
            onToggle: (kind, visible) => calls.add((kind, visible)),
          ),
        ),
      );

      await tester.tap(find.text('Sơ đồ'));
      expect(calls, [(LiveOverlayKind.bracket, false)]);
    });

    testWidgets('chips meet the 44 px touch target', (tester) async {
      await tester.pumpWidget(
        _host(
          LiveOverlayToggleChips(
            h2hVisible: false,
            bracketVisible: false,
            bracketAvailable: true,
            matchEnded: false,
            pendingKind: null,
            onToggle: (_, _) {},
          ),
        ),
      );

      expect(
        tester
            .getSize(find.byKey(const ValueKey('live-overlay-chip-h2h')))
            .height,
        greaterThanOrEqualTo(44),
      );
      expect(
        tester
            .getSize(find.byKey(const ValueKey('live-overlay-chip-bracket')))
            .height,
        greaterThanOrEqualTo(44),
      );
    });

    testWidgets(
      'while a save is pending both chips are locked and only the tapped chip spins',
      (tester) async {
        final calls = <(LiveOverlayKind, bool)>[];
        await tester.pumpWidget(
          _host(
            LiveOverlayToggleChips(
              h2hVisible: false,
              bracketVisible: false,
              bracketAvailable: true,
              matchEnded: false,
              pendingKind: LiveOverlayKind.h2h,
              onToggle: (kind, visible) => calls.add((kind, visible)),
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        await tester.tap(
          find.byKey(const ValueKey('live-overlay-chip-h2h')),
          warnIfMissed: false,
        );
        await tester.tap(
          find.byKey(const ValueKey('live-overlay-chip-bracket')),
          warnIfMissed: false,
        );
        expect(calls, isEmpty);
      },
    );

    testWidgets('a match without tournament cannot open the bracket', (
      tester,
    ) async {
      final calls = <(LiveOverlayKind, bool)>[];
      await tester.pumpWidget(
        _host(
          LiveOverlayToggleChips(
            h2hVisible: false,
            bracketVisible: false,
            bracketAvailable: false,
            matchEnded: false,
            pendingKind: null,
            onToggle: (kind, visible) => calls.add((kind, visible)),
          ),
        ),
      );

      await tester.tap(find.text('Sơ đồ'), warnIfMissed: false);
      expect(calls, isEmpty);
    });

    testWidgets('a completed match shows the ended label and locks both chips', (
      tester,
    ) async {
      final calls = <(LiveOverlayKind, bool)>[];
      await tester.pumpWidget(
        _host(
          LiveOverlayToggleChips(
            h2hVisible: true,
            bracketVisible: false,
            bracketAvailable: true,
            matchEnded: true,
            pendingKind: null,
            onToggle: (kind, visible) => calls.add((kind, visible)),
          ),
        ),
      );

      expect(find.text('Trận đã kết thúc'), findsOneWidget);
      await tester.tap(find.text('H2H'), warnIfMissed: false);
      await tester.tap(find.text('Sơ đồ'), warnIfMissed: false);
      expect(calls, isEmpty);
    });
  });

  testWidgets('reduced motion removes the 240 ms overlay transition', (
    tester,
  ) async {
    late Duration normal;
    late Duration reduced;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: false),
        child: Builder(
          builder: (context) {
            normal = liveOverlayMotionDuration(context);
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Builder(
          builder: (context) {
            reduced = liveOverlayMotionDuration(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(normal, const Duration(milliseconds: 240));
    expect(reduced, Duration.zero);
  });

  testWidgets('close button calls back on tap and meets the 44 px target', (
    tester,
  ) async {
    var closed = 0;
    await tester.pumpWidget(
      _host(LiveOverlayCloseButton(onPressed: () => closed++)),
    );

    final size = tester.getSize(find.byType(IconButton));
    expect(size.width, greaterThanOrEqualTo(44));
    expect(size.height, greaterThanOrEqualTo(44));

    await tester.tap(find.byTooltip('Đóng'));
    expect(closed, 1);
  });
}
