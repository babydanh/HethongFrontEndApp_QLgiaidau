import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/social/widgets/create_edit_screen/social_duration_sheet.dart';
import 'package:app_quanly_giaidau/features/social/widgets/social_more_options_sheet.dart';
import 'package:app_quanly_giaidau/features/social/widgets/participant_tab/social_participant_counter.dart';
import 'package:app_quanly_giaidau/features/social/widgets/create_edit_screen/social_price_dialog.dart';
import 'package:app_quanly_giaidau/data/models/social_session_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

void main() {
  testWidgets(
    'participant counter keeps local state and reports valid values',
    (tester) async {
      final values = <int>[];
      var parentBuilds = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                parentBuilds++;
                return SocialParticipantCounter(
                  initialValue: 6,
                  onChanged: values.add,
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.remove));
      await tester.pump();

      expect(values, [7, 6]);
      expect(parentBuilds, 1);
      expect(find.text('6'), findsOneWidget);
    },
  );

  testWidgets('duration and price modals return confirmed values', (
    tester,
  ) async {
    double? duration;
    int? price;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Column(
                children: [
                  TextButton(
                    onPressed: () async {
                      duration = await SocialDurationSheet.show(context, 1);
                    },
                    child: const Text('Duration'),
                  ),
                  TextButton(
                    onPressed: () async {
                      price = await SocialPriceDialog.show(context, 0);
                    },
                    child: const Text('Price'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Duration'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1.5 giờ'));
    await tester.pumpAndSettle();
    expect(duration, 1.5);

    await tester.tap(find.text('Price'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '50000');
    await tester.tap(find.text('Xác nhận'));
    await tester.pumpAndSettle();
    expect(price, 50000);
  });
  testWidgets('more options dispatches host and guest actions', (tester) async {
    final session = SocialSessionModel(
      id: 'session-1',
      hostUserId: 'host-1',
      title: 'Kèo cuối tuần',
      playFormat: 'Giao lưu',
      startAt: DateTime(2026, 9, 25),
      venueName: 'Sân A',
      venueAddress: 'Địa chỉ A',
      sport: 'pickleball',
      sportName: 'Pickleball',
    );
    final completedSession = SocialSessionModel(
      id: 'session-completed',
      hostUserId: 'host-1',
      title: 'Social đã kết thúc',
      playFormat: 'Giao lưu',
      startAt: DateTime(2026, 9, 25),
      venueName: 'Sân A',
      venueAddress: 'Địa chỉ A',
      sport: 'pickleball',
      sportName: 'Pickleball',
      status: 'COMPLETED',
    );
    var edits = 0;
    var reports = 0;
    var repeats = 0;
    var cancelCalls = 0;
    var muteCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              void open(bool isHost, [SocialSessionModel? target]) =>
                  SocialMoreOptionsSheet.show(
                    context,
                    target ?? session,
                    isHost: isHost,
                    onRepeat: () => repeats++,
                    onEdit: () => edits++,
                    onCancel: () => cancelCalls++,
                    onMute: () => muteCalls++,
                    onReport: () => reports++,
                  );
              return Column(
                children: [
                  TextButton(
                    onPressed: () => open(true),
                    child: const Text('Host'),
                  ),
                  TextButton(
                    onPressed: () => open(true, completedSession),
                    child: const Text('Completed host'),
                  ),
                  TextButton(
                    onPressed: () => open(true, session.copyWith(status: 'FULL')),
                    child: const Text('Full host'),
                  ),
                  TextButton(
                    onPressed: () => open(false),
                    child: const Text('Guest'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Host'));
    await tester.pumpAndSettle();
    expect(find.text('Lặp lại kèo'), findsOneWidget);
    expect(find.text('Chỉnh sửa kèo'), findsOneWidget);
    expect(find.text('Hủy kèo'), findsOneWidget);
    expect(find.text('Tắt thông báo cuộc trò chuyện'), findsNothing);
    await tester.tap(find.text('Chỉnh sửa kèo'));
    await tester.pumpAndSettle();
    expect(edits, 1);

    await tester.tap(find.text('Host'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hủy kèo'));
    await tester.pumpAndSettle();
    expect(cancelCalls, 1);

    await tester.tap(find.text('Full host'));
    await tester.pumpAndSettle();
    expect(find.text('Chỉnh sửa kèo'), findsOneWidget);
    expect(find.text('Hủy kèo'), findsOneWidget);
    await tester.tap(find.text('Lặp lại kèo'));
    await tester.pumpAndSettle();
    expect(repeats, 1);

    await tester.tap(find.text('Completed host'));
    await tester.pumpAndSettle();
    expect(find.text('Lặp lại kèo'), findsOneWidget);
    expect(find.text('Chỉnh sửa kèo'), findsNothing);
    expect(find.text('Hủy kèo'), findsNothing);
    await tester.tap(find.text('Lặp lại kèo'));
    await tester.pumpAndSettle();
    expect(repeats, 2);

    await tester.tap(find.text('Guest'));
    await tester.pumpAndSettle();
    expect(find.text('Chỉnh sửa kèo'), findsNothing);
    expect(find.text('Hủy kèo'), findsNothing);
    await tester.tap(find.text('Báo cáo buổi Social này'));
    await tester.pumpAndSettle();
    expect(reports, 1);
    expect(cancelCalls, 1);
    expect(muteCalls, 0);
  });
}
