import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/services/chat_socket_service.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:app_quanly_giaidau/features/community/social/community_feed_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ClubChatScreen extends ConsumerStatefulWidget {
  final String communityId;
  final String communityName;

  const ClubChatScreen({
    super.key,
    required this.communityId,
    required this.communityName,
  });

  @override
  ConsumerState<ClubChatScreen> createState() => _ClubChatScreenState();
}

class _ClubChatScreenState extends ConsumerState<ClubChatScreen> {
  static const _log = AppLogger('ClubChatScreen');
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _pollTimer;
  Timer? _typingTimer;
  late final ChatSocketService _chatSocket;
  List<_ClubChatMessage> _messages = const [];
  String? _roomId;
  String? _cursor;
  bool _loading = true;
  bool _sending = false;
  bool _loadingOlder = false;
  String? _error;
  bool _socketConnected = false;
  String? _typingUser;
  final Set<String> _blockedUserIds = <String>{};
  final List<String> _selectedAttachments = <String>[];
  _ClubChatMessage? _replyingTo;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _chatSocket = ChatSocketService(ref.read(tokenManagerProvider));
    _chatSocket.onConnection = (connected) {
      if (mounted) setState(() => _socketConnected = connected);
    };
    _chatSocket.onMessage = _onSocketMessage;
    _chatSocket.onReaction = _onSocketReaction;
    _chatSocket.onRevoked = _onSocketRevoked;
    _chatSocket.onPinned = _onSocketPinned;
    _chatSocket.onTyping = (data) {
      if (mounted)
        setState(
          () => _typingUser = data['isTyping'] == true
              ? data['userId']?.toString()
              : null,
        );
    };
    _loadRoom();
    _loadBlockedUsers();
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!_socketConnected) _refreshMessages();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _typingTimer?.cancel();
    if (_roomId != null) _chatSocket.disconnect(_roomId!);
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels <= 100) _loadOlder();
  }

  Future<void> _loadRoom() async {
    try {
      final response = await ref
          .read(dioClientProvider)
          .dio
          .get(
            '/chat/rooms',
            queryParameters: {
              'type': 'CLUB',
              'communityId': widget.communityId,
            },
          );
      final payload = _asMap(response.data);
      final raw = payload['data'];
      final room = raw is List
          ? (raw.isEmpty ? const <String, dynamic>{} : _asMap(raw.first))
          : _asMap(raw ?? payload);
      final id = room['id']?.toString();
      if (id == null || id.isEmpty)
        throw const FormatException('Không tạo được phòng chat');
      if (!mounted) return;
      setState(() => _roomId = id);
      await _chatSocket.connect(id);
      await _refreshMessages(initial: true);
    } catch (error, stack) {
      _log.error('Không thể mở chat CLB', error, stack);
      if (mounted)
        setState(() {
          _loading = false;
          _error = 'Chưa thể mở trò chuyện. Thử lại sau.';
        });
    }
  }

  Future<void> _loadBlockedUsers() async {
    try {
      final response = await ref
          .read(dioClientProvider)
          .dio
          .get('/chat/blocks');
      final payload = _asMap(response.data);
      final raw = payload['data'] is List
          ? payload['data'] as List
          : const <Object?>[];
      if (mounted)
        setState(
          () => _blockedUserIds.addAll(
            raw
                .map((item) => _asMap(item)['blockedId']?.toString())
                .whereType<String>(),
          ),
        );
    } catch (_) {
      // Blocking is optional UI state; chat remains usable if this request fails.
    }
  }

  Future<void> _refreshMessages({bool initial = false}) async {
    final roomId = _roomId;
    if (roomId == null || _loadingOlder) return;
    try {
      final response = await ref
          .read(dioClientProvider)
          .dio
          .get('/chat/rooms/$roomId/messages', queryParameters: {'limit': 50});
      final payload = _asMap(response.data);
      final raw = payload['data'];
      final list = raw is List
          ? raw
          : (_asMap(raw)['items'] ?? const <Object?>[]);
      if (list is! List) return;
      final incoming = list
          .map(_ClubChatMessage.fromJson)
          .where((message) => message.id.isNotEmpty)
          .toList();
      final ids = <String>{};
      final deduped = <_ClubChatMessage>[];
      for (final message in incoming) {
        if (ids.add(message.id)) deduped.add(message);
      }
      deduped.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      final nextCursor = _asMap(payload['meta'])['nextCursor']?.toString();
      if (!mounted) return;
      setState(() {
        if (initial) {
          _messages = deduped;
          _cursor = nextCursor;
        } else {
          final knownIds = _messages.map((message) => message.id).toSet();
          _messages = [
            ..._messages,
            ...deduped.where((message) => knownIds.add(message.id)),
          ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
        }
        _loading = false;
        _error = null;
      });
      if (initial) _scrollToBottom();
      if (initial) {
        // Keep the cross-device unread state in sync as soon as the room is opened.
        try {
          await ref.read(dioClientProvider).dio.put('/chat/rooms/$roomId/read');
        } catch (error, stack) {
          // Read-state is ancillary; a transient failure must not blank a usable chat.
          _log.error(
            'KhÃ´ng thá»ƒ cáº­p nháº­t tráº¡ng thÃ¡i Ä‘Ã£ Ä‘á»c',
            error,
            stack,
          );
        }
      }
    } catch (error, stack) {
      _log.error('Không thể đồng bộ chat CLB', error, stack);
      if (mounted && initial)
        setState(() {
          _loading = false;
          _error = 'Mất kết nối. Kéo xuống để thử lại.';
        });
    }
  }

  Future<void> _loadOlder() async {
    final roomId = _roomId;
    final cursor = _cursor;
    if (roomId == null || cursor == null || cursor.isEmpty || _loadingOlder)
      return;
    setState(() => _loadingOlder = true);
    try {
      final response = await ref
          .read(dioClientProvider)
          .dio
          .get(
            '/chat/rooms/$roomId/messages',
            queryParameters: {'limit': 50, 'cursor': cursor},
          );
      final payload = _asMap(response.data);
      final raw = payload['data'];
      final list = raw is List
          ? raw
          : (_asMap(raw)['items'] ?? const <Object?>[]);
      if (list is! List) return;
      final older = list
          .map(_ClubChatMessage.fromJson)
          .where((m) => m.id.isNotEmpty)
          .toList();
      final ids = _messages.map((m) => m.id).toSet();
      if (mounted) {
        setState(() {
          _messages = [
            ...older.where((m) => !ids.contains(m.id)),
            ..._messages,
          ];
          _cursor = _asMap(payload['meta'])['nextCursor']?.toString();
        });
      }
    } catch (error, stack) {
      _log.error('Không thể tải tin cũ trong chat CLB', error, stack);
    } finally {
      if (mounted) setState(() => _loadingOlder = false);
    }
  }

  Future<void> _sendMessage() async {
    final roomId = _roomId;
    final text = _messageController.text.trim();
    if (roomId == null ||
        (text.isEmpty && _selectedAttachments.isEmpty) ||
        _sending)
      return;
    setState(() => _sending = true);
    try {
      if (_socketConnected &&
          _selectedAttachments.isEmpty &&
          _replyingTo == null) {
        _chatSocket.send(roomId, text);
      } else {
        await ref
            .read(dioClientProvider)
            .dio
            .post(
              '/chat/messages',
              data: {
                'roomId': roomId,
                if (text.isNotEmpty) 'messageText': text,
                if (_selectedAttachments.isNotEmpty)
                  'attachmentsUrls': _selectedAttachments,
                if (_replyingTo != null) 'replyToId': _replyingTo!.id,
              },
            );
      }
      _messageController.clear();
      _selectedAttachments.clear();
      _replyingTo = null;
      await _refreshMessages();
      _scrollToBottom();
    } catch (error, stack) {
      _log.error('Không thể gửi tin chat CLB', error, stack);
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gửi tin nhắn thất bại.')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pickAttachment() async {
    if (_selectedAttachments.length >= 5) return;
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    setState(() => _uploading = true);
    try {
      final url = await ref
          .read(communitySocialRepositoryProvider)
          .uploadImage(await picked.readAsBytes(), picked.name);
      if (mounted) setState(() => _selectedAttachments.add(url));
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Không thể tải ảnh lên.')));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _revokeMessage(_ClubChatMessage message) async {
    try {
      await ref
          .read(dioClientProvider)
          .dio
          .post('/chat/messages/${message.id}/revoke');
      await _refreshMessages();
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể thu hồi tin nhắn.')),
        );
    }
  }

  Future<void> _togglePin(_ClubChatMessage message) async {
    final roomId = _roomId;
    if (roomId == null) return;
    try {
      await ref
          .read(dioClientProvider)
          .dio
          .post('/chat/rooms/$roomId/messages/${message.id}/pin');
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã ghim tin nhắn.')));
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể ghim tin nhắn.')),
        );
    }
  }

  void _showMessageActions(_ClubChatMessage message) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Trả lời'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _replyingTo = message);
              },
            ),
            if (message.text.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Sao chép'),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: message.text));
                  Navigator.pop(ctx);
                },
              ),
            ListTile(
              leading: const Icon(Icons.push_pin_outlined),
              title: const Text('Ghim tin nhắn'),
              onTap: () {
                Navigator.pop(ctx);
                _togglePin(message);
              },
            ),
            if (message.senderId ==
                (ref.read(userProfileProvider).asData?.value.id ?? ''))
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Thu hồi'),
                onTap: () {
                  Navigator.pop(ctx);
                  _revokeMessage(message);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _onSocketMessage(Map<String, dynamic> data) {
    final message = _ClubChatMessage.fromJson(data);
    if (!mounted ||
        message.id.isEmpty ||
        _messages.any((item) => item.id == message.id))
      return;
    setState(
      () =>
          _messages = [..._messages, message]
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt)),
    );
    _scrollToBottom();
  }

  void _onSocketReaction(Map<String, dynamic> data) {
    final messageId = data['messageId']?.toString();
    if (!mounted || messageId == null || data['roomId']?.toString() != _roomId)
      return;
    final raw = data['reactions'];
    if (raw is! List) return;
    final reactions = raw
        .map((item) => item.toString())
        .toList(growable: false);
    setState(() {
      _messages = _messages
          .map(
            (message) => message.id == messageId
                ? message.copyWith(reactions: reactions)
                : message,
          )
          .toList(growable: false);
    });
  }

  void _onSocketRevoked(Map<String, dynamic> data) {
    final id = data['messageId']?.toString();
    if (!mounted || id == null) return;
    setState(
      () => _messages = _messages
          .map((m) => m.id == id ? m.copyWith(isRevoked: true) : m)
          .toList(growable: false),
    );
  }

  void _onSocketPinned(Map<String, dynamic> data) {
    if (!mounted || data['roomId']?.toString() != _roomId) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Phòng chat có tin nhắn vừa được ghim.')),
    );
  }

  Future<void> _toggleReaction(_ClubChatMessage message, String emoji) async {
    try {
      final response = await ref
          .read(dioClientProvider)
          .dio
          .post(
            '/chat/messages/${message.id}/reaction',
            data: {'emoji': emoji},
          );
      final payload = _asMap(response.data);
      final raw = _asMap(payload['data'] ?? payload)['reactions'];
      if (!mounted || raw is! List) return;
      final reactions = raw
          .map((item) => item.toString())
          .toList(growable: false);
      setState(() {
        _messages = _messages
            .map(
              (item) => item.id == message.id
                  ? item.copyWith(reactions: reactions)
                  : item,
            )
            .toList(growable: false);
      });
    } catch (error, stack) {
      _log.error('Không thể cập nhật cảm xúc tin nhắn', error, stack);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể thả cảm xúc lúc này.')),
        );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients)
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(title: Text(widget.communityName)),
      body: Column(
        children: [
          if (_loadingOlder) const LinearProgressIndicator(minHeight: 2),
          if (_typingUser != null)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('Đang nhập…', style: TextStyle(fontSize: 11)),
            ),
          Expanded(child: _buildMessages(colors)),
          SafeArea(child: _buildComposer(colors)),
        ],
      ),
    );
  }

  Widget _buildMessages(AppColorsExtension colors) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));
    if (_messages.isEmpty)
      return const Center(child: Text('Chưa có tin nhắn nào.'));
    final visibleMessages = _messages
        .where((message) => !_blockedUserIds.contains(message.senderId))
        .toList();
    final currentUserId = ref.watch(userProfileProvider).asData?.value.id ?? '';
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      itemCount: visibleMessages.length,
      itemBuilder: (context, index) {
        final message = visibleMessages[index];
        final isMine =
            currentUserId.isNotEmpty && message.senderId == currentUserId;
        return Align(
          alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
          child: Row(
            mainAxisAlignment: isMine
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMine) _SenderAvatar(message: message),
              Flexible(
                child: Container(
                  margin: const EdgeInsets.only(bottom: AppTheme.spacingSM),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  constraints: const BoxConstraints(maxWidth: 320),
                  decoration: BoxDecoration(
                    color: isMine ? AppTheme.primary : colors.bgCard,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    border: Border.all(
                      color: isMine ? AppTheme.primary : colors.borderLight,
                    ),
                  ),
                  child: GestureDetector(
                    onLongPress: message.id.isEmpty
                        ? null
                        : () => _showMessageActions(message),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isMine)
                          Text(
                            message.senderName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: colors.textMuted,
                            ),
                          ),
                        const SizedBox(height: 3),
                        if (message.isRevoked)
                          Text(
                            'Tin nhắn đã thu hồi',
                            style: TextStyle(
                              color: colors.textMuted,
                              fontStyle: FontStyle.italic,
                            ),
                          )
                        else
                          _buildMessageContent(message, isMine, colors),
                        if (message.reactions.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Wrap(
                            spacing: 3,
                            children: message.reactions
                                .map(
                                  (emoji) => Text(
                                    emoji,
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Thả tim',
                visualDensity: VisualDensity.compact,
                onPressed: () => _toggleReaction(message, '❤️'),
                icon: Icon(
                  message.reactions.contains('❤️')
                      ? Icons.favorite
                      : Icons.favorite_border,
                  size: 18,
                  color: colors.textMuted,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageContent(
    _ClubChatMessage message,
    bool isMine,
    AppColorsExtension colors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final url in message.attachmentsUrls)
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                url,
                width: 220,
                height: 160,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
              ),
            ),
          ),
        if (message.text.isNotEmpty)
          Text(
            message.text,
            style: TextStyle(color: isMine ? Colors.white : colors.textPrimary),
          ),
      ],
    );
  }

  Widget _buildComposer(AppColorsExtension colors) => Container(
    padding: const EdgeInsets.fromLTRB(
      AppTheme.spacingMD,
      8,
      AppTheme.spacingSM,
      8,
    ),
    decoration: BoxDecoration(
      color: colors.bgCard,
      border: Border(top: BorderSide(color: colors.borderLight)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_replyingTo != null)
          ListTile(
            dense: true,
            leading: const Icon(Icons.reply, size: 16),
            title: Text('Trả lời ${_replyingTo!.senderName}'),
            trailing: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => _replyingTo = null),
            ),
          ),
        if (_selectedAttachments.isNotEmpty)
          SizedBox(
            height: 58,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedAttachments.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) => Image.network(
                _selectedAttachments[i],
                width: 58,
                height: 58,
                fit: BoxFit.cover,
              ),
            ),
          ),
        Row(
          children: [
            IconButton(
              onPressed: _uploading ? null : _pickAttachment,
              icon: _uploading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.image_outlined),
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                onChanged: _onMessageChanged,
                decoration: const InputDecoration(
                  hintText: 'Nhắn trong CLB',
                  border: InputBorder.none,
                ),
              ),
            ),
            IconButton(
              onPressed: _sending ? null : _sendMessage,
              icon: _sending
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ],
    ),
  );

  void _onMessageChanged(String value) {
    final roomId = _roomId;
    if (roomId == null || !_socketConnected) return;
    _typingTimer?.cancel();
    if (value.trim().isEmpty) {
      _chatSocket.typing(roomId, false);
      return;
    }
    _chatSocket.typing(roomId, true);
    _typingTimer = Timer(const Duration(milliseconds: 900), () {
      if (_socketConnected) _chatSocket.typing(roomId, false);
    });
  }
}

class _ClubChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime createdAt;
  final String? senderAvatarUrl;
  final List<String> reactions;
  final List<String> attachmentsUrls;
  final bool isRevoked;

  const _ClubChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.createdAt,
    this.senderAvatarUrl,
    this.reactions = const [],
    this.attachmentsUrls = const [],
    this.isRevoked = false,
  });

  _ClubChatMessage copyWith({List<String>? reactions, bool? isRevoked}) =>
      _ClubChatMessage(
        id: id,
        senderId: senderId,
        senderName: senderName,
        text: text,
        createdAt: createdAt,
        senderAvatarUrl: senderAvatarUrl,
        reactions: reactions ?? this.reactions,
        attachmentsUrls: attachmentsUrls,
        isRevoked: isRevoked ?? this.isRevoked,
      );

  factory _ClubChatMessage.fromJson(Object? raw) {
    final json = _asMap(raw);
    final sender = _asMap(json['sender']);
    return _ClubChatMessage(
      id: json['id']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? sender['id']?.toString() ?? '',
      senderName:
          json['senderName']?.toString() ??
          sender['displayName']?.toString() ??
          'Thành viên CLB',
      text: (json['messageText'] ?? json['content'] ?? '').toString(),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      senderAvatarUrl:
          json['senderAvatarUrl']?.toString() ??
          json['senderAvatar']?.toString() ??
          sender['avatarUrl']?.toString(),
      attachmentsUrls: (json['attachmentsUrls'] ?? json['mediaUrls']) is List
          ? ((json['attachmentsUrls'] ?? json['mediaUrls']) as List)
                .map((item) => item.toString())
                .toList(growable: false)
          : const [],
      isRevoked: json['isRevoked'] == true,
      reactions: json['reactions'] is List
          ? (json['reactions'] as List)
                .map((item) => item.toString())
                .toList(growable: false)
          : const [],
    );
  }
}

class _SenderAvatar extends StatelessWidget {
  const _SenderAvatar({required this.message});
  final _ClubChatMessage message;
  @override
  Widget build(BuildContext context) {
    final url = message.senderAvatarUrl;
    return Padding(
      padding: const EdgeInsets.only(right: 6, bottom: 8),
      child: CircleAvatar(
        radius: 15,
        backgroundColor: AppTheme.primary,
        backgroundImage: url == null || url.isEmpty ? null : NetworkImage(url),
        child: url == null || url.isEmpty
            ? Text(
                message.senderName.trim().isEmpty
                    ? '?'
                    : message.senderName.trim()[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              )
            : null,
      ),
    );
  }
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map)
    return value.map((key, item) => MapEntry(key.toString(), item));
  return const <String, dynamic>{};
}
