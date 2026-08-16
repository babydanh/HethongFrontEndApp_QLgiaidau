# Community Social Parity — Flutter App Implementation Plan

> **For Hermes:** Use subagent-driven-development skill to implement this plan task-by-task.

**Goal:** Đạt parity chức năng Community/Social giữa Flutter App và Web Frontend, tuân thủ SKILLS.md, GRAPH_REPORT.md và taste skills.

**Architecture:** 
- Mở rộng `ICommunitySocialRepository` với các method mới
- Tách widget theo Feature-first, mỗi file ≤ 300 dòng
- Dùng `Notifier` / `AsyncNotifier` (KHÔNG dùng StateNotifier)
- API prefix `/api/v1`, response bọc trong `{ data, meta }`

**Tech Stack:** Flutter 3.10+, Riverpod 3.3+, go_router 17+, Dio, Socket.IO client

**Source specs:**
- `COMMUNITY_SOCIAL_HUB_EXECUTION_PLAN.md` (kiến trúc & phase)
- `COMMUNITY_WEB_SYNC_SPEC.md` (parity checklist)
- Web thực tế đã audit: `CommunityPostCard.tsx`, `UnifiedChatWidget.tsx`, backend controller

---

## PHASE 0: API Contract & Repository Extension

### Task 0.1: Thêm delete post API vào repository interface

**Objective:** Định nghĩa method xóa bài viết trong abstract class

**Files:**
- Modify: `lib/domain/repositories/community_social_repository.dart`

**Step 1: Thêm method vào interface**

```dart
// Thêm vào ICommunitySocialRepository
Future<void> deletePost(String communityId, String postId);

Future<void> deleteComment(String communityId, String commentId);
```

**Verification:** `flutter analyze lib/domain/repositories/community_social_repository.dart` — không có lỗi

---

### Task 0.2: Implement delete post trong ApiCommunitySocialRepository

**Objective:** Gọi API `DELETE /communities/:id/posts/:postId`

**Files:**
- Modify: `lib/data/repositories/api/api_community_social_repository.dart`

**Step 1: Thêm implementation**

```dart
@override
Future<void> deletePost(String communityId, String postId) async {
  try {
    await _dioClient.dio.delete('/communities/$communityId/posts/$postId');
    _log.info('Đã xóa bài viết $postId');
  } catch (error, stack) {
    _log.error('Không thể xóa bài viết $postId', error, stack);
    rethrow;
  }
}

@override
Future<void> deleteComment(String communityId, String commentId) async {
  try {
    await _dioClient.dio.post('/communities/$communityId/comments/$commentId/delete');
    _log.info('Đã xóa bình luận $commentId');
  } catch (error, stack) {
    _log.error('Không thể xóa bình luận $commentId', error, stack);
    rethrow;
  }
}
```

**Verification:** 
```bash
flutter analyze lib/data/repositories/api/api_community_social_repository.dart
```

---

## PHASE 1: Delete Post & Comment UI

### Task 1.1: Thêm nút xóa bài trong CommunityPostCard

**Objective:** Hiển thị icon xóa khi user là tác giả hoặc BQT

**Files:**
- Modify: `lib/features/community/social/widgets/community_post_card.dart`
- Read: `lib/providers/auth_provider.dart` (để lấy currentUserId, role)

**Step 1: Thêm parameter vào CommunityPostCard**

```dart
class CommunityPostCard extends ConsumerWidget {
  final CommunityPostModel post;
  final String communityId;
  final ValueChanged<String>? onReact;
  final bool commentsEnabled;
  final VoidCallback? onDelete; // THÊM MỚI

  const CommunityPostCard({
    super.key,
    required this.post,
    required this.communityId,
    this.onReact,
    this.commentsEnabled = true,
    this.onDelete, // THÊM MỚI
  });
```

**Step 2: Thêm nút xóa vào header của card**

```dart
// Trong build(), sau author name/time, thêm PopupMenuButton hoặc IconButton
if (onDelete != null)
  IconButton(
    tooltip: 'Xóa bài viết',
    onPressed: onDelete,
    icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
  ),
```

**Step 3: Wire onDelete trong CommunitySocialScreen**

```dart
// Trong CommunitySocialScreen, chỗ render CommunityPostCard:
CommunityPostCard(
  post: post,
  communityId: widget.communityId,
  onReact: (reaction) => ref.read(communityFeedNotifierProvider.notifier).reactToPost(post.id, reaction),
  onDelete: (currentUserId == post.authorId || isModerator)
      ? () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Xóa bài viết?'),
              content: const Text('Bạn có chắc muốn xóa bài viết này?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Xóa'),
                ),
              ],
            ),
          );
          if (confirm == true) {
            await ref.read(communitySocialRepositoryProvider).deletePost(widget.communityId, post.id);
            ref.read(communityFeedNotifierProvider.notifier).refresh();
          }
        }
      : null,
),
```

**Verification:** 
- Chạy app, login với user là tác giả bài viết → thấy nút xóa
- Bấm xóa → hiện dialog → confirm → bài biến mất khỏi feed

---

### Task 1.2: Thêm nút xóa comment trong _CommentSheet

**Objective:** Cho phép tác giả comment và BQT xóa comment

**Files:**
- Modify: `lib/features/community/social/widgets/community_post_card.dart` (_CommentSheet widget)

**Step 1: Thêm parameter currentUserId và isModerator vào _CommentSheet**

```dart
class _CommentSheet extends ConsumerStatefulWidget {
  final String communityId;
  final String postId;
  final List<CommunityCommentModel> comments;
  final String currentUserId;
  final bool isModerator;

  const _CommentSheet({
    required this.communityId,
    required this.postId,
    required this.comments,
    required this.currentUserId,
    required this.isModerator,
  });
```

**Step 2: Thêm icon xóa vào mỗi ListTile của comment**

```dart
// Trong renderCommentItem (hoặc ListTile):
if (comment.authorId == widget.currentUserId || widget.isModerator)
  IconButton(
    tooltip: 'Xóa bình luận',
    onPressed: () async {
      final confirm = await showDialog<bool>(...);
      if (confirm == true) {
        await ref.read(communitySocialRepositoryProvider).deleteComment(widget.communityId, comment.id);
        setState(() {
          _comments.removeWhere((c) => c.id == comment.id);
        });
      }
    },
    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
  ),
```

**Verification:** 
- Chạy app, mở comment sheet
- Comment của mình có nút xóa → bấm → comment biến mất

---

## PHASE 2: Nested Comments (Reply Phân Cấp)

### Task 2.1: Mở rộng CommunityCommentModel với parentId

**Objective:** Hỗ trợ reply 2 cấp (comment → reply)

**Files:**
- Modify: `lib/data/models/community_social_models.dart`

**Step 1: Thêm field parentId vào CommunityCommentModel**

```dart
class CommunityCommentModel {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String body;
  final String? parentId; // THÊM MỚI
  final DateTime createdAt;

  const CommunityCommentModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.body,
    this.parentId, // THÊM MỚI
    required this.createdAt,
  });

  factory CommunityCommentModel.fromJson(Map<String, dynamic> json) {
    return CommunityCommentModel(
      id: _asString(json['id']) ?? '',
      authorId: _asString(json['authorId'] ?? json['author_id']) ?? '',
      authorName: _asString(json['authorName'] ?? json['author_name']) ?? 'Ẩn danh',
      authorAvatar: _asString(json['authorAvatar'] ?? json['avatar']),
      body: _asString(json['body'] ?? json['content']) ?? '',
      parentId: _asString(json['parentId'] ?? json['parent_id']), // THÊM MỚI
      createdAt: _asDateTime(json['createdAt'] ?? json['created_at']) ?? DateTime.now(),
    );
  }
}
```

**Verification:** `flutter analyze lib/data/models/community_social_models.dart`

---

### Task 2.2: Cập nhật createComment hỗ trợ parentId

**Objective:** Gửi `parentId` khi reply vào comment

**Files:**
- Modify: `lib/domain/repositories/community_social_repository.dart`
- Modify: `lib/data/repositories/api/api_community_social_repository.dart`

**Step 1: Thêm parameter parentId vào interface**

```dart
Future<CommunityCommentModel> createComment(
  String communityId,
  String postId, {
  required String body,
  String? parentId, // THÊM MỚI
});
```

**Step 2: Gửi parentId trong API implementation**

```dart
@override
Future<CommunityCommentModel> createComment(
  String communityId,
  String postId, {
  required String body,
  String? parentId,
}) async {
  try {
    final response = await _dioClient.dio.post(
      '/communities/$communityId/posts/$postId/comments',
      data: {
        'body': body.trim(),
        if (parentId != null) 'parentId': parentId, // THÊM MỚI
      },
    );
    // ... parse response
  }
}
```

**Verification:** `flutter analyze` trên cả 2 file

---

### Task 2.3: UI reply phân cấp trong _CommentSheet

**Objective:** Hiển thị reply thụt lề với đường kẻ nhánh

**Files:**
- Modify: `lib/features/community/social/widgets/community_post_card.dart`

**Step 1: Tách root comments và replies**

```dart
// Trong _CommentSheetState.build():
final rootComments = _comments.where((c) => c.parentId == null).toList();
final replyMap = <String, List<CommunityCommentModel>>{};
for (final c in _comments) {
  if (c.parentId != null) {
    replyMap.putIfAbsent(c.parentId!, () => []).add(c);
  }
}
```

**Step 2: Render với indent và branch line**

```dart
Widget buildCommentItem(CommunityCommentModel comment, {bool isReply = false}) {
  return Padding(
    padding: EdgeInsets.only(left: isReply ? 32 : 0),
    child: Stack(
      children: [
        if (isReply)
          Positioned(
            left: 12,
            top: 0,
            bottom: 0,
            child: Container(width: 2, color: Colors.grey.shade300),
          ),
        ListTile(
          dense: isReply,
          leading: CircleAvatar(
            radius: isReply ? 13 : 16,
            backgroundImage: comment.authorAvatar != null
                ? NetworkImage(comment.authorAvatar!)
                : null,
            child: comment.authorAvatar == null
                ? Text(comment.authorName[0].toUpperCase())
                : null,
          ),
          title: Text(comment.authorName, style: TextStyle(fontSize: isReply ? 13 : 15)),
          subtitle: Text(comment.body),
          trailing: isReply && (comment.authorId == widget.currentUserId || widget.isModerator)
              ? IconButton(
                  onPressed: () => _deleteComment(comment.id),
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                )
              : null,
        ),
      ],
    ),
  );
}
```

**Step 3: Thêm nút "Trả lời" và state replyingTo**

```dart
String? _replyingToId;

// Trong ListTile của root comment:
TextButton(
  onPressed: () {
    setState(() {
      _replyingToId = comment.id;
      _controller.text = '@${comment.authorName} ';
    });
  },
  child: const Text('Trả lời'),
),

// Hiển thị replies:
if (replyMap[comment.id] != null)
  ...replyMap[comment.id]!.map((reply) => buildCommentItem(reply, isReply: true)),
```

**Step 4: Gửi comment với parentId**

```dart
Future<void> _submit() async {
  if (_sending || _controller.text.trim().isEmpty) return;
  setState(() => _sending = true);
  try {
    final comment = await ref.read(communitySocialRepositoryProvider).createComment(
      widget.communityId,
      widget.postId,
      body: _controller.text.trim(),
      parentId: _replyingToId, // THÊM MỚI
    );
    if (mounted) {
      setState(() {
        _comments = [..._comments, comment];
        _controller.clear();
        _replyingToId = null;
      });
    }
  } catch (_) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể gửi bình luận.')));
  } finally {
    if (mounted) setState(() => _sending = false);
  }
}
```

**Verification:**
- Chạy app, mở comment sheet
- Bấm "Trả lời" → ô input có @author
- Gửi → reply hiện thụt lề bên dưới comment gốc
- Có đường kẻ dọc bên trái

---

## PHASE 3: Poll Card

### Task 3.1: Thêm CommunityPollModel

**Objective:** Model cho poll và options

**Files:**
- Create: `lib/data/models/community_poll_model.dart`

**Step 1: Tạo model**

```dart
class CommunityPollOption {
  final String id;
  final String text;
  final int voteCount;
  final List<String> voterAvatars; // URL avatar của những người đã vote

  const CommunityPollOption({
    required this.id,
    required this.text,
    this.voteCount = 0,
    this.voterAvatars = const [],
  });

  factory CommunityPollOption.fromJson(Map<String, dynamic> json) {
    return CommunityPollOption(
      id: json['id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      voteCount: json['voteCount'] ?? json['vote_count'] ?? 0,
      voterAvatars: (json['voterAvatars'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

class CommunityPollModel {
  final String id;
  final String question;
  final List<CommunityPollOption> options;
  final bool allowMultipleAnswers;
  final bool allowAddOptions;
  final bool hasVoted;
  final String? viewerVoteId;

  const CommunityPollModel({
    required this.id,
    required this.question,
    required this.options,
    this.allowMultipleAnswers = false,
    this.allowAddOptions = false,
    this.hasVoted = false,
    this.viewerVoteId,
  });

  factory CommunityPollModel.fromJson(Map<String, dynamic> json) {
    return CommunityPollModel(
      id: json['id']?.toString() ?? '',
      question: json['question']?.toString() ?? '',
      options: (json['options'] as List<dynamic>?)
              ?.map((e) => CommunityPollOption.fromJson(e))
              .toList() ??
          [],
      allowMultipleAnswers: json['allowMultipleAnswers'] ?? false,
      allowAddOptions: json['allowAddOptions'] ?? false,
      hasVoted: json['hasVoted'] ?? false,
      viewerVoteId: json['viewerVoteId']?.toString(),
    );
  }
}
```

**Verification:** `flutter analyze lib/data/models/community_poll_model.dart`

---

### Task 3.2: Thêm poll vào CommunityPostModel

**Objective:** Post có thể chứa poll

**Files:**
- Modify: `lib/data/models/community_social_models.dart`

**Step 1: Thêm field poll**

```dart
// Trong CommunityPostModel:
final CommunityPollModel? poll;

// Trong fromJson:
poll: json['poll'] != null ? CommunityPollModel.fromJson(json['poll']) : null,
```

---

### Task 3.3: Thêm vote API vào repository

**Objective:** Gọi API vote poll

**Files:**
- Modify: `lib/domain/repositories/community_social_repository.dart`
- Modify: `lib/data/repositories/api/api_community_social_repository.dart`

**Step 1: Thêm method**

```dart
// Interface:
Future<void> votePoll(String communityId, String pollId, String optionId);

Future<void> addPollOption(String communityId, String pollId, String optionText);

// Implementation:
@override
Future<void> votePoll(String communityId, String pollId, String optionId) async {
  try {
    await _dioClient.dio.post('/communities/$communityId/polls/$pollId/vote', data: {'optionId': optionId});
    _log.info('Đã vote poll $pollId');
  } catch (error, stack) {
    _log.error('Không thể vote poll $pollId', error, stack);
    rethrow;
  }
}
```

---

### Task 3.4: Tạo CommunityPollWidget

**Objective:** Widget hiển thị poll với thanh progress và avatar voters

**Files:**
- Create: `lib/features/community/social/widgets/community_poll_widget.dart`

**Step 1: Tạo widget**

```dart
import 'package:flutter/material.dart';
import 'package:app_quanly_giaidau/data/models/community_poll_model.dart';

class CommunityPollWidget extends StatefulWidget {
  final CommunityPollModel poll;
  final String communityId;
  final Future<void> Function(String optionId)? onVote;

  const CommunityPollWidget({
    super.key,
    required this.poll,
    required this.communityId,
    this.onVote,
  });

  @override
  State<CommunityPollWidget> createState() => _CommunityPollWidgetState();
}

class _CommunityPollWidgetState extends State<CommunityPollWidget> {
  bool _voting = false;
  late CommunityPollModel _poll;

  @override
  void initState() {
    super.initState();
    _poll = widget.poll;
  }

  Future<void> _vote(String optionId) async {
    if (_voting || _poll.hasVoted || widget.onVote == null) return;
    setState(() => _voting = true);
    try {
      await widget.onVote!(optionId);
      setState(() {
        _poll = CommunityPollModel(
          id: _poll.id,
          question: _poll.question,
          options: _poll.options.map((o) {
            if (o.id == optionId) {
              return CommunityPollOption(
                id: o.id,
                text: o.text,
                voteCount: o.voteCount + 1,
                voterAvatars: o.voterAvatars,
              );
            }
            return o;
          }).toList(),
          allowMultipleAnswers: _poll.allowMultipleAnswers,
          allowAddOptions: _poll.allowAddOptions,
          hasVoted: true,
          viewerVoteId: optionId,
        );
      });
    } finally {
      if (mounted) setState(() => _voting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalVotes = _poll.options.fold(0, (sum, o) => sum + o.voteCount);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_poll.question, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ..._poll.options.map((option) {
              final percent = totalVotes > 0 ? (option.voteCount / totalVotes * 100).round() : 0;
              final isSelected = _poll.viewerVoteId == option.id;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: _poll.hasVoted ? null : () => _vote(option.id),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isSelected ? Colors.blue : Colors.grey.shade300, width: isSelected ? 2 : 1),
                      color: _poll.hasVoted ? Colors.grey.shade50 : null,
                    ),
                    child: Stack(
                      children: [
                        if (_poll.hasVoted)
                          Positioned.fill(
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: percent / 100,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: (isSelected ? Colors.blue : Colors.grey).withAlpha(30),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                option.text,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (_poll.hasVoted) ...[
                              Text('$percent%', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              const SizedBox(width: 8),
                              if (option.voterAvatars.isNotEmpty)
                                Row(
                                  children: option.voterAvatars.take(3).map((url) {
                                    return Padding(
                                      padding: const EdgeInsets.only(left: 2),
                                      child: CircleAvatar(radius: 10, backgroundImage: NetworkImage(url)),
                                    );
                                  }).toList(),
                                ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            if (_voting)
              const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator()),
          ],
        ),
      ),
    );
  }
}
```

**Verification:** `flutter analyze lib/features/community/social/widgets/community_poll_widget.dart`

---

### Task 3.5: Sử dụng CommunityPollWidget trong CommunityPostCard

**Objective:** Hiển thị poll nếu post có poll

**Files:**
- Modify: `lib/features/community/social/widgets/community_post_card.dart`

**Step 1: Import và render**

```dart
import 'package:app_quanly_giaidau/features/community/social/widgets/community_poll_widget.dart';

// Trong build(), sau content text:
if (post.poll != null)
  CommunityPollWidget(
    poll: post.poll!,
    communityId: communityId,
    onVote: (optionId) async {
      await ref.read(communitySocialRepositoryProvider).votePoll(communityId, post.poll!.id, optionId);
    },
  ),
```

---

## PHASE 4: Tournament Preview Card

### Task 4.1: Tạo TournamentPreviewCard widget

**Objective:** Card đặc biệt cho bài viết liên kết giải đấu

**Files:**
- Create: `lib/features/community/social/widgets/tournament_preview_card.dart`

**Step 1: Tạo widget**

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TournamentPreviewCard extends StatelessWidget {
  final String tournamentId;
  final String tournamentName;
  final String? sportName;
  final DateTime? startTime;

  const TournamentPreviewCard({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
    this.sportName,
    this.startTime,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.blue.shade200)),
      child: InkWell(
        onTap: () => context.push('/tournament/$tournamentId'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                      child: const Text('GIẢI ĐẤU CLB', style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 4),
                    Text(tournamentName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    if (sportName != null)
                      Text(sportName!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

### Task 4.2: Sử dụng TournamentPreviewCard trong CommunityPostCard

**Objective:** Hiển thị card khi `tournamentId != null`

**Files:**
- Modify: `lib/features/community/social/widgets/community_post_card.dart`

**Step 1: Import và render**

```dart
import 'package:app_quanly_giaidau/features/community/social/widgets/tournament_preview_card.dart';

// Trong build(), sau content (và sau poll nếu có):
if (post.tournamentId != null)
  TournamentPreviewCard(
    tournamentId: post.tournamentId!,
    tournamentName: post.tournamentName ?? 'Giải đấu Câu lạc bộ',
  ),
```

---

## PHASE 5: Danger Zone (Xóa CLB)

### Task 5.1: Thêm confirm name dialog vào EditClubScreen

**Objective:** Yêu cầu nhập đúng tên CLB mới cho xóa

**Files:**
- Modify: `lib/features/community/screens/edit_club_screen.dart`

**Step 1: Tạo dialog với TextField**

```dart
Future<void> _showDeleteConfirmDialog() async {
  final controller = TextEditingController();
  bool canDelete = false;

  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          title: const Text('Xóa Câu lạc bộ'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Hành động này không thể hoàn tác. Để xác nhận, hãy nhập chính xác tên CLB:'),
              const SizedBox(height: 12),
              Text(widget.clubName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Nhập tên CLB',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setDialogState(() {
                    canDelete = value.trim() == widget.clubName;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: canDelete
                  ? () async {
                      Navigator.pop(ctx);
                      // Gọi API xóa CLB
                      await ref.read(communityRepositoryProvider).deleteCommunity(widget.clubId);
                      if (mounted) {
                        context.go('/home');
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa CLB')));
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text('Xóa vĩnh viễn'),
            ),
          ],
        );
      },
    ),
  );
}
```

**Step 2: Wire vào nút Xóa**

```dart
// Thay thế onPressed hiện tại của nút Xóa:
onPressed: _showDeleteConfirmDialog,
```

---

## PHASE 6: Verification & Cleanup

### Task 6.1: Chạy flutter analyze toàn bộ feature

**Objective:** Đảm bảo không có lỗi mới

**Command:**
```bash
cd D:\Duancanhan\Project_QuanLyGiaiDau\app_quanly_giaidau
flutter analyze lib/features/community lib/data/models/community_social_models.dart lib/data/models/community_poll_model.dart lib/domain/repositories/community_social_repository.dart lib/data/repositories/api/api_community_social_repository.dart
```

**Expected:** 0 errors, warnings chỉ từ code cũ không liên quan

---

### Task 6.2: Chạy thử trên thiết bị/emulator

**Objective:** Smoke test các flow mới

**Checklist:**
- [ ] Login với user thường → thấy feed, không thấy nút xóa bài của người khác
- [ ] Login với user là tác giả → thấy nút xóa bài của mình → xóa được
- [ ] Login với user là BQT → thấy nút xóa mọi bài → xóa được
- [ ] Comment → thấy nút Trả lời → bấm → reply hiện thụt lề
- [ ] Xóa comment của mình → comment biến mất
- [ ] Post có poll → hiển thị poll → vote → % thay đổi
- [ ] Post có tournamentId → hiện card giải đấu → bấm → navigate tới trang giải
- [ ] Xóa CLB → phải nhập đúng tên mới xóa được

---

### Task 6.3: Cập nhật GRAPH_REPORT.md

**Objective:** Cập nhật đồ thị kiến thức sau khi hoàn thành

**Command:**
```bash
cd D:\Duancanhan\Project_QuanLyGiaiDau\app_quanly_giaidau
graphify update .
```

---

## Files Summary

### Created
- `lib/data/models/community_poll_model.dart`
- `lib/features/community/social/widgets/community_poll_widget.dart`
- `lib/features/community/social/widgets/tournament_preview_card.dart`

### Modified
- `lib/domain/repositories/community_social_repository.dart`
- `lib/data/repositories/api/api_community_social_repository.dart`
- `lib/data/models/community_social_models.dart`
- `lib/features/community/social/widgets/community_post_card.dart`
- `lib/features/community/social/community_social_screen.dart`
- `lib/features/community/screens/edit_club_screen.dart`

---

## Risks & Tradeoffs

| Risk | Mitigation |
|---|---|
| API endpoint `/comments/:id/delete` dùng POST thay vì DELETE | Tuân thủ backend contract đã audit |
| Poll vote có thể race condition khi nhiều user vote cùng lúc | Backend đã xử lý optimistic, UI chỉ hiển thị kết quả từ API |
| Reply phân cấp chỉ 2 cấp, không hỗ trợ tree sâu | Theo spec Execution Plan mục 4.2 |
| Danger zone yêu cầu nhập tên có thể annoy user | Nhưng cần thiết để tránh xóa nhầm |

---

## Open Questions

1. Có nên thêm tính năng "Sửa comment" không? Web chưa có, nhưng user thường mong đợi.
2. Poll có cho phép "Add option" không? Backend đã support nhưng UI có thể để phase sau.
3. Notification deeplink cho `COMMUNITY_POST_MENTIONED` cần xử lý ở app-level notification handler — có nên đưa vào phase này không?

