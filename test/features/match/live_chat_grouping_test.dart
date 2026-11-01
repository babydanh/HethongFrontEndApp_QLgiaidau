import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/features/match/widgets/match_discussion_message.dart';
import 'package:app_quanly_giaidau/features/match/widgets/viewer/live_chat_grouping.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _t0 = DateTime.utc(2026, 11, 1, 10);

void main() {
  test('TC-LIVEFS-01 same author within five minutes continues the group', () {
    expect(
      isChatContinuation(
        userId: 'u1',
        at: _t0.add(const Duration(minutes: 1)),
        olderUserId: 'u1',
        olderAt: _t0,
      ),
      isTrue,
    );
  });

  test('TC-LIVEFS-02 different author, long gap or missing id break the group', () {
    final soon = _t0.add(const Duration(minutes: 1));
    expect(
      isChatContinuation(
        userId: 'u2',
        at: soon,
        olderUserId: 'u1',
        olderAt: _t0,
      ),
      isFalse,
    );
    expect(
      isChatContinuation(
        userId: 'u1',
        at: _t0.add(const Duration(minutes: 6)),
        olderUserId: 'u1',
        olderAt: _t0,
      ),
      isFalse,
    );
    expect(
      isChatContinuation(userId: '', at: soon, olderUserId: '', olderAt: _t0),
      isFalse,
    );
    expect(isChatContinuation(userId: 'u1', at: soon), isFalse);
  });

  testWidgets('TC-LIVEFS-03 compact message hides the author name', (
    tester,
  ) async {
    Widget app({required bool compact}) => ProviderScope(
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: MatchDiscussionMessage(
            userId: 'u1',
            name: 'Ann',
            text: 'hello',
            timeLabel: '10:00',
            compact: compact,
          ),
        ),
      ),
    );

    await tester.pumpWidget(app(compact: false));
    expect(find.text('Ann'), findsOneWidget);

    await tester.pumpWidget(app(compact: true));
    expect(find.text('Ann'), findsNothing);
    expect(find.text('hello'), findsOneWidget);
  });
}
