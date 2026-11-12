import 'package:app_quanly_giaidau/data/repositories/api/api_community_social_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_api_adapter.dart';

(ApiCommunitySocialRepository, FakeApiAdapter) _setup(
  Map<String, FakeReply> routes,
) {
  final adapter = FakeApiAdapter(routes);
  return (ApiCommunitySocialRepository(fakeDioClient(adapter)), adapter);
}

const _posts = '/communities/c-1/posts';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  dotenv.loadFromString(
    envString: 'API_BASE_URL=https://api.example.test/api/v1',
  );

  group('getFeed', () {
    test('drops posts without an id and exposes a fresh cursor', () async {
      final (repo, adapter) = _setup({
        'GET $_posts': const FakeReply(200, {
          'data': [
            {'id': 'p1', 'body': 'xin chào'},
            {'body': 'no id'},
          ],
          'meta': {'hasMore': true, 'nextCursor': ' n2 '},
        }),
      });

      final page = await repo.getFeed('c-1', cursor: 'n1', limit: 5);

      expect(page.items.map((p) => p.id), ['p1']);
      expect(page.items.single.text, 'xin chào');
      expect(page.nextCursor, 'n2');
      expect(page.hasMore, isTrue);
      expect(adapter.requests.single.query, {'limit': 5, 'cursor': 'n1'});
    });

    test('stops paging when the cursor repeats or hasMore is false', () async {
      final (repeat, _) = _setup({
        'GET $_posts': const FakeReply(200, {
          'data': <dynamic>[],
          'meta': {'hasMore': true, 'nextCursor': 'same'},
        }),
      });
      final (done, _) = _setup({
        'GET $_posts': const FakeReply(200, {
          'data': <dynamic>[],
          'meta': {'hasMore': false, 'nextCursor': 'more'},
        }),
      });

      final a = await repeat.getFeed('c-1', cursor: 'same');
      final b = await done.getFeed('c-1');

      expect(a.hasMore, isFalse);
      expect(a.nextCursor, isNull);
      expect(b.hasMore, isFalse);
      expect(b.nextCursor, isNull);
    });

    test(
      'returns an empty page for a malformed body and rethrows on 500',
      () async {
        final (malformed, _) = _setup({
          'GET $_posts': const FakeReply(200, <dynamic>[]),
        });
        final (failing, _) = _setup({
          'GET $_posts': const FakeReply(500, {'message': 'boom'}),
        });

        final page = await malformed.getFeed('c-1');

        expect(page.items, isEmpty);
        expect(page.hasMore, isFalse);
        await expectLater(failing.getFeed('c-1'), throwsA(isA<DioException>()));
      },
    );
  });

  group('createPost', () {
    test(
      'sends only non-empty optional fields and an Idempotency-Key',
      () async {
        final (repo, adapter) = _setup({
          'POST $_posts': const FakeReply(201, {
            'data': {'id': 'p9', 'body': 'bài mới'},
          }),
        });

        final bare = await repo.createPost('c-1', text: 'bài mới');
        await repo.createPost(
          'c-1',
          text: 'đủ',
          mediaUrls: ['u1'],
          topicTags: ['t'],
          mentions: ['m'],
          poll: {'question': 'q'},
        );

        expect(bare.id, 'p9');
        final bodies = adapter.postsTo(_posts).map((r) => r.body).toList();
        expect(bodies[0], {'body': 'bài mới'});
        expect(bodies[1], {
          'body': 'đủ',
          'mediaUrls': ['u1'],
          'topics': ['t'],
          'mentions': ['m'],
          'poll': {'question': 'q'},
        });
      },
    );

    test('accepts an unwrapped post body', () async {
      final (repo, _) = _setup({
        'POST $_posts': const FakeReply(201, {'id': 'p2', 'text': 'raw'}),
      });

      expect((await repo.createPost('c-1', text: 'raw')).id, 'p2');
    });

    test(
      'throws FormatException when the server returns a post without id',
      () async {
        final (repo, _) = _setup({
          'POST $_posts': const FakeReply(201, {
            'data': {'body': 'x'},
          }),
        });

        await expectLater(
          repo.createPost('c-1', text: 'x'),
          throwsA(isA<FormatException>()),
        );
      },
    );
  });

  group('comments', () {
    test('getComments filters id-less items and maps paging meta', () async {
      final (repo, adapter) = _setup({
        'GET $_posts/p1/comments': const FakeReply(200, {
          'data': [
            {'id': 'k1', 'body': 'hay', 'parentId': 'k0'},
            {'body': 'no id'},
          ],
          'meta': {'nextCursor': 'k-next', 'hasMore': true},
        }),
      });

      final page = await repo.getComments('c-1', 'p1', cursor: 'k-cur');

      expect(page.items.single.parentId, 'k0');
      expect(page.nextCursor, 'k-next');
      expect(page.hasMore, isTrue);
      expect(adapter.requests.single.query, {'limit': 20, 'cursor': 'k-cur'});
    });

    test('getComments yields no items when data is not a list', () async {
      final (repo, _) = _setup({
        'GET $_posts/p1/comments': const FakeReply(200, {'data': 'oops'}),
      });

      final page = await repo.getComments('c-1', 'p1');

      expect(page.items, isEmpty);
      expect(page.hasMore, isFalse);
    });

    test(
      'createComment trims the body and only sends a non-empty parentId',
      () async {
        final (repo, adapter) = _setup({
          'POST $_posts/p1/comments': const FakeReply(201, {
            'data': {'id': 'k2', 'body': 'ok'},
          }),
        });

        final c = await repo.createComment('c-1', 'p1', body: '  ok  ');
        await repo.createComment('c-1', 'p1', body: 'r', parentId: '');
        await repo.createComment('c-1', 'p1', body: 'r2', parentId: 'k1');

        expect(c.id, 'k2');
        final bodies = adapter
            .postsTo('$_posts/p1/comments')
            .map((r) => r.body);
        expect(bodies.toList(), [
          {'body': 'ok'},
          {'body': 'r'},
          {'body': 'r2', 'parentId': 'k1'},
        ]);
      },
    );

    test('createComment rejects a response without a comment id', () async {
      final (repo, _) = _setup({
        'POST $_posts/p1/comments': const FakeReply(201, {'data': {}}),
      });

      await expectLater(
        repo.createComment('c-1', 'p1', body: 'x'),
        throwsA(isA<FormatException>()),
      );
    });

    test(
      'deleteComment POSTs the delete route and rethrows on failure',
      () async {
        final (repo, adapter) = _setup({
          'POST /communities/c-1/comments/k1/delete': const FakeReply(200, {}),
        });

        await repo.deleteComment('c-1', 'k1');

        expect(
          adapter.requests.single.path,
          '/communities/c-1/comments/k1/delete',
        );
        await expectLater(
          repo.deleteComment('c-1', 'missing'),
          throwsA(isA<DioException>()),
        );
      },
    );
  });

  group('moderation', () {
    test(
      'getPendingPosts reads the data envelope and drops id-less posts',
      () async {
        final (repo, _) = _setup({
          'GET /communities/c-1/moderation/posts': const FakeReply(200, {
            'data': [
              {'id': 'p1'},
              {'text': 'no id'},
            ],
          }),
        });

        expect((await repo.getPendingPosts('c-1')).map((p) => p.id), ['p1']);
      },
    );

    test(
      'getPendingPosts returns empty when the payload is not a list',
      () async {
        final (repo, _) = _setup({
          'GET /communities/c-1/moderation/posts': const FakeReply(200, {
            'data': {'unexpected': true},
          }),
        });

        expect(await repo.getPendingPosts('c-1'), isEmpty);
      },
    );

    test(
      'getReports defaults to OPEN, parses nested report and defaults',
      () async {
        final (repo, adapter) = _setup({
          'GET /communities/c-1/moderation/reports': const FakeReply(200, {
            'data': [
              {
                'report': {'id': 'r1', 'reason': 'SPAM'},
              },
              {'id': 'r2'},
              {'reason': 'no id'},
            ],
          }),
        });

        final reports = await repo.getReports('c-1');

        expect(reports.map((r) => r.id), ['r1', 'r2']);
        expect(reports[0].reason, 'SPAM');
        // Missing reason/status fall back to documented defaults.
        expect(reports[1].reason, 'OTHER');
        expect(reports[1].status, 'OPEN');
        expect(adapter.requests.single.query, {'status': 'OPEN'});
      },
    );

    test('status and report mutations send the documented payloads', () async {
      final (repo, adapter) = _setup({
        'PATCH /communities/c-1/moderation/reports/r1': const FakeReply(
          200,
          {},
        ),
        'PATCH $_posts/p1/moderation': const FakeReply(200, {}),
        'POST $_posts/p1/report': const FakeReply(200, {}),
      });

      await repo.updateReportStatus('c-1', 'r1', status: 'RESOLVED');
      await repo.moderatePost('c-1', 'p1', status: 'APPROVED');
      await repo.reportPost('c-1', 'p1', reason: 'SPAM', details: '   ');
      await repo.reportPost('c-1', 'p1', reason: 'SPAM', details: ' link ');

      final bodies = adapter.requests.map((r) => r.body).toList();
      expect(bodies[0], {'status': 'RESOLVED'});
      expect(bodies[1], {'status': 'APPROVED'});
      expect(bodies[2], {'reason': 'SPAM'});
      expect(bodies[3], {'reason': 'SPAM', 'details': 'link'});
    });
  });

  group('polls and reactions', () {
    test(
      'votePoll and addPollOption parse the poll and trim the option',
      () async {
        final (repo, adapter) = _setup({
          'POST /communities/c-1/polls/pl1/vote': const FakeReply(200, {
            'data': {
              'id': 'pl1',
              'question': 'Đi đâu?',
              'totalVotes': 3,
              'options': [
                {
                  'id': 'o1',
                  'optionText': 'A',
                  'voteCount': 2,
                  'isVoted': true,
                },
                {'optionText': 'no id'},
              ],
            },
          }),
          'POST /communities/c-1/polls/pl1/options': const FakeReply(200, {
            'id': 'pl1',
            'options': [
              {'id': 'o9', 'text': 'Mới'},
            ],
          }),
        });

        final voted = await repo.votePoll('c-1', 'pl1', 'o1');
        final added = await repo.addPollOption('c-1', 'pl1', '  Mới  ');

        expect(voted.totalVotes, 3);
        expect(voted.options.single.isVoted, isTrue);
        expect(added.options.single.optionText, 'Mới');
        expect(adapter.requests[0].body, {'optionId': 'o1'});
        expect(adapter.requests[1].body, {'optionText': 'Mới'});
      },
    );

    test('reactToPost sends reactionType and rethrows on failure', () async {
      final (repo, adapter) = _setup({
        'POST $_posts/p1/reaction': const FakeReply(200, {}),
      });

      await repo.reactToPost('c-1', 'p1', reaction: 'LIKE');

      expect(adapter.requests.single.body, {'reactionType': 'LIKE'});
      await expectLater(
        repo.reactToPost('c-1', 'zz', reaction: 'LIKE'),
        throwsA(isA<DioException>()),
      );
    });

    test('post and comment reactions drop groups without a type and fall '
        'back count to the user list length', () async {
      final (repo, _) = _setup({
        'GET $_posts/p1/reactions': const FakeReply(200, {
          'data': [
            {
              'reactionType': 'LIKE',
              'isReacted': true,
              'users': [
                {'id': 'u1', 'fullName': 'An'},
                {'fullName': 'no id'},
              ],
            },
            {'count': 4},
          ],
        }),
        'GET /communities/c-1/comments/k1/reactions': const FakeReply(200, [
          {'emoji': 'HEART', 'count': 7},
        ]),
      });

      final post = await repo.getPostReactions('c-1', 'p1');
      final comment = await repo.getCommentReactions('c-1', 'k1');

      expect(post, hasLength(1));
      expect(post.single.count, 1);
      expect(post.single.isReacted, isTrue);
      expect(post.single.users.single.fullName, 'An');
      expect(comment.single.reactionType, 'HEART');
      expect(comment.single.count, 7);
    });

    test('reactToComment parses the toggle result', () async {
      final (repo, adapter) = _setup({
        'POST /communities/c-1/comments/k1/reaction': const FakeReply(200, {
          'data': {
            'reactionType': 'LIKE',
            'count': 2,
            'reactionDetails': [
              {'reactionType': 'LIKE', 'count': 2},
              {'count': 1},
            ],
          },
        }),
      });

      final result = await repo.reactToComment('c-1', 'k1', reaction: 'LIKE');

      expect(result.reactionType, 'LIKE');
      expect(result.count, 2);
      expect(result.reactionDetails, hasLength(1));
      expect(adapter.requests.single.body, {'reactionType': 'LIKE'});
    });
  });

  group('deletePost / uploadImage', () {
    test('deletePost calls DELETE and surfaces failures', () async {
      final (repo, adapter) = _setup({
        'DELETE $_posts/p1': const FakeReply(204, {}),
      });

      await repo.deletePost('c-1', 'p1');

      expect(adapter.requests.single.method, 'DELETE');
      await expectLater(
        repo.deletePost('c-1', 'nope'),
        throwsA(isA<DioException>()),
      );
    });

    test('uploadImage reads url from the root or from data', () async {
      final (root, _) = _setup({
        'POST /upload/image': const FakeReply(200, {
          'url': 'https://cdn/a.png',
        }),
      });
      final (nested, _) = _setup({
        'POST /upload/image': const FakeReply(200, {
          'data': {'url': 'https://cdn/b.png'},
        }),
      });

      expect(await root.uploadImage([1, 2, 3], 'a.png'), 'https://cdn/a.png');
      expect(await nested.uploadImage([1], 'b.png'), 'https://cdn/b.png');
    });

    test('uploadImage throws FormatException when no url comes back', () async {
      final (repo, _) = _setup({
        'POST /upload/image': const FakeReply(200, {
          'data': {'url': ''},
        }),
      });

      await expectLater(
        repo.uploadImage([1], 'a.png'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
