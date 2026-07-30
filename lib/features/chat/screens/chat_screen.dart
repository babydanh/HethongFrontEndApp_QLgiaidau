import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class Conversation {
  final String id;
  final String name;
  final String? avatarUrl;

  const Conversation({required this.id, required this.name, this.avatarUrl});
}

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      senderName: json['senderName']?.toString() ?? 'Admin hỗ trợ',
      content: (json['messageText'] ?? json['content'] ?? '').toString(),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  List<ChatMessage> _messages = const [];
  Timer? _pollTimer;
  bool _isLoading = true;
  bool _isSending = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadConversation();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _loadConversation(quiet: true),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  dynamic _unwrapData(dynamic raw) {
    if (raw is Map<String, dynamic> && raw.containsKey('data')) {
      return raw['data'];
    }
    return raw;
  }

  List<ChatMessage> _parseMessages(dynamic raw) {
    final conversation = _unwrapData(raw);
    if (conversation is! Map<String, dynamic>) return const [];
    final messages = conversation['messages'];
    if (messages is! List) return const [];
    return messages
        .whereType<Map>()
        .map((item) => ChatMessage.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> _loadConversation({bool quiet = false}) async {
    if (!quiet && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final dio = ref.read(dioClientProvider).dio;
      final response = await dio.get('/chat/support/me');
      final messages = _parseMessages(response.data);
      if (!mounted) return;
      setState(() {
        _messages = messages;
        _isLoading = false;
        _errorMessage = null;
      });
      _scrollToBottom();
    } catch (error) {
      if (!mounted || quiet) return;
      setState(() {
        _isLoading = false;
        _errorMessage = ErrorParser.parse(
          error,
          'Không thể tải cuộc trò chuyện hỗ trợ.',
        );
      });
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    try {
      final dio = ref.read(dioClientProvider).dio;
      final response = await dio.post(
        '/chat/support',
        data: {'messageText': content},
      );
      final messages = _parseMessages(response.data);
      if (!mounted) return;
      _messageController.clear();
      setState(() {
        _messages = messages;
        _isSending = false;
      });
      _scrollToBottom();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _errorMessage = ErrorParser.parse(error, 'Không gửi được tin nhắn.');
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final currentUserId = ref.watch(userProfileProvider).asData?.value.id;

    return Scaffold(
      backgroundColor: colors.bgDark,
      appBar: AppBar(
        backgroundColor: colors.bgDark,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
          onPressed: () => context.pop(),
        ),
        titleSpacing: 4,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F1FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.support_agent_rounded,
                color: Color(0xFF1463F3),
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin hỗ trợ',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Phản hồi trực tiếp',
                      style: TextStyle(color: colors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: colors.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _loadConversation,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadConversation,
                    child: _messages.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.sizeOf(context).height * 0.55,
                                child: _EmptySupportState(colors: colors),
                              ),
                            ],
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final message = _messages[index];
                              return _MessageBubble(
                                message: message,
                                isMine: message.senderId == currentUserId,
                                colors: colors,
                              );
                            },
                          ),
                  ),
          ),
          _buildInput(colors),
        ],
      ),
    );
  }

  Widget _buildInput(AppColorsExtension colors) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        decoration: BoxDecoration(
          color: colors.bgCard,
          border: Border(top: BorderSide(color: colors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                style: TextStyle(color: colors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Nhập nội dung cần hỗ trợ...',
                  filled: true,
                  fillColor: colors.bgSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 9),
            IconButton.filled(
              onPressed: _isSending ? null : _sendMessage,
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF1463F3),
                disabledBackgroundColor: const Color(
                  0xFF1463F3,
                ).withValues(alpha: 0.45),
                minimumSize: const Size(46, 46),
              ),
              icon: _isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatDetailScreen extends StatelessWidget {
  final String conversationId;
  final Conversation? conversation;

  const ChatDetailScreen({
    super.key,
    required this.conversationId,
    this.conversation,
  });

  @override
  Widget build(BuildContext context) => const ChatScreen();
}

class _EmptySupportState extends StatelessWidget {
  final AppColorsExtension colors;

  const _EmptySupportState({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: const Color(0xFF1463F3).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.support_agent_rounded,
                color: Color(0xFF1463F3),
                size: 40,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Bạn cần hỗ trợ gì?',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Tin nhắn tại đây được gửi trực tiếp tới quản trị viên VNSport.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;
  final AppColorsExtension colors;

  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.76,
        ),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        decoration: BoxDecoration(
          color: isMine ? const Color(0xFF1463F3) : colors.bgCard,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(17),
            topRight: const Radius.circular(17),
            bottomLeft: Radius.circular(isMine ? 17 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 17),
          ),
          border: isMine ? null : Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMine)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  message.senderName.isEmpty
                      ? 'Admin hỗ trợ'
                      : message.senderName,
                  style: const TextStyle(
                    color: Color(0xFF1463F3),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            Text(
              message.content,
              style: TextStyle(
                color: isMine ? Colors.white : colors.textPrimary,
                fontSize: 14,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              DateFormat('HH:mm • dd/MM').format(message.createdAt.toLocal()),
              style: TextStyle(
                color: isMine ? Colors.white70 : colors.textMuted,
                fontSize: 9.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
