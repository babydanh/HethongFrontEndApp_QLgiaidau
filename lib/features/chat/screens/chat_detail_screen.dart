import 'dart:async';
import 'package:dio/dio.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/core/services/chat_socket_service.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/data/models/chat_models.dart';
import 'package:app_quanly_giaidau/features/chat/widgets/chat_poll_dialog.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

const List<String> _kQuickReactions = ['❤️', '👍', '😂', '😮', '😢', '🔥'];

class ChatDetailScreen extends ConsumerStatefulWidget {
  final String roomId;
  final String? roomName;
  final String? roomAvatar;
  final String? roomType;
  final String? communityId;

  const ChatDetailScreen({
    super.key,
    required this.roomId,
    this.roomName,
    this.roomAvatar,
    this.roomType,
    this.communityId,
  });

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  List<ChatMessageModel> _messages = [];
  ChatMessageModel? _pinnedMessage;
  ChatMessageModel? _replyingTo;
  final List<String> _pendingMedia = [];

  bool _isLoading = true;
  bool _isSending = false;
  bool _hasMore = true;
  String? _cursor;
  String? _typingUser;
  Timer? _typingTimer;
  Timer? _pollTimer;

  late final ChatSocketService _chatSocket;
  bool _socketConnected = false;
  bool _showEmojiPicker = false;

  @override
  void initState() {
    super.initState();
    _chatSocket = ChatSocketService(ref.read(tokenManagerProvider));
    _initSocket();
    _loadInitialMessages();
    _loadPinnedMessage();
    _markAsRead();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _hasMore) {
        _loadOlderMessages();
      }
    });

    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!_socketConnected) _refreshMessages();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _typingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _chatSocket.dispose();
    super.dispose();
  }

  void _initSocket() {
    _chatSocket.onConnection = (connected) {
      if (mounted) setState(() => _socketConnected = connected);
    };
    _chatSocket.onMessage = (data) {
      if (data is Map<String, dynamic> && mounted) {
        final currentUserId = ref.read(userProfileProvider).asData?.value?.id;
        final msg = ChatMessageModel.fromJson(data, currentUserId: currentUserId);
        if (msg.roomId == widget.roomId) {
          setState(() {
            _messages.removeWhere((m) => m.id == msg.id);
            _messages.insert(0, msg);
          });
          _markAsRead();
        }
      }
    };
    _chatSocket.onReaction = (data) {
      if (data is Map<String, dynamic> && mounted) {
        final msgId = data['messageId']?.toString();
        final reactionsRaw = data['reactions'];
        if (msgId != null && reactionsRaw is List) {
          setState(() {
            final idx = _messages.indexWhere((m) => m.id == msgId);
            if (idx != -1) {
              final currentUserId = ref.read(userProfileProvider).asData?.value?.id;
              final reactionsList = reactionsRaw
                  .whereType<Map<String, dynamic>>()
                  .map((r) => ChatReactionModel.fromJson(r, currentUserId: currentUserId))
                  .toList();
              _messages[idx] = _messages[idx].copyWith(reactions: reactionsList);
            }
          });
        }
      }
    };
    _chatSocket.onRevoked = (data) {
      if (data is Map<String, dynamic> && mounted) {
        final msgId = data['messageId']?.toString();
        if (msgId != null) {
          setState(() {
            final idx = _messages.indexWhere((m) => m.id == msgId);
            if (idx != -1) {
              _messages[idx] = _messages[idx].copyWith(isRevoked: true, content: 'Tin nhắn đã bị thu hồi');
            }
          });
        }
      }
    };
    _chatSocket.onPinned = (data) {
      if (data is Map<String, dynamic> && mounted) {
        _loadPinnedMessage();
      }
    };
    _chatSocket.onTyping = (data) {
      if (data is Map<String, dynamic> && mounted) {
        if (data['roomId'] == widget.roomId) {
          final isTyping = data['isTyping'] == true;
          final userName = data['userName']?.toString() ?? data['userId']?.toString();
          setState(() => _typingUser = isTyping ? userName : null);
          _typingTimer?.cancel();
          if (isTyping) {
            _typingTimer = Timer(const Duration(seconds: 4), () {
              if (mounted) setState(() => _typingUser = null);
            });
          }
        }
      }
    };
  }

  Future<void> _loadInitialMessages() async {
    setState(() => _isLoading = true);
    try {
      final dio = ref.read(dioClientProvider).dio;
      final currentUserId = ref.read(userProfileProvider).asData?.value?.id;
      final res = await dio.get('/chat/rooms/${widget.roomId}/messages', queryParameters: {'limit': 30});
      final rawList = res.data is Map ? (res.data['data'] ?? res.data['items'] ?? []) : res.data;
      if (rawList is List && mounted) {
        final items = rawList
            .whereType<Map<String, dynamic>>()
            .map((json) => ChatMessageModel.fromJson(json, currentUserId: currentUserId))
            .toList();
        setState(() {
          _messages = items;
          _hasMore = items.length >= 30;
          _cursor = items.isNotEmpty ? items.last.id : null;
        });
      }
    } catch (_) {
      // Fallback
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadOlderMessages() async {
    if (_cursor == null || !_hasMore) return;
    try {
      final dio = ref.read(dioClientProvider).dio;
      final currentUserId = ref.read(userProfileProvider).asData?.value?.id;
      final res = await dio.get(
        '/chat/rooms/${widget.roomId}/messages',
        queryParameters: {'limit': 30, 'cursor': _cursor},
      );
      final rawList = res.data is Map ? (res.data['data'] ?? res.data['items'] ?? []) : res.data;
      if (rawList is List && mounted) {
        final older = rawList
            .whereType<Map<String, dynamic>>()
            .map((json) => ChatMessageModel.fromJson(json, currentUserId: currentUserId))
            .toList();
        setState(() {
          _messages.addAll(older);
          _hasMore = older.length >= 30;
          _cursor = older.isNotEmpty ? older.last.id : null;
        });
      }
    } catch (_) {}
  }

  Future<void> _refreshMessages() async {
    try {
      final dio = ref.read(dioClientProvider).dio;
      final currentUserId = ref.read(userProfileProvider).asData?.value?.id;
      final res = await dio.get('/chat/rooms/${widget.roomId}/messages', queryParameters: {'limit': 30});
      final rawList = res.data is Map ? (res.data['data'] ?? res.data['items'] ?? []) : res.data;
      if (rawList is List && mounted) {
        final items = rawList
            .whereType<Map<String, dynamic>>()
            .map((json) => ChatMessageModel.fromJson(json, currentUserId: currentUserId))
            .toList();
        setState(() => _messages = items);
      }
    } catch (_) {}
  }

  Future<void> _loadPinnedMessage() async {
    try {
      final dio = ref.read(dioClientProvider).dio;
      final currentUserId = ref.read(userProfileProvider).asData?.value?.id;
      final res = await dio.get('/chat/rooms/${widget.roomId}/pinned');
      final data = res.data is Map ? (res.data['data'] ?? res.data) : null;
      if (data is Map<String, dynamic> && mounted) {
        setState(() => _pinnedMessage = ChatMessageModel.fromJson(data, currentUserId: currentUserId));
      } else if (mounted) {
        setState(() => _pinnedMessage = null);
      }
    } catch (_) {}
  }

  Future<void> _markAsRead() async {
    try {
      final dio = ref.read(dioClientProvider).dio;
      await dio.put('/chat/rooms/${widget.roomId}/read', data: {});
    } catch (_) {}
  }

  Future<void> _sendMessage({String? customContent, Map<String, dynamic>? pollData}) async {
    final text = (customContent ?? _messageController.text).trim();
    if (text.isEmpty && _pendingMedia.isEmpty && pollData == null) return;
    if (_isSending) return;

    setState(() => _isSending = true);
    final replyId = _replyingTo?.id;
    final media = [..._pendingMedia];

    _messageController.clear();
    setState(() {
      _replyingTo = null;
      _pendingMedia.clear();
    });

    try {
      final dio = ref.read(dioClientProvider).dio;
      final payload = <String, dynamic>{
        'roomId': widget.roomId,
        'messageText': text,
        if (media.isNotEmpty) 'mediaUrls': media,
        if (replyId != null) 'replyToId': replyId,
        if (pollData != null) 'poll': pollData,
      };

      final res = await dio.post('/chat/messages', data: payload);
      final currentUserId = ref.read(userProfileProvider).asData?.value?.id;
      final raw = res.data is Map ? (res.data['data'] ?? res.data) : null;
      if (raw is Map<String, dynamic> && mounted) {
        final newMsg = ChatMessageModel.fromJson(raw, currentUserId: currentUserId);
        setState(() {
          _messages.removeWhere((m) => m.id == newMsg.id);
          _messages.insert(0, newMsg);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorParser.parse(e, 'Không thể gửi tin nhắn.'))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _sendThumbsUp() async {
    await _sendMessage(customContent: '👍');
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 85);
      if (picked == null) return;

      setState(() => _isSending = true);
      final dio = ref.read(dioClientProvider).dio;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(picked.path, filename: picked.name),
      });
      final res = await dio.post('/upload/image', data: formData);
      final url = res.data is Map ? (res.data['url'] ?? res.data['data']?['url']) : null;
      if (url is String && mounted) {
        setState(() => _pendingMedia.add(url));
        await _sendMessage();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể tải ảnh lên.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _openCreatePollDialog() async {
    final poll = await ChatPollDialog.show(context);
    if (poll != null) {
      await _sendMessage(pollData: poll);
    }
  }

  Future<void> _reactToMessage(ChatMessageModel message, String emoji) async {
    try {
      final dio = ref.read(dioClientProvider).dio;
      final res = await dio.post('/chat/messages/${message.id}/reaction', data: {'emoji': emoji});
      final currentUserId = ref.read(userProfileProvider).asData?.value?.id;
      final raw = res.data is Map ? res.data['data'] : null;
      if (raw is Map<String, dynamic> && raw['reactions'] is List && mounted) {
        final reactionsList = (raw['reactions'] as List)
            .whereType<Map<String, dynamic>>()
            .map((r) => ChatReactionModel.fromJson(r, currentUserId: currentUserId))
            .toList();
        setState(() {
          final idx = _messages.indexWhere((m) => m.id == message.id);
          if (idx != -1) {
            _messages[idx] = _messages[idx].copyWith(reactions: reactionsList);
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _votePoll(ChatMessageModel message, String optionId) async {
    try {
      final dio = ref.read(dioClientProvider).dio;
      final res = await dio.post('/chat/messages/${message.id}/poll/vote', data: {'optionId': optionId});
      final currentUserId = ref.read(userProfileProvider).asData?.value?.id;
      final raw = res.data is Map ? res.data['data'] : null;
      if (raw is Map<String, dynamic> && raw['poll'] is Map && mounted) {
        final updatedPoll = ChatPollModel.fromJson(raw['poll'] as Map<String, dynamic>, currentUserId: currentUserId);
        setState(() {
          final idx = _messages.indexWhere((m) => m.id == message.id);
          if (idx != -1) {
            _messages[idx] = _messages[idx].copyWith(poll: updatedPoll);
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _togglePinMessage(ChatMessageModel message) async {
    try {
      final dio = ref.read(dioClientProvider).dio;
      if (message.isPinned) {
        await dio.delete('/chat/rooms/${widget.roomId}/messages/${message.id}/pin');
      } else {
        await dio.post('/chat/rooms/${widget.roomId}/messages/${message.id}/pin');
      }
      _loadPinnedMessage();
      _refreshMessages();
    } catch (_) {}
  }

  Future<void> _revokeMessage(ChatMessageModel message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thu hồi tin nhắn?'),
        content: const Text('Tin nhắn này sẽ bị gỡ bỏ đối với tất cả mọi người trong phòng chat.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Thu hồi'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final dio = ref.read(dioClientProvider).dio;
      await dio.post('/chat/messages/${message.id}/revoke');
      setState(() {
        final idx = _messages.indexWhere((m) => m.id == message.id);
        if (idx != -1) {
          _messages[idx] = _messages[idx].copyWith(isRevoked: true, content: 'Tin nhắn đã bị thu hồi');
        }
      });
    } catch (_) {}
  }

  void _showMessageOptions(ChatMessageModel message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        final colors = context.colors;
        return Container(
          decoration: BoxDecoration(
            color: colors.bgCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Emoji Reaction Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _kQuickReactions.map((emoji) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(sheetCtx);
                        _reactToMessage(message, emoji);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colors.bgSurface,
                          shape: BoxShape.circle,
                        ),
                        child: Text(emoji, style: const TextStyle(fontSize: 24)),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const Divider(height: 16),
              ListTile(
                leading: const Icon(Icons.reply_rounded),
                title: const Text('Trả lời'),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  setState(() => _replyingTo = message);
                  _focusNode.requestFocus();
                },
              ),
              if (message.content.isNotEmpty && !message.isRevoked)
                ListTile(
                  leading: const Icon(Icons.copy_rounded),
                  title: const Text('Sao chép văn bản'),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    Clipboard.setData(ClipboardData(text: message.content));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã sao chép vào bộ nhớ tạm.')),
                    );
                  },
                ),
              ListTile(
                leading: Icon(message.isPinned ? Icons.push_pin_outlined : Icons.push_pin_rounded),
                title: Text(message.isPinned ? 'Bỏ ghim tin nhắn' : 'Ghim tin nhắn'),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _togglePinMessage(message);
                },
              ),
              if (message.isMine && !message.isRevoked)
                ListTile(
                  leading: Icon(Icons.delete_outline_rounded, color: colors.error),
                  title: Text('Thu hồi tin nhắn', style: TextStyle(color: colors.error)),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    _revokeMessage(message);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _showMediaGallery(String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: Image.network(url, fit: BoxFit.contain),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateSeparator(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return 'Hôm nay';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (dt.year == yesterday.year && dt.month == yesterday.month && dt.day == yesterday.day) {
      return 'Hôm qua';
    }
    return DateFormat('EEEE, dd/MM/yyyy', 'vi_VN').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = widget.roomName ?? 'Phòng chat';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF18191A) : const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: colors.bgCard,
        elevation: 0.5,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 19,
                  backgroundColor: AppTheme.primaryLight,
                  backgroundImage: widget.roomAvatar != null && widget.roomAvatar!.isNotEmpty
                      ? NetworkImage(widget.roomAvatar!)
                      : null,
                  child: widget.roomAvatar == null || widget.roomAvatar!.isEmpty
                      ? Text(
                          title.characters.first.toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                        )
                      : null,
                ),
                Positioned(
                  bottom: -1,
                  right: -1,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.bgCard, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _typingUser != null ? '$_typingUser đang soạn tin...' : 'Đang hoạt động',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: _typingUser != null ? AppTheme.primary : colors.textMuted,
                      fontWeight: _typingUser != null ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.poll_outlined, size: 22),
            tooltip: 'Tạo bình chọn',
            onPressed: _openCreatePollDialog,
          ),
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, size: 22),
            tooltip: 'Thông tin',
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Sticky Pinned Banner ──
          if (_pinnedMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2D261A) : const Color(0xFFFEF3C7),
                border: Border(bottom: BorderSide(color: Colors.amber.withValues(alpha: 0.3))),
              ),
              child: Row(
                children: [
                  const Icon(Icons.push_pin_rounded, size: 16, color: Color(0xFFD97706)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tin nhắn đã ghim từ ${_pinnedMessage!.senderName}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                        ),
                        Text(
                          _pinnedMessage!.content,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: isDark ? Colors.white70 : const Color(0xFF78350F),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // ── Message Stream ──
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.forum_outlined, size: 54, color: colors.textMuted.withValues(alpha: 0.4)),
                            const SizedBox(height: 12),
                            Text('Chưa có tin nhắn nào.', style: TextStyle(color: colors.textMuted, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text('Hãy gửi tin nhắn đầu tiên để bắt đầu trò chuyện!', style: TextStyle(color: colors.textMuted.withValues(alpha: 0.7), fontSize: 12)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final prevMsg = index < _messages.length - 1 ? _messages[index + 1] : null;
                          final showDate = prevMsg == null ||
                              msg.createdAt.day != prevMsg.createdAt.day ||
                              msg.createdAt.month != prevMsg.createdAt.month;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (showDate)
                                Center(
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(vertical: 14),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: colors.bgCard.withValues(alpha: 0.8),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      _formatDateSeparator(msg.createdAt),
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colors.textMuted),
                                    ),
                                  ),
                                ),
                              _buildMessageBubble(msg, colors, isDark),
                            ],
                          );
                        },
                      ),
          ),

          // ── Typing Indicator ──
          if (_typingUser != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              alignment: Alignment.centerLeft,
              child: Text(
                '$_typingUser đang soạn tin...',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: colors.textMuted),
              ),
            ),

          // ── Reply Banner ──
          if (_replyingTo != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: colors.bgCard,
                border: Border(top: BorderSide(color: colors.borderLight)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.reply_rounded, size: 18, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trả lời ${_replyingTo!.senderName}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary),
                        ),
                        Text(
                          _replyingTo!.content.isEmpty ? '[Hình ảnh / Bình chọn]' : _replyingTo!.content,
                          style: TextStyle(fontSize: 12, color: colors.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, size: 18, color: colors.textMuted),
                    onPressed: () => setState(() => _replyingTo = null),
                  ),
                ],
              ),
            ),

          // ── Bottom Composer ──
          Container(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            decoration: BoxDecoration(
              color: colors.bgCard,
              border: Border(top: BorderSide(color: colors.borderLight.withValues(alpha: 0.6))),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Attachment Icon Button
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.image_outlined, color: AppTheme.primary, size: 22),
                    tooltip: 'Gửi ảnh',
                    onPressed: () => _pickImage(ImageSource.gallery),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.camera_alt_outlined, color: AppTheme.primary, size: 22),
                    tooltip: 'Chụp ảnh',
                    onPressed: () => _pickImage(ImageSource.camera),
                  ),

                  // Pill TextField
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: TextField(
                        controller: _messageController,
                        focusNode: _focusNode,
                        minLines: 1,
                        maxLines: 5,
                        style: const TextStyle(fontSize: 14.5),
                        onChanged: (v) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Nhắn tin...',
                          hintStyle: TextStyle(color: colors.textMuted, fontSize: 14.5),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Send or Thumbs-up Button
                  if (_messageController.text.trim().isNotEmpty || _pendingMedia.isNotEmpty)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: Icon(Icons.send_rounded, color: _isSending ? colors.textMuted : AppTheme.primary, size: 22),
                      tooltip: 'Gửi',
                      onPressed: _isSending ? null : () => _sendMessage(),
                    )
                  else
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.thumb_up_rounded, color: AppTheme.primary, size: 22),
                      tooltip: 'Thích',
                      onPressed: _sendThumbsUp,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageModel msg, AppColorsExtension colors, bool isDark) {
    final isMine = msg.isMine;
    final bubbleBg = isMine
        ? AppTheme.primary
        : (isDark ? const Color(0xFF3A3B3C) : const Color(0xFFFFFFFF));
    final textColor = isMine ? Colors.white : colors.textPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Other's Avatar
          if (!isMine) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: AppTheme.primaryLight,
              backgroundImage: msg.senderAvatarUrl != null ? NetworkImage(msg.senderAvatarUrl!) : null,
              child: msg.senderAvatarUrl == null
                  ? Text(
                      msg.senderName.characters.first.toUpperCase(),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],

          // Bubble Container
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showMessageOptions(msg),
              child: Column(
                crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  // Sender name in group/club chats
                  if (!isMine && (widget.roomType == 'CLUB' || widget.roomType == 'GROUP'))
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 2),
                      child: Text(
                        msg.senderName,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colors.textMuted),
                      ),
                    ),

                  Container(
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.76),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: bubbleBg,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isMine ? 18 : 4),
                        bottomRight: Radius.circular(isMine ? 4 : 18),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Quoted Reply Preview
                        if (msg.replyToMessage != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isMine ? Colors.white.withValues(alpha: 0.2) : colors.bgSurface,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  msg.replyToMessage!.senderName,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isMine ? Colors.white : AppTheme.primary,
                                  ),
                                ),
                                Text(
                                  msg.replyToMessage!.content.isEmpty
                                      ? '[Hình ảnh]'
                                      : msg.replyToMessage!.content,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: isMine ? Colors.white70 : colors.textMuted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                        // Media Images Grid
                        if (msg.mediaUrls.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: msg.mediaUrls.map((url) {
                                  return GestureDetector(
                                    onTap: () => _showMediaGallery(url),
                                    child: Image.network(
                                      url,
                                      width: msg.mediaUrls.length == 1 ? 220 : 105,
                                      height: msg.mediaUrls.length == 1 ? 180 : 105,
                                      fit: BoxFit.cover,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),

                        // In-chat Poll Card
                        if (msg.poll != null) _buildPollCard(msg, msg.poll!, colors, isMine),

                        // Text Content
                        if (msg.content.isNotEmpty)
                          Text(
                            msg.content,
                            style: TextStyle(
                              fontSize: 14.5,
                              height: 1.35,
                              fontStyle: msg.isRevoked ? FontStyle.italic : FontStyle.normal,
                              color: msg.isRevoked ? (isMine ? Colors.white70 : colors.textMuted) : textColor,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Reactions Badge Row
                  if (msg.reactions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Wrap(
                        spacing: 4,
                        children: msg.reactions.map((r) {
                          return GestureDetector(
                            onTap: () => _reactToMessage(msg, r.emoji),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: colors.bgCard,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: r.isReacted ? AppTheme.primary : colors.borderLight,
                                  width: r.isReacted ? 1.2 : 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(r.emoji, style: const TextStyle(fontSize: 12)),
                                  if (r.count > 1) ...[
                                    const SizedBox(width: 3),
                                    Text('${r.count}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colors.textPrimary)),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPollCard(ChatMessageModel msg, ChatPollModel poll, AppColorsExtension colors, bool isMine) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMine ? Colors.white.withValues(alpha: 0.15) : colors.bgSurface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.poll_rounded, color: AppTheme.primary, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  poll.question,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isMine ? Colors.white : colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...poll.options.map((opt) {
            final percent = poll.totalVotes > 0 ? (opt.voteCount / poll.totalVotes) : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => _votePoll(msg, opt.id),
                child: Stack(
                  children: [
                    Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: isMine ? Colors.white.withValues(alpha: 0.1) : colors.bgCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: opt.isVoted ? AppTheme.primary : colors.borderLight,
                          width: opt.isVoted ? 1.5 : 1,
                        ),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: percent > 0 ? percent : 0.01,
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: opt.isVoted ? AppTheme.primary.withValues(alpha: 0.35) : colors.borderLight.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          if (opt.isVoted)
                            const Padding(
                              padding: EdgeInsets.only(right: 6),
                              child: Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 16),
                            ),
                          Expanded(
                            child: Text(
                              opt.optionText,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: opt.isVoted ? FontWeight.bold : FontWeight.w500,
                                color: isMine ? Colors.white : colors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${(percent * 100).toInt()}% (${opt.voteCount})',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isMine ? Colors.white70 : colors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
