import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:intl/intl.dart';

// ─── Models ───

class Conversation {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final bool isOnline;

  const Conversation({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.isOnline = false,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
    id: json['id'] ?? '',
    name: json['name'] ?? json['title'] ?? 'Chat',
    avatarUrl: json['avatarUrl'] ?? json['avatar'],
    lastMessage: json['lastMessage'] ?? json['last_message'],
    lastMessageTime: json['lastMessageTime'] != null
        ? DateTime.tryParse(json['lastMessageTime'])
        : null,
    unreadCount: json['unreadCount'] ?? json['unread_count'] ?? 0,
    isOnline: json['isOnline'] ?? json['is_online'] ?? false,
  );
}

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String content;
  final DateTime createdAt;
  final bool isMine;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.content,
    required this.createdAt,
    this.isMine = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    return ChatMessage(
      id: json['id'] ?? '',
      senderId: json['senderId'] ?? json['userId'] ?? '',
      senderName: json['senderName'] ?? json['fullName'] ?? json['username'] ?? '',
      senderAvatar: json['senderAvatar'] ?? json['avatar'],
      content: json['content'] ?? json['message'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? json['created_at'] ?? '') ?? DateTime.now(),
      isMine: (json['senderId'] ?? json['userId'] ?? '') == currentUserId,
    );
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes}p';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return DateFormat('dd/MM').format(createdAt);
  }
}

// ─── Providers ───

final _conversationsProvider = FutureProvider<List<Conversation>>((ref) async {
  final dio = ref.read(dioClientProvider).dio;
  try {
    final response = await dio.get('/chat/conversations');
    final List<dynamic> list = response.data['data'] ?? response.data ?? [];
    return list.map((j) => Conversation.fromJson(j as Map<String, dynamic>)).toList();
  } catch (_) {
    return [];
  }
});

final _messagesProvider = FutureProvider.family<List<ChatMessage>, String>((ref, conversationId) async {
  final dio = ref.read(dioClientProvider).dio;
  try {
    final response = await dio.get('/chat/conversations/$conversationId/messages');
    final List<dynamic> list = response.data['data'] ?? response.data ?? [];
    return list.map((j) => ChatMessage.fromJson(j as Map<String, dynamic>)).toList();
  } catch (_) {
    return [];
  }
});

// ─── Chat List Screen ───

class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final conversationsAsync = ref.watch(_conversationsProvider);

    return Scaffold(
      backgroundColor: colors.bgDark,
      appBar: AppBar(
        backgroundColor: colors.bgDark,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Tin nhắn',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
      ),
      body: conversationsAsync.when(
        data: (conversations) {
          if (conversations.isEmpty) return _buildEmpty(colors);
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(_conversationsProvider),
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: conversations.length,
              itemBuilder: (ctx, i) => _buildConversationCard(context, conversations[i], colors),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _buildError(colors, ref),
      ),
    );
  }

  Widget _buildEmpty(AppColorsExtension colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colors.bgSurface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.chat_bubble_outline_rounded, size: 40, color: colors.textMuted.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có tin nhắn',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            'Các hội thoại sẽ xuất hiện tại đây',
            style: TextStyle(fontSize: 13, color: colors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildError(AppColorsExtension colors, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, size: 48, color: colors.textMuted),
          const SizedBox(height: 12),
          Text('Không thể tải danh sách tin nhắn', style: TextStyle(color: colors.textSecondary)),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => ref.refresh(_conversationsProvider),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationCard(BuildContext context, Conversation conv, AppColorsExtension colors) {
    return GestureDetector(
      onTap: () => context.push('/chat/${conv.id}', extra: conv),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: colors.bgSurface,
                  backgroundImage: conv.avatarUrl != null ? NetworkImage(conv.avatarUrl!) : null,
                  child: conv.avatarUrl == null
                      ? Text(
                          conv.name.isNotEmpty ? conv.name[0].toUpperCase() : '?',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: colors.textMuted),
                        )
                      : null,
                ),
                if (conv.isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.bgCard, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conv.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: conv.unreadCount > 0 ? FontWeight.w800 : FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (conv.lastMessageTime != null)
                        Text(
                          DateFormat('HH:mm').format(conv.lastMessageTime!),
                          style: TextStyle(fontSize: 11, color: colors.textMuted),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conv.lastMessage ?? 'Chưa có tin nhắn',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (conv.unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2979FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            conv.unreadCount > 99 ? '99+' : '${conv.unreadCount}',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Chat Detail Screen ───

class ChatDetailScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final Conversation? conversation;

  const ChatDetailScreen({
    super.key,
    required this.conversationId,
    this.conversation,
  });

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  static const _log = AppLogger('ChatDetail');
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final messages = await ref.read(_messagesProvider(widget.conversationId).future);
    if (mounted) {
      setState(() {
        _messages.addAll(messages);
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    final tempMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: _currentUserId ?? 'me',
      senderName: 'Tôi',
      content: text,
      createdAt: DateTime.now(),
      isMine: true,
    );

    setState(() => _messages.add(tempMsg));
    _scrollToBottom();

    try {
      final dio = ref.read(dioClientProvider).dio;
      await dio.post('/chat/conversations/${widget.conversationId}/messages', data: {
        'content': text,
      });
    } catch (e, stack) {
      _log.error('Lỗi gửi tin nhắn', e, stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể gửi tin nhắn')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final convName = widget.conversation?.name ?? 'Chat';

    return Scaffold(
      backgroundColor: colors.bgDark,
      appBar: AppBar(
        backgroundColor: colors.bgDark,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: colors.bgSurface,
              backgroundImage: widget.conversation?.avatarUrl != null
                  ? NetworkImage(widget.conversation!.avatarUrl!)
                  : null,
              child: widget.conversation?.avatarUrl == null
                  ? Text(
                      convName.isNotEmpty ? convName[0].toUpperCase() : '?',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.textMuted),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                convName,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? _buildEmptyChat(colors)
                    : ListView.builder(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _messages.length,
                        itemBuilder: (ctx, i) => _buildMessageBubble(_messages[i], colors),
                      ),
          ),
          // Input bar
          _buildInputBar(colors),
        ],
      ),
    );
  }

  Widget _buildEmptyChat(AppColorsExtension colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_rounded, size: 48, color: colors.textMuted.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(
            'Chưa có tin nhắn nào',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            'Hãy bắt đầu cuộc trò chuyện',
            style: TextStyle(fontSize: 12, color: colors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, AppColorsExtension colors) {
    final isMine = msg.isMine;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine && msg.senderAvatar != null)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: CircleAvatar(
                radius: 12,
                backgroundImage: NetworkImage(msg.senderAvatar!),
              ),
            ),
          if (!isMine && msg.senderAvatar == null)
            const SizedBox(width: 24),
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMine ? const Color(0xFF2979FF) : colors.bgCard,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isMine ? const Radius.circular(16) : Radius.zero,
                  bottomRight: isMine ? Radius.zero : const Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!isMine)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        msg.senderName,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: colors.info),
                      ),
                    ),
                  Text(
                    msg.content,
                    style: TextStyle(
                      fontSize: 14,
                      color: isMine ? Colors.white : colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    msg.timeAgo,
                    style: TextStyle(
                      fontSize: 10,
                      color: isMine ? Colors.white70 : colors.textMuted,
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

  Widget _buildInputBar(AppColorsExtension colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colors.bgCard,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: colors.bgSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.border),
                ),
                child: TextField(
                  controller: _messageController,
                  style: TextStyle(color: colors.textPrimary, fontSize: 14),
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration(
                    hintText: 'Nhập tin nhắn...',
                    hintStyle: TextStyle(color: colors.textMuted, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF2979FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
