import 'package:app_quanly_giaidau/data/models/community_social_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CommunityPostModel.fromJson', () {
    test('parses author identity, tournament and poll contract', () {
      final post = CommunityPostModel.fromJson({
        'id': 'post-1',
        'authorId': 'user-1',
        'body': 'Kèo tối nay',
        'author': {
          'id': 'user-1',
          'fullName': 'Nguyễn Minh Anh',
          'avatarUrl': 'https://example.com/avatar.jpg',
        },
        'tournamentId': 'tournament-1',
        'tournament': {'name': 'Giải nội bộ tháng 8'},
        'poll': {
          'id': 'poll-1',
          'question': 'Bạn tham gia không?',
          'allowMultipleAnswers': false,
          'allowAddOptions': true,
          'isClosed': false,
          'totalVotes': 3,
          'options': [
            {
              'id': 'option-1',
              'optionText': 'Có',
              'voteCount': 2,
              'isVoted': true,
              'voters': [
                {
                  'id': 'user-1',
                  'fullName': 'Nguyễn Minh Anh',
                  'avatarUrl': 'https://example.com/avatar.jpg',
                },
              ],
            },
          ],
        },
      });

      expect(post.authorId, 'user-1');
      expect(post.tournamentName, 'Giải nội bộ tháng 8');
      expect(post.poll?.totalVotes, 3);
      expect(post.poll?.options.single.optionText, 'Có');
      expect(post.poll?.options.single.isVoted, isTrue);
      expect(
        post.poll?.options.single.voters.single.fullName,
        'Nguyễn Minh Anh',
      );
    });
  });

  group('CommunityPollModel.fromJson', () {
    test(
      'parses backend vote response where data contains poll and options',
      () {
        final poll = CommunityPollModel.fromJson({
          'poll': {
            'id': 'poll-2',
            'question': 'Chọn lịch thi đấu',
            'allowMultipleAnswers': true,
            'allowAddOptions': false,
            'isClosed': false,
          },
          'totalVotes': 4,
          'options': [
            {
              'id': 'option-2',
              'optionText': 'Thứ bảy',
              'voteCount': 4,
              'isVoted': true,
              'voters': <Map<String, dynamic>>[],
            },
          ],
        });

        expect(poll.id, 'poll-2');
        expect(poll.question, 'Chọn lịch thi đấu');
        expect(poll.allowMultipleAnswers, isTrue);
        expect(poll.totalVotes, 4);
        expect(poll.options.single.isVoted, isTrue);
      },
    );
  });

  group('CommunityCommentModel.fromJson', () {
    test('parses nested author and parentId for replies', () {
      final comment = CommunityCommentModel.fromJson({
        'id': 'comment-2',
        'authorId': 'user-2',
        'parentId': 'comment-1',
        'body': '@Minh Anh Đồng ý',
        'author': {
          'id': 'user-2',
          'fullName': 'Trần Quốc Bảo',
          'avatarUrl': 'https://example.com/bao.jpg',
        },
      });

      expect(comment.authorId, 'user-2');
      expect(comment.parentId, 'comment-1');
      expect(comment.authorName, 'Trần Quốc Bảo');
    });
  });
}
