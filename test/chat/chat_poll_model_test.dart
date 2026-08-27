import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:app_quanly_giaidau/data/models/chat_models.dart';

void main() {
  group('Chat poll parsing', () {
    test('parses Web-style POLL metadata from another sender', () {
      final message = ChatMessageModel.fromJson({
        'id': 'message-1',
        'roomId': 'room-1',
        'type': 'POLL',
        'senderId': 'other-user',
        'senderName': 'Other user',
        'messageText': '[Poll] Which sport?',
        'metadata': {
          'question': 'Which sport?',
          'allowMultiple': false,
          'options': [
            {
              'id': 'option-1',
              'text': 'Football',
              'voterIds': ['current-user'],
            },
            {'id': 'option-2', 'text': 'Tennis', 'voterIds': []},
          ],
        },
        'createdAt': '2026-08-27T10:00:00.000Z',
      }, currentUserId: 'current-user');

      expect(message.poll, isNotNull);
      expect(message.poll!.question, 'Which sport?');
      expect(message.poll!.allowMultipleAnswers, isFalse);
      expect(message.poll!.options, hasLength(2));
      expect(message.poll!.options.first.optionText, 'Football');
      expect(message.poll!.options.first.isVoted, isTrue);
      expect(message.poll!.totalVotes, 1);
    });

    test('preserves existing direct poll and nested metadata.poll shapes', () {
      final direct = ChatMessageModel.fromJson({
        'id': 'direct',
        'roomId': 'room-1',
        'senderId': 'other-user',
        'poll': {
          'id': 'poll-1',
          'question': 'Direct poll',
          'allowMultipleAnswers': true,
          'options': [
            {'id': 'a', 'optionText': 'A', 'voteCount': 2},
            {'id': 'b', 'optionText': 'B', 'voteCount': 0},
          ],
        },
      });
      final nested = ChatMessageModel.fromJson({
        'id': 'nested',
        'roomId': 'room-1',
        'senderId': 'other-user',
        'metadata': {
          'poll': {
            'question': 'Nested poll',
            'options': [
              {
                'id': 'a',
                'text': 'A',
                'voters': ['u1'],
              },
              {
                'id': 'b',
                'text': 'B',
                'voters': ['u2'],
              },
            ],
          },
        },
      });

      expect(direct.poll?.question, 'Direct poll');
      expect(direct.poll?.allowMultipleAnswers, isTrue);
      expect(direct.poll?.totalVotes, 2);
      expect(nested.poll?.question, 'Nested poll');
      expect(nested.poll?.totalVotes, 2);
    });

    test('does not treat an incomplete POLL payload as a poll', () {
      final message = ChatMessageModel.fromJson({
        'id': 'invalid',
        'roomId': 'room-1',
        'type': 'POLL',
        'senderId': 'other-user',
        'messageText': 'Poll unavailable',
        'metadata': {'question': 'Missing options'},
      });

      expect(message.poll, isNull);
      expect(message.content, 'Poll unavailable');
    });
  });

  test('Flutter composer exposes the existing poll creator', () {
    final source = File(
      'lib/features/chat/screens/chat_detail_screen.dart',
    ).readAsStringSync();

    expect(source, contains('Icons.poll_outlined'));
    expect(source, contains('chatDetailPollTooltip'));
    expect(source, contains('_openCreatePollDialog'));
  });

  test('Flutter subscribes to existing poll vote realtime event', () {
    final socketSource = File(
      'lib/core/services/chat_socket_service.dart',
    ).readAsStringSync();
    final detailSource = File(
      'lib/features/chat/screens/chat_detail_screen.dart',
    ).readAsStringSync();

    expect(socketSource, contains("'chat:poll:voted'"));
    expect(socketSource, contains('onPollVoted'));
    expect(detailSource, contains('_chatSocket.onPollVoted'));
  });
}
