import 'dart:async';
import 'package:dio/dio.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/core/services/chat_socket_service.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/data/models/chat_models.dart';
import 'package:app_quanly_giaidau/data/models/community_social_models.dart';
import 'package:app_quanly_giaidau/features/chat/widgets/chat_poll_dialog.dart';
import 'package:app_quanly_giaidau/features/chat/widgets/chat_room_settings_sheet.dart';
import 'package:app_quanly_giaidau/features/chat/widgets/chat_reaction_detail_sheet.dart';
import 'package:app_quanly_giaidau/features/chat/widgets/chat_image_viewer.dart';
import 'package:app_quanly_giaidau/features/community/widgets/member_tag_chip.dart';
import 'package:app_quanly_giaidau/providers/community_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
  List<ChatParticipant> _participants = [];
  final Set<String> _onlineUserIds = {};
  final Map<String, DateTime> _userReadTimestamps = {};
  bool _showScrollToBottom = false;
  String? _highlightedMessageId;
  Timer? _highlightTimer;

  bool _isLoading = true;
  bool _isSending = false;
  bool _hasMore = true;
  String? _cursor;
  String? _typingUser;
  Timer? _typingTimer;
  Timer? _pollTimer;

  late final ChatSocketService _chatSocket;
  bool _socketConnected = false;

  @override
  void initState() {
    super.initState();
    _chatSocket = ChatSocketService(ref.read(tokenManagerProvider));
    _initSocket();
    _loadInitialMessages();
    _loadPinnedMessage();
    _loadRoomDetails();
    _markAsRead();

    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        final show = _scrollController.offset > 200;
        if (show != _showScrollToBottom) {
          setState(() => _showScrollToBottom = show);
        }
        if (_scrollController.position.pixels >=
                _scrollController.position.maxScrollExtent - 200 &&
            !_isLoading &&
            _hasMore) {
          _loadOlderMessages();
        }
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
    _highlightTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _chatSocket.dispose();
    super.dispose();
  }

  void _initSocket() {
    _chatSocket.onConnection = (connected) {
      if (mounted) {
        setState(() => _socketConnected = connected);
        if (connected && _participants.isNotEmpty) {
          _chatSocket.checkOnlineUsers(
            _participants.map((p) => p.id).toList(),
            (statusMap) {
              if (mounted && statusMap.isNotEmpty) {
                setState(() {
                  for (final entry in statusMap.entries) {
                    if (entry.value == true) {
                      _onlineUserIds.add(entry.key);
                    } else {
                      _onlineUserIds.remove(entry.key);
                    }
                  }
                });
              }
            },
          );
        }
      }
    };
    _chatSocket.onMessage = (data) {
      if (mounted) {
        final currentUserId = ref.read(userProfileProvider).asData?.value.id;
        final msg = ChatMessageModel.fromJson(
          data,
          currentUserId: currentUserId,
        );
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
      if (mounted) {
        final msgId = data['messageId']?.toString();
        final reactionsRaw = data['reactions'];
        if (msgId != null && reactionsRaw is List) {
          final parsedReactions = <ChatReactionModel>[];
          final emojiCounts = <String, int>{};
          final userReactedMap = <String, bool>{};

          for (final item in reactionsRaw) {
            if (item is String) {
              emojiCounts[item] = (emojiCounts[item] ?? 0) + 1;
              if (item == data['emoji']) userReactedMap[item] = true;
            } else if (item is Map<String, dynamic>) {
              final em = (item['emoji'] ?? '').toString();
              final count = (item['count'] as num?)?.toInt() ?? 1;
              if (em.isNotEmpty) {
                emojiCounts[em] = count;
                userReactedMap[em] = item['isReacted'] == true;
              }
            }
          }

          emojiCounts.forEach((em, count) {
            parsedReactions.add(
              ChatReactionModel(
                emoji: em,
                count: count,
                isReacted: userReactedMap[em] ?? false,
              ),
            );
          });

          setState(() {
            final idx = _messages.indexWhere((m) => m.id == msgId);
            if (idx != -1) {
              _messages[idx] = _messages[idx].copyWith(
                reactions: parsedReactions,
              );
            }
          });
        }
      }
    };
    _chatSocket.onRevoked = (data) {
      if (mounted) {
        final msgId = data['messageId']?.toString();
        if (msgId != null) {
          setState(() {
            final idx = _messages.indexWhere((m) => m.id == msgId);
            if (idx != -1) {
              _messages[idx] = _messages[idx].copyWith(
                isRevoked: true,
                content: 'Tin nhắn đã bị thu hồi',
              );
            }
          });
        }
      }
    };
    _chatSocket.onPinned = (data) {
      if (mounted) {
        _loadPinnedMessage();
      }
    };
    _chatSocket.onUserStatus = (data) {
      if (mounted) {
        final uid = data['userId']?.toString();
        final isOnline = data['isOnline'] == true;
        if (uid != null) {
          setState(() {
            if (isOnline) {
              _onlineUserIds.add(uid);
            } else {
              _onlineUserIds.remove(uid);
            }
          });
        }
      }
    };
    _chatSocket.onRoomRead = (data) {
      if (mounted) {
        final uid = data['userId']?.toString();
        final readAtStr = data['readAt']?.toString();
        if (uid != null && readAtStr != null) {
          final dt = DateTime.tryParse(readAtStr);
          if (dt != null) {
            setState(() => _userReadTimestamps[uid] = dt);
          }
        }
      }
    };
    _chatSocket.onTyping = (data) {
      if (mounted) {
        if (data['roomId'] == widget.roomId) {
          final isTyping = data['isTyping'] == true;
          final userName =
              data['userName']?.toString() ?? data['userId']?.toString();
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
    _chatSocket.connect(widget.roomId);
  }

  Future<void> _loadRoomDetails() async {
    try {
      final dio = ref.read(dioClientProvider).dio;
      final res = await dio.get('/chat/rooms/${widget.roomId}');
      final data = res.data is Map ? (res.data['data'] ?? res.data) : null;
      if (mounted) {
        final rawParts = data['participants'];
        if (rawParts is List) {
          final list = rawParts
              .whereType<Map<String, dynamic>>()
              .map((p) => ChatParticipant.fromJson(p))
              .toList();
          setState(() {
            _participants = list;
            for (final p in list) {
              if (p.lastReadAt != null) {
                _userReadTimestamps[p.id] = p.lastReadAt!;
              }
              if (p.isOnline) {
                _onlineUserIds.add(p.id);
              }
            }
          });
          if (list.isNotEmpty && _chatSocket.isConnected) {
            _chatSocket.checkOnlineUsers(list.map((p) => p.id).toList(), (
              statusMap,
            ) {
              if (mounted && statusMap.isNotEmpty) {
                setState(() {
                  for (final entry in statusMap.entries) {
                    if (entry.value == true) {
                      _onlineUserIds.add(entry.key);
                    } else {
                      _onlineUserIds.remove(entry.key);
                    }
                  }
                });
              }
            });
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _loadInitialMessages() async {
    setState(() => _isLoading = true);
    try {
      final dio = ref.read(dioClientProvider).dio;
      final currentUserId = ref.read(userProfileProvider).asData?.value.id;
      final res = await dio.get(
        '/chat/rooms/${widget.roomId}/messages',
        queryParameters: {'limit': 30},
      );
      final rawList = res.data is Map
          ? (res.data['data'] ?? res.data['items'] ?? [])
          : res.data;
      if (rawList is List && mounted) {
        final items = rawList
            .whereType<Map<String, dynamic>>()
            .map(
              (json) =>
                  ChatMessageModel.fromJson(json, currentUserId: currentUserId),
            )
            .toList();
        // Ensure strictly sorted newest-first so ListView.builder(reverse: true) renders newest at the bottom
        items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
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
      final currentUserId = ref.read(userProfileProvider).asData?.value.id;
      final res = await dio.get(
        '/chat/rooms/${widget.roomId}/messages',
        queryParameters: {'limit': 30, 'cursor': _cursor},
      );
      final rawList = res.data is Map
          ? (res.data['data'] ?? res.data['items'] ?? [])
          : res.data;
      if (rawList is List && mounted) {
        final older = rawList
            .whereType<Map<String, dynamic>>()
            .map(
              (json) =>
                  ChatMessageModel.fromJson(json, currentUserId: currentUserId),
            )
            .toList();
        older.sort((a, b) => b.createdAt.compareTo(a.createdAt));
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
      final currentUserId = ref.read(userProfileProvider).asData?.value.id;
      final res = await dio.get(
        '/chat/rooms/${widget.roomId}/messages',
        queryParameters: {'limit': 30},
      );
      final rawList = res.data is Map
          ? (res.data['data'] ?? res.data['items'] ?? [])
          : res.data;
      if (rawList is List && mounted) {
        final items = rawList
            .whereType<Map<String, dynamic>>()
            .map(
              (json) =>
                  ChatMessageModel.fromJson(json, currentUserId: currentUserId),
            )
            .toList();
        items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        setState(() => _messages = items);
      }
    } catch (_) {}
  }

  Future<void> _loadPinnedMessage() async {
    try {
      final dio = ref.read(dioClientProvider).dio;
      final currentUserId = ref.read(userProfileProvider).asData?.value.id;
      final res = await dio.get('/chat/rooms/${widget.roomId}/pinned');
      final data = res.data is Map ? (res.data['data'] ?? res.data) : null;
      if (data is Map<String, dynamic> &&
          data['id'] != null &&
          data['id'].toString().isNotEmpty &&
          mounted) {
        final parsed = ChatMessageModel.fromJson(
          data,
          currentUserId: currentUserId,
        );
        if (parsed.id.isNotEmpty &&
            (parsed.content.trim().isNotEmpty ||
                parsed.mediaUrls.isNotEmpty ||
                parsed.poll != null)) {
          setState(() => _pinnedMessage = parsed);
        } else {
          setState(() => _pinnedMessage = null);
        }
      } else if (mounted) {
        setState(() => _pinnedMessage = null);
      }
    } catch (_) {
      if (mounted) setState(() => _pinnedMessage = null);
    }
  }

  Future<void> _markAsRead() async {
    try {
      final dio = ref.read(dioClientProvider).dio;
      await dio.put('/chat/rooms/${widget.roomId}/read', data: {});
    } catch (_) {}
  }

  String _resolveMediaUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    var rawBase = dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000/api/v1';
    if (rawBase.contains('localhost')) {
      rawBase = rawBase.replaceAll('localhost', '10.0.2.2');
    } else if (rawBase.contains('127.0.0.1')) {
      rawBase = rawBase.replaceAll('127.0.0.1', '10.0.2.2');
    }
    final host = rawBase.replaceAll(RegExp(r'/api/v1/?$'), '');
    final cleanPath = url.startsWith('/') ? url : '/$url';
    return '$host$cleanPath';
  }

  Future<void> _sendMessage({
    String? customContent,
    Map<String, dynamic>? pollData,
  }) async {
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
        if (media.isNotEmpty) ...{'attachmentsUrls': media, 'mediaUrls': media},
        'replyToId': ?replyId,
        'poll': ?pollData,
      };

      final res = await dio.post('/chat/messages', data: payload);
      final currentUserId = ref.read(userProfileProvider).asData?.value.id;
      final raw = res.data is Map ? (res.data['data'] ?? res.data) : null;
      if (raw is Map<String, dynamic> && mounted) {
        final newMsg = ChatMessageModel.fromJson(
          raw,
          currentUserId: currentUserId,
        );
        setState(() {
          _messages.removeWhere((m) => m.id == newMsg.id);
          _messages.insert(0, newMsg);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorParser.parse(e, 'Không thể gửi tin nhắn.')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _sendThumbsUp() {
    _sendMessage(customContent: '👍');
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 80);
      if (picked == null) return;

      final dio = ref.read(dioClientProvider).dio;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(picked.path),
      });
      final res = await dio.post('/upload/image', data: formData);
      final url =
          (res.data is Map
                  ? (res.data['data']?['url'] ?? res.data['url'])
                  : null)
              ?.toString();
      if (url != null && url.isNotEmpty) {
        setState(() => _pendingMedia.add(url));
        await _sendMessage();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorParser.parse(e, 'Không thể tải ảnh lên.')),
          ),
        );
      }
    }
  }

  Future<void> _openCreatePollDialog() async {
    final poll = await ChatPollDialog.show(context);
    if (poll != null) {
      await _sendMessage(pollData: poll);
    }
  }

  Future<void> _reactToMessage(ChatMessageModel message, String emoji) async {
    HapticFeedback.lightImpact();

    // 1. Optimistic Update
    final existingIdx = message.reactions.indexWhere((r) => r.emoji == emoji);
    final updatedReactions = List<ChatReactionModel>.from(message.reactions);

    if (existingIdx != -1) {
      final current = updatedReactions[existingIdx];
      if (current.isReacted) {
        if (current.count <= 1) {
          updatedReactions.removeAt(existingIdx);
        } else {
          updatedReactions[existingIdx] = ChatReactionModel(
            emoji: current.emoji,
            count: current.count - 1,
            isReacted: false,
          );
        }
      } else {
        updatedReactions[existingIdx] = ChatReactionModel(
          emoji: current.emoji,
          count: current.count + 1,
          isReacted: true,
        );
      }
    } else {
      updatedReactions.add(
        ChatReactionModel(emoji: emoji, count: 1, isReacted: true),
      );
    }

    setState(() {
      final idx = _messages.indexWhere((m) => m.id == message.id);
      if (idx != -1) {
        _messages[idx] = _messages[idx].copyWith(reactions: updatedReactions);
      }
    });

    // 2. Server Sync
    try {
      final dio = ref.read(dioClientProvider).dio;
      final res = await dio.post(
        '/chat/messages/${message.id}/reaction',
        data: {'emoji': emoji},
      );
      final raw = res.data is Map ? (res.data['data'] ?? res.data) : null;
      final rawList = raw is Map
          ? raw['reactions']
          : (raw is List ? raw : null);

      if (rawList is List && mounted) {
        final parsedReactions = <ChatReactionModel>[];
        final emojiCounts = <String, int>{};
        final userReactedMap = <String, bool>{};

        for (final item in rawList) {
          if (item is String) {
            emojiCounts[item] = (emojiCounts[item] ?? 0) + 1;
            if (item == emoji) userReactedMap[item] = true;
          } else if (item is Map<String, dynamic>) {
            final em = (item['emoji'] ?? '').toString();
            final count = (item['count'] as num?)?.toInt() ?? 1;
            if (em.isNotEmpty) {
              emojiCounts[em] = count;
              userReactedMap[em] = item['isReacted'] == true;
            }
          }
        }

        emojiCounts.forEach((em, count) {
          parsedReactions.add(
            ChatReactionModel(
              emoji: em,
              count: count,
              isReacted: userReactedMap[em] ?? (em == emoji),
            ),
          );
        });

        setState(() {
          final idx = _messages.indexWhere((m) => m.id == message.id);
          if (idx != -1) {
            _messages[idx] = _messages[idx].copyWith(
              reactions: parsedReactions,
            );
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _votePoll(ChatMessageModel message, String optionId) async {
    try {
      final dio = ref.read(dioClientProvider).dio;
      final res = await dio.post(
        '/chat/messages/${message.id}/poll/vote',
        data: {'optionId': optionId},
      );
      final currentUserId = ref.read(userProfileProvider).asData?.value.id;
      final raw = res.data is Map ? res.data['data'] : null;
      if (raw is Map<String, dynamic> && raw['poll'] is Map && mounted) {
        final updatedPoll = ChatPollModel.fromJson(
          raw['poll'] as Map<String, dynamic>,
          currentUserId: currentUserId,
        );
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
        await dio.delete(
          '/chat/rooms/${widget.roomId}/messages/${message.id}/pin',
        );
      } else {
        await dio.post(
          '/chat/rooms/${widget.roomId}/messages/${message.id}/pin',
        );
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
        content: const Text(
          'Tin nhắn này sẽ bị gỡ bỏ đối với tất cả mọi người trong phòng chat.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
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
          _messages[idx] = _messages[idx].copyWith(
            isRevoked: true,
            content: 'Tin nhắn đã bị thu hồi',
          );
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
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
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const Divider(height: 16),
              if (message.reactions.isNotEmpty)
                ListTile(
                  leading: const Icon(
                    Icons.favorite_outline_rounded,
                    color: Colors.pink,
                  ),
                  title: const Text('Xem người bày tỏ cảm xúc'),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    ChatReactionDetailSheet.show(context, message);
                  },
                ),
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
                      const SnackBar(
                        content: Text('Đã sao chép vào bộ nhớ tạm.'),
                      ),
                    );
                  },
                ),
              ListTile(
                leading: Icon(
                  message.isPinned
                      ? Icons.push_pin_outlined
                      : Icons.push_pin_rounded,
                ),
                title: Text(
                  message.isPinned ? 'Bỏ ghim tin nhắn' : 'Ghim tin nhắn',
                ),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _togglePinMessage(message);
                },
              ),
              if (message.isMine && !message.isRevoked)
                ListTile(
                  leading: Icon(
                    Icons.delete_outline_rounded,
                    color: colors.error,
                  ),
                  title: Text(
                    'Thu hồi tin nhắn',
                    style: TextStyle(color: colors.error),
                  ),
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

  void _openRoomSettings() {
    ChatRoomSettingsSheet.show(
      context,
      roomId: widget.roomId,
      roomName: widget.roomName ?? 'Phòng chat',
      roomAvatar: widget.roomAvatar,
      roomType: widget.roomType,
      communityId: widget.communityId,
      pinnedMessage: _pinnedMessage,
      messages: _messages,
      onUnpinMessage: _pinnedMessage != null
          ? () => _togglePinMessage(_pinnedMessage!)
          : null,
      onJumpToMessage: (id) => _jumpToMessage(id),
      onRoomUpdated: () {
        _refreshMessages();
        _loadPinnedMessage();
      },
    );
  }

  void _jumpToMessage(String messageId) {
    HapticFeedback.lightImpact();
    final idx = _messages.indexWhere((m) => m.id == messageId);
    if (idx != -1 && _scrollController.hasClients) {
      final targetOffset = (idx * 85.0).clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
      setState(() => _highlightedMessageId = messageId);
      _highlightTimer?.cancel();
      _highlightTimer = Timer(const Duration(milliseconds: 2000), () {
        if (mounted) setState(() => _highlightedMessageId = null);
      });
    }
  }

  void _showMediaGallery(
    String url, {
    String? senderName,
    DateTime? timestamp,
  }) {
    ChatImageViewer.show(
      context,
      imageUrl: _resolveMediaUrl(url),
      senderName: senderName,
      timestamp: timestamp,
    );
  }

  String _formatDateSeparator(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return 'Hôm nay';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (dt.year == yesterday.year &&
        dt.month == yesterday.month &&
        dt.day == yesterday.day) {
      return 'Hôm qua';
    }
    return DateFormat('EEEE, dd/MM/yyyy', 'vi_VN').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = widget.roomName ?? 'Phòng chat';
    final memberDirectory = widget.communityId == null
        ? null
        : ref.watch(communityMemberDirectoryProvider(widget.communityId!)).asData?.value;
    final tagPresets = widget.communityId == null
        ? null
        : ref.watch(communityTagPresetsProvider(widget.communityId!)).asData?.value;

    final hasValidPinned =
        _pinnedMessage != null &&
        _pinnedMessage!.id.isNotEmpty &&
        (_pinnedMessage!.content.trim().isNotEmpty ||
            _pinnedMessage!.mediaUrls.isNotEmpty ||
            _pinnedMessage!.poll != null);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF18191A)
          : const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: colors.bgCard,
        elevation: 0.5,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: GestureDetector(
          onTap: _openRoomSettings,
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 19,
                    backgroundColor: AppTheme.primaryLight,
                    backgroundImage:
                        widget.roomAvatar != null &&
                            widget.roomAvatar!.isNotEmpty
                        ? NetworkImage(widget.roomAvatar!)
                        : null,
                    child:
                        widget.roomAvatar == null || widget.roomAvatar!.isEmpty
                        ? Text(
                            title.characters.first.toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryDark,
                            ),
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
                        color:
                            _typingUser != null ||
                                (widget.roomType == 'CLUB' ||
                                        widget.roomType == 'GROUP'
                                    ? _onlineUserIds.isNotEmpty
                                    : (_participants.any(
                                        (p) =>
                                            p.id !=
                                                ref
                                                    .read(userProfileProvider)
                                                    .asData
                                                    ?.value
                                                    .id &&
                                            _onlineUserIds.contains(p.id),
                                      )))
                            ? const Color(0xFF22C55E)
                            : colors.textMuted.withValues(alpha: 0.4),
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
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _typingUser != null
                          ? '$_typingUser đang soạn tin...'
                          : (widget.roomType == 'CLUB' ||
                                    widget.roomType == 'GROUP'
                                ? (_onlineUserIds.isNotEmpty
                                      ? '${_onlineUserIds.length} người đang online'
                                      : 'Đang hoạt động')
                                : (_participants.any(
                                        (p) =>
                                            p.id !=
                                                ref
                                                    .read(userProfileProvider)
                                                    .asData
                                                    ?.value
                                                    .id &&
                                            _onlineUserIds.contains(p.id),
                                      )
                                      ? 'Đang hoạt động'
                                      : 'Hoạt động gần đây')),
                      style: TextStyle(
                        fontSize: 11.5,
                        color: _typingUser != null
                            ? AppTheme.primary
                            : colors.textMuted,
                        fontWeight: _typingUser != null
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.poll_outlined, size: 22),
            tooltip: 'Tạo bình chọn',
            onPressed: _openCreatePollDialog,
          ),
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, size: 22),
            tooltip: 'Tùy chọn & Thông báo',
            onPressed: _openRoomSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Sticky Pinned Banner (Only when valid pinned message exists) ──
          if (hasValidPinned)
            Container(
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF241E12)
                    : const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.push_pin_rounded,
                      size: 15,
                      color: Color(0xFFD97706),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _jumpToMessage(_pinnedMessage!.id),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Tin nhắn đã ghim',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFD97706),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '· ${_pinnedMessage!.senderName}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colors.textMuted,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _pinnedMessage!.content.trim().isNotEmpty
                                ? _pinnedMessage!.content.trim()
                                : (_pinnedMessage!.mediaUrls.isNotEmpty
                                      ? '📷 [Hình ảnh đính kèm]'
                                      : '📊 [Bình chọn]'),
                            style: TextStyle(
                              fontSize: 12.5,
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF78350F),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: Color(0xFFD97706),
                    ),
                    tooltip: 'Xem tin nhắn',
                    onPressed: () => _jumpToMessage(_pinnedMessage!.id),
                  ),
                ],
              ),
            ),

          // ── Message Stream ──
          Expanded(
            child: Stack(
              children: [
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.forum_outlined,
                              size: 54,
                              color: colors.textMuted.withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Chưa có tin nhắn nào.',
                              style: TextStyle(
                                color: colors.textMuted,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Hãy gửi tin nhắn đầu tiên để bắt đầu trò chuyện!',
                              style: TextStyle(
                                color: colors.textMuted.withValues(alpha: 0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final olderMsg = index < _messages.length - 1
                              ? _messages[index + 1]
                              : null;
                          final newerMsg = index > 0
                              ? _messages[index - 1]
                              : null;

                          final showDate =
                              olderMsg == null ||
                              msg.createdAt.day != olderMsg.createdAt.day ||
                              msg.createdAt.month != olderMsg.createdAt.month ||
                              msg.createdAt.year != olderMsg.createdAt.year;

                          final isFirstInGroup =
                              olderMsg == null ||
                              olderMsg.senderId != msg.senderId ||
                              showDate;

                          final isLastInGroup =
                              newerMsg == null ||
                              newerMsg.senderId != msg.senderId ||
                              (newerMsg.createdAt.day != msg.createdAt.day ||
                                  newerMsg.createdAt.month !=
                                      msg.createdAt.month ||
                                  newerMsg.createdAt.year !=
                                      msg.createdAt.year);

                          final currentUserId = ref
                              .read(userProfileProvider)
                              .asData
                              ?.value
                              .id;
                          final readers = _participants.where((p) {
                            if (p.id == currentUserId) return false;
                            final readAt = _userReadTimestamps[p.id];
                            if (readAt == null) return false;
                            final isAfterThis = !readAt.isBefore(msg.createdAt);
                            final isBeforeNewer =
                                newerMsg == null ||
                                readAt.isBefore(newerMsg.createdAt);
                            return isAfterThis && isBeforeNewer;
                          }).toList();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (showDate)
                                Center(
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colors.bgCard.withValues(
                                        alpha: 0.8,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      _formatDateSeparator(msg.createdAt),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: colors.textMuted,
                                      ),
                                    ),
                                  ),
                                ),
                              _buildMessageBubble(
                                msg,
                                colors,
                                isDark,
                                isFirstInGroup: isFirstInGroup,
                                isLastInGroup: isLastInGroup,
                                senderTags: memberDirectory?[msg.senderId]?.tags
                                        .take(AppConstants.memberTagMax)
                                        .toList(growable: false) ??
                                    const <String>[],
                                tagPresets: tagPresets,
                              ),
                              if (readers.isNotEmpty)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      top: 2,
                                      right: 8,
                                      bottom: 4,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: readers.map((p) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            left: 3,
                                          ),
                                          child: Tooltip(
                                            message: 'Đã xem bởi ${p.fullName}',
                                            child: CircleAvatar(
                                              radius: 7.5,
                                              backgroundColor:
                                                  AppTheme.primaryLight,
                                              backgroundImage:
                                                  p.avatarUrl != null &&
                                                      p.avatarUrl!.isNotEmpty
                                                  ? NetworkImage(
                                                      _resolveMediaUrl(
                                                        p.avatarUrl!,
                                                      ),
                                                    )
                                                  : null,
                                              child:
                                                  p.avatarUrl == null ||
                                                      p.avatarUrl!.isEmpty
                                                  ? Text(
                                                      p
                                                          .fullName
                                                          .characters
                                                          .first
                                                          .toUpperCase(),
                                                      style: const TextStyle(
                                                        fontSize: 7,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: AppTheme
                                                            .primaryDark,
                                                      ),
                                                    )
                                                  : null,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),

                // Floating Scroll-To-Bottom Button (↓)
                if (_showScrollToBottom)
                  Positioned(
                    right: 14,
                    bottom: 12,
                    child: GestureDetector(
                      onTap: () {
                        _scrollController.animateTo(
                          0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                        );
                      },
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: colors.bgCard,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colors.borderLight,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppTheme.primary,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Typing Indicator ──
          if (_typingUser != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              alignment: Alignment.centerLeft,
              child: Text(
                '$_typingUser đang soạn tin...',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: colors.textMuted,
                ),
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
                  const Icon(
                    Icons.reply_rounded,
                    size: 18,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trả lời ${_replyingTo!.senderName}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                        Text(
                          _replyingTo!.content.isEmpty
                              ? '[Hình ảnh / Bình chọn]'
                              : _replyingTo!.content,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: colors.textMuted,
                    ),
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
              border: Border(
                top: BorderSide(
                  color: colors.borderLight.withValues(alpha: 0.6),
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Attachment Icon Button
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.image_outlined,
                      color: AppTheme.primary,
                      size: 22,
                    ),
                    tooltip: 'Gửi ảnh',
                    onPressed: () => _pickImage(ImageSource.gallery),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.camera_alt_outlined,
                      color: AppTheme.primary,
                      size: 22,
                    ),
                    tooltip: 'Chụp ảnh',
                    onPressed: () => _pickImage(ImageSource.camera),
                  ),

                  // Pill TextField
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF3A3B3C)
                            : const Color(0xFFF0F2F5),
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
                          hintStyle: TextStyle(
                            color: colors.textMuted,
                            fontSize: 14.5,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.fromLTRB(
                            14,
                            10,
                            14,
                            10,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Send or Thumbs-up Button
                  if (_messageController.text.trim().isNotEmpty ||
                      _pendingMedia.isNotEmpty)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        Icons.send_rounded,
                        color: _isSending ? colors.textMuted : AppTheme.primary,
                        size: 22,
                      ),
                      tooltip: 'Gửi',
                      onPressed: _isSending ? null : () => _sendMessage(),
                    )
                  else
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(
                        Icons.thumb_up_rounded,
                        color: AppTheme.primary,
                        size: 22,
                      ),
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

  Widget _buildMessageBubble(
    ChatMessageModel msg,
    AppColorsExtension colors,
    bool isDark, {
    required bool isFirstInGroup,
    required bool isLastInGroup,
    required List<String> senderTags,
    List<CommunityTagPreset>? tagPresets,
  }) {
    final isMine = msg.isMine;
    final bubbleBg = isMine
        ? AppTheme.primary
        : (isDark ? const Color(0xFF3A3B3C) : const Color(0xFFFFFFFF));
    final textColor = isMine ? Colors.white : colors.textPrimary;

    final textContent = msg.content.trim();
    final hasMedia = msg.mediaUrls.isNotEmpty;
    final hasPoll = msg.poll != null;

    if (textContent.isEmpty && !hasMedia && !hasPoll) {
      return const SizedBox.shrink();
    }

    final isEmojiOnly =
        textContent.isNotEmpty &&
        textContent.characters.length <= 4 &&
        !hasMedia &&
        !hasPoll &&
        textContent.runes.every(
          (r) =>
              (r >= 0x1F600 && r <= 0x1F64F) ||
              (r >= 0x1F300 && r <= 0x1F5FF) ||
              (r >= 0x1F680 && r <= 0x1F6FF) ||
              (r >= 0x1F900 && r <= 0x1F9FF) ||
              (r >= 0x1FA70 && r <= 0x1FAFF) ||
              (r >= 0x2600 && r <= 0x27BF) ||
              r == 0x200D ||
              r == 0xFE0F ||
              r == 0x20 ||
              r == 0x0A,
        );

    return Padding(
      padding: EdgeInsets.only(
        top: isFirstInGroup ? 6 : 1.5,
        bottom: isLastInGroup ? 6 : 1.5,
      ),
      child: Row(
        mainAxisAlignment: isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Other's Avatar (only on last message of group)
          if (!isMine) ...[
            if (isLastInGroup)
              CircleAvatar(
                radius: 14,
                backgroundColor: AppTheme.primaryLight,
                backgroundImage:
                    msg.senderAvatarUrl != null &&
                        msg.senderAvatarUrl!.isNotEmpty
                    ? NetworkImage(_resolveMediaUrl(msg.senderAvatarUrl!))
                    : null,
                child:
                    msg.senderAvatarUrl == null || msg.senderAvatarUrl!.isEmpty
                    ? Text(
                        msg.senderName.characters.first.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryDark,
                        ),
                      )
                    : null,
              )
            else
              const SizedBox(width: 28),
            const SizedBox(width: 8),
          ],

          // Bubble Container
          Flexible(
            child: GestureDetector(
              onDoubleTap: () => _reactToMessage(msg, '❤️'),
              onLongPress: () => _showMessageOptions(msg),
              child: Column(
                crossAxisAlignment: isMine
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  // Sender name in group/club chats (only on first message in group)
                  if (!isMine &&
                      isFirstInGroup &&
                      (widget.roomType == 'CLUB' || widget.roomType == 'GROUP'))
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 3),
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 3,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            msg.senderName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: colors.textMuted,
                            ),
                          ),
                          ...senderTags.map(
                            (tag) => PresetTagChip(
                              label: tag,
                              color: tagPresets == null
                                  ? null
                                  : resolvePresetColor(tagPresets, tag),
                              style: PresetTagChipStyle.solid,
                            ),
                          ),
                        ],
                      ),
                    ),

                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      if (isEmojiOnly)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          child: Text(
                            textContent,
                            style: const TextStyle(fontSize: 32),
                          ),
                        )
                      else
                        Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.76,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: msg.id == _highlightedMessageId
                                ? (isMine
                                      ? AppTheme.primary
                                      : (isDark
                                            ? const Color(0xFF4A4B4D)
                                            : const Color(0xFFFFFBEB)))
                                : bubbleBg,
                            border: msg.id == _highlightedMessageId
                                ? Border.all(color: Colors.amber, width: 2)
                                : null,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(
                                !isMine && !isFirstInGroup ? 6 : 18,
                              ),
                              topRight: Radius.circular(
                                isMine && !isFirstInGroup ? 6 : 18,
                              ),
                              bottomLeft: Radius.circular(
                                !isMine && !isLastInGroup
                                    ? 6
                                    : (isMine ? 18 : 4),
                              ),
                              bottomRight: Radius.circular(
                                isMine && !isLastInGroup
                                    ? 6
                                    : (isMine ? 4 : 18),
                              ),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: msg.id == _highlightedMessageId
                                    ? Colors.amber.withValues(alpha: 0.35)
                                    : Colors.black.withValues(alpha: 0.04),
                                blurRadius: msg.id == _highlightedMessageId
                                    ? 10
                                    : 4,
                                spreadRadius: msg.id == _highlightedMessageId
                                    ? 1
                                    : 0,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Quoted Reply Preview
                              if (msg.replyToMessage != null)
                                GestureDetector(
                                  onTap: () =>
                                      _jumpToMessage(msg.replyToMessage!.id),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 6),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isMine
                                          ? Colors.white.withValues(alpha: 0.2)
                                          : colors.bgSurface,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border(
                                        left: BorderSide(
                                          color: isMine
                                              ? Colors.white
                                              : AppTheme.primary,
                                          width: 3,
                                        ),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          msg.replyToMessage!.senderName,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: isMine
                                                ? Colors.white
                                                : AppTheme.primary,
                                          ),
                                        ),
                                        Text(
                                          msg.replyToMessage!.content.isEmpty
                                              ? '[Hình ảnh / Bình chọn]'
                                              : msg.replyToMessage!.content,
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: isMine
                                                ? Colors.white70
                                                : colors.textMuted,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
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
                                        final resolved = _resolveMediaUrl(url);
                                        return GestureDetector(
                                          onTap: () => _showMediaGallery(
                                            resolved,
                                            senderName: msg.senderName,
                                            timestamp: msg.createdAt,
                                          ),
                                          child: Hero(
                                            tag: resolved,
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: Image.network(
                                                resolved,
                                                width: msg.mediaUrls.length == 1
                                                    ? 220
                                                    : 105,
                                                height:
                                                    msg.mediaUrls.length == 1
                                                    ? 180
                                                    : 105,
                                                fit: BoxFit.cover,
                                                loadingBuilder:
                                                    (ctx, child, progress) {
                                                      if (progress == null) {
                                                        return child;
                                                      }
                                                      return Container(
                                                        width:
                                                            msg
                                                                    .mediaUrls
                                                                    .length ==
                                                                1
                                                            ? 220
                                                            : 105,
                                                        height:
                                                            msg
                                                                    .mediaUrls
                                                                    .length ==
                                                                1
                                                            ? 180
                                                            : 105,
                                                        color: Colors.black12,
                                                        child: const Center(
                                                          child:
                                                              CircularProgressIndicator(
                                                                strokeWidth: 2,
                                                              ),
                                                        ),
                                                      );
                                                    },
                                                errorBuilder:
                                                    (
                                                      ctx,
                                                      err,
                                                      stack,
                                                    ) => Container(
                                                      width:
                                                          msg
                                                                  .mediaUrls
                                                                  .length ==
                                                              1
                                                          ? 220
                                                          : 105,
                                                      height:
                                                          msg
                                                                  .mediaUrls
                                                                  .length ==
                                                              1
                                                          ? 180
                                                          : 105,
                                                      color: Colors.black12,
                                                      child: const Center(
                                                        child: Icon(
                                                          Icons
                                                              .broken_image_rounded,
                                                          size: 28,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                    ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),

                              // In-chat Poll Card
                              if (msg.poll != null)
                                _buildPollCard(msg, msg.poll!, colors, isMine),

                              // Text Content
                              if (textContent.isNotEmpty)
                                Text(
                                  textContent,
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    height: 1.35,
                                    fontStyle: msg.isRevoked
                                        ? FontStyle.italic
                                        : FontStyle.normal,
                                    color: msg.isRevoked
                                        ? (isMine
                                              ? Colors.white70
                                              : colors.textMuted)
                                        : textColor,
                                  ),
                                ),

                              // Message Time
                              Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Text(
                                  DateFormat('HH:mm').format(msg.createdAt),
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    color: isMine
                                        ? Colors.white.withValues(alpha: 0.65)
                                        : colors.textMuted.withValues(
                                            alpha: 0.6,
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Floating Messenger Reaction Pill
                      if (msg.reactions.isNotEmpty)
                        Positioned(
                          bottom: -9,
                          right: isMine ? 6 : null,
                          left: isMine ? null : 6,
                          child: GestureDetector(
                            onTap: () =>
                                _reactToMessage(msg, msg.reactions.first.emoji),
                            onLongPress: () =>
                                ChatReactionDetailSheet.show(context, msg),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colors.bgCard,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: colors.borderLight,
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.12),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ...msg.reactions
                                      .take(3)
                                      .map(
                                        (r) => Text(
                                          r.emoji,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                  if (msg.reactions.fold<int>(
                                        0,
                                        (sum, r) => sum + r.count,
                                      ) >
                                      1) ...[
                                    const SizedBox(width: 3),
                                    Text(
                                      '${msg.reactions.fold<int>(0, (sum, r) => sum + r.count)}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPollCard(
    ChatMessageModel msg,
    ChatPollModel poll,
    AppColorsExtension colors,
    bool isMine,
  ) {
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
            final percent = poll.totalVotes > 0
                ? (opt.voteCount / poll.totalVotes)
                : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => _votePoll(msg, opt.id),
                child: Stack(
                  children: [
                    Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: isMine
                            ? Colors.white.withValues(alpha: 0.1)
                            : colors.bgCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: opt.isVoted
                              ? AppTheme.primary
                              : colors.borderLight,
                          width: opt.isVoted ? 1.5 : 1,
                        ),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: percent > 0 ? percent : 0.01,
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: opt.isVoted
                              ? AppTheme.primary.withValues(alpha: 0.35)
                              : colors.borderLight.withValues(alpha: 0.5),
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
                              child: Icon(
                                Icons.check_circle_rounded,
                                color: AppTheme.primary,
                                size: 16,
                              ),
                            ),
                          Expanded(
                            child: Text(
                              opt.optionText,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: opt.isVoted
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isMine
                                    ? Colors.white
                                    : colors.textPrimary,
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
