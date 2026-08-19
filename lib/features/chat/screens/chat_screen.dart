import 'dart:async';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/services/chat_socket_service.dart';
import 'package:app_quanly_giaidau/data/models/chat_models.dart';
import 'package:app_quanly_giaidau/features/chat/screens/chat_detail_screen.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with SingleTickerProviderStateMixin {
  static const _log = AppLogger('ChatScreen');
  late final TabController _tabController;
  final _searchController = TextEditingController();
  final _aiMessageController = TextEditingController();
  final _supportMessageController = TextEditingController();

  List<ChatRoomModel> _rooms = [];
  bool _isLoadingRooms = true;
  String _searchQuery = '';

  // AI Chat State
  final List<Map<String, String>> _aiMessages = [];
  bool _hasSeededAiGreeting = false;
  bool _isAiReplying = false;

  // Support Chat State
  List<ChatMessageModel> _supportMessages = [];
  bool _isLoadingSupport = false;
  bool _isSendingSupport = false;

  late final ChatSocketService _chatSocket;
  Timer? _refreshTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasSeededAiGreeting) {
      final l10n = AppLocalizations.of(context)!;
      _aiMessages.add({
        'role': 'assistant',
        'content': l10n.chatScreenAiGreeting,
      });
      _hasSeededAiGreeting = true;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _chatSocket = ChatSocketService(ref.read(tokenManagerProvider));
    _initSocket();
    _loadRooms();
    _loadSupportChat();

    _searchController.addListener(() {
      setState(
        () => _searchQuery = _searchController.text.trim().toLowerCase(),
      );
    });

    _refreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _loadRooms(quiet: true),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabController.dispose();
    _searchController.dispose();
    _aiMessageController.dispose();
    _supportMessageController.dispose();
    _chatSocket.dispose();
    super.dispose();
  }

  void _initSocket() {
    _chatSocket.onMessage = (data) {
      if (mounted) _loadRooms(quiet: true);
    };
  }

  Future<void> _loadRooms({bool quiet = false}) async {
    if (!quiet) setState(() => _isLoadingRooms = true);
    try {
      final dio = ref.read(dioClientProvider).dio;
      final currentUserId = ref.read(userProfileProvider).asData?.value.id;
      final res = await dio.get('/chat/rooms');
      final rawList = res.data is Map
          ? (res.data['data'] ?? res.data['items'] ?? [])
          : res.data;
      if (rawList is List && mounted) {
        final items = rawList
            .whereType<Map<String, dynamic>>()
            .map(
              (json) =>
                  ChatRoomModel.fromJson(json, currentUserId: currentUserId),
            )
            .toList();
        setState(() => _rooms = items);
      }
    } catch (_) {}
    if (!quiet && mounted) setState(() => _isLoadingRooms = false);
  }

  Future<void> _loadSupportChat() async {
    setState(() => _isLoadingSupport = true);
    try {
      final dio = ref.read(dioClientProvider).dio;
      final currentUserId = ref.read(userProfileProvider).asData?.value.id;
      final res = await dio.get('/chat/support/me');
      final data = res.data is Map ? (res.data['data'] ?? res.data) : null;
      if (data is Map<String, dynamic> && data['messages'] is List && mounted) {
        final msgs = (data['messages'] as List)
            .whereType<Map<String, dynamic>>()
            .map(
              (json) =>
                  ChatMessageModel.fromJson(json, currentUserId: currentUserId),
            )
            .toList();
        setState(() => _supportMessages = msgs);
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoadingSupport = false);
  }

  Future<void> _sendSupportMessage() async {
    final text = _supportMessageController.text.trim();
    if (text.isEmpty || _isSendingSupport) return;
    setState(() => _isSendingSupport = true);
    _supportMessageController.clear();
    try {
      final dio = ref.read(dioClientProvider).dio;
      final res = await dio.post('/chat/support', data: {'messageText': text});
      final currentUserId = ref.read(userProfileProvider).asData?.value.id;
      final data = res.data is Map ? (res.data['data'] ?? res.data) : null;
      if (data is Map<String, dynamic> && data['messages'] is List && mounted) {
        final msgs = (data['messages'] as List)
            .whereType<Map<String, dynamic>>()
            .map(
              (json) =>
                  ChatMessageModel.fromJson(json, currentUserId: currentUserId),
            )
            .toList();
        setState(() => _supportMessages = msgs);
      }
    } catch (_) {}
    if (mounted) setState(() => _isSendingSupport = false);
  }

  Future<void> _sendAiMessage({String? presetText}) async {
    final text = (presetText ?? _aiMessageController.text).trim();
    if (text.isEmpty || _isAiReplying) return;

    setState(() {
      _aiMessages.add({'role': 'user', 'content': text});
      _isAiReplying = true;
    });
    _aiMessageController.clear();

    try {
      final dio = ref.read(dioClientProvider).dio;
      final res = await dio.post(
        '/ai/message',
        data: {'messages': _aiMessages, 'message': text, 'isMobile': true},
      );
      final raw = res.data;
      final data = raw is Map<String, dynamic>
          ? raw
          : (raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{});
      final reply = (data['reply'] ?? data['data'] ?? data['content'])
          ?.toString();
      if (mounted) {
        setState(() {
          _aiMessages.add({
            'role': 'assistant',
            'content':
                reply ??
                AppLocalizations.of(context)!.chatScreenAiFallbackReply,
          });
        });
      }
    } catch (e, stack) {
      _log.error('Lỗi gọi AI Chat', e, stack);
      if (mounted) {
        setState(() {
          _aiMessages.add({
            'role': 'assistant',
            'content': AppLocalizations.of(context)!.chatScreenAiErrorReply,
          });
        });
      }
    } finally {
      if (mounted) setState(() => _isAiReplying = false);
    }
  }

  String _formatRoomTime(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return DateFormat('HH:mm').format(dt);
    }
    final diff = now.difference(dt);
    if (diff.inDays < 7) {
      return DateFormat('EEEE', 'vi_VN').format(dt);
    }
    return DateFormat('dd/MM').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = ref.watch(userProfileProvider).asData?.value;
    final currentUserId = profile?.id;

    final filteredRooms = _rooms.where((r) {
      if (_searchQuery.isEmpty) return true;
      final title = r.displayTitle(currentUserId).toLowerCase();
      final lastMsg = r.lastMessage?.content.toLowerCase() ?? '';
      return title.contains(_searchQuery) || lastMsg.contains(_searchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF18191A)
          : const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: colors.bgCard,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: AppTheme.primaryLight,
              backgroundImage: profile?.avatarUrl != null
                  ? NetworkImage(profile!.avatarUrl!)
                  : null,
              child: profile?.avatarUrl == null
                  ? const Icon(
                      Icons.person,
                      color: AppTheme.primaryDark,
                      size: 18,
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Text(
              l10n.chatScreenTitle,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          indicatorWeight: 3,
          labelColor: AppTheme.primary,
          unselectedLabelColor: colors.textMuted,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13.5,
          ),
          tabs: [
            Tab(
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
              text: l10n.chatScreenConversations,
            ),
            Tab(
              icon: const Icon(Icons.auto_awesome_rounded, size: 20),
              text: l10n.chatScreenAiAssistant,
            ),
            Tab(
              icon: const Icon(Icons.headset_mic_outlined, size: 20),
              text: l10n.chatScreenSupport,
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── TAB 1: CONVERSATIONS / INBOX ──
          RefreshIndicator(
            onRefresh: () => _loadRooms(),
            color: AppTheme.primary,
            child: Column(
              children: [
                // Messenger Search Bar
                Container(
                  color: colors.bgCard,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF3A3B3C)
                          : const Color(0xFFF0F2F5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: l10n.chatScreenSearchHint,
                        hintStyle: TextStyle(
                          color: colors.textMuted,
                          fontSize: 13.5,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: colors.textMuted,
                          size: 20,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                      ),
                    ),
                  ),
                ),

                // Conversations List
                Expanded(
                  child: _isLoadingRooms
                      ? const Center(child: CircularProgressIndicator())
                      : filteredRooms.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.forum_outlined,
                                size: 52,
                                color: colors.textMuted.withValues(alpha: 0.4),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? l10n.chatScreenNoSearchResults
                                    : l10n.chatScreenNoConversations,
                                style: TextStyle(
                                  color: colors.textMuted,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: filteredRooms.length,
                          separatorBuilder: (_, _) => Divider(
                            height: 1,
                            indent: 72,
                            color: colors.borderLight.withValues(alpha: 0.5),
                          ),
                          itemBuilder: (context, index) {
                            final room = filteredRooms[index];
                            final title = room.displayTitle(currentUserId);
                            final avatar = room.displayAvatar(currentUserId);
                            final hasUnread = room.unreadCount > 0;

                            return ListTile(
                              tileColor: colors.bgCard,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatDetailScreen(
                                      roomId: room.id,
                                      roomName: title,
                                      roomAvatar: avatar,
                                      roomType: room.type,
                                      communityId: room.communityId,
                                    ),
                                  ),
                                ).then((_) => _loadRooms(quiet: true));
                              },
                              leading: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: AppTheme.primaryLight,
                                    backgroundImage:
                                        avatar != null && avatar.isNotEmpty
                                        ? NetworkImage(avatar)
                                        : null,
                                    child: avatar == null || avatar.isEmpty
                                        ? Text(
                                            title.characters.first
                                                .toUpperCase(),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.primaryDark,
                                              fontSize: 16,
                                            ),
                                          )
                                        : null,
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      width: 13,
                                      height: 13,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF22C55E),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: colors.bgCard,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: TextStyle(
                                        fontWeight: hasUnread
                                            ? FontWeight.bold
                                            : FontWeight.w600,
                                        fontSize: 15,
                                        color: colors.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (room.type == 'CLUB')
                                    Container(
                                      margin: const EdgeInsets.only(left: 6),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 1.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        l10n.chatScreenClubBadge,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryDark,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        room.lastMessage?.isRevoked == true
                                            ? l10n.chatScreenRevokedMessage
                                            : (room
                                                          .lastMessage
                                                          ?.content
                                                          .isNotEmpty ==
                                                      true
                                                  ? room.lastMessage!.content
                                                  : (room
                                                                .lastMessage
                                                                ?.mediaUrls
                                                                .isNotEmpty ==
                                                            true
                                                        ? l10n.chatScreenImageMessage
                                                        : l10n.chatScreenStartConversation)),

                                        style: TextStyle(
                                          fontSize: 13,
                                          color: hasUnread
                                              ? colors.textPrimary
                                              : colors.textMuted,
                                          fontWeight: hasUnread
                                              ? FontWeight.w700
                                              : FontWeight.normal,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatRoomTime(room.updatedAt),
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: hasUnread
                                            ? AppTheme.primary
                                            : colors.textMuted,
                                        fontWeight: hasUnread
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              trailing: hasUnread
                                  ? Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: AppTheme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        '${room.unreadCount}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  : null,
                            );
                          },
                        ),
                ),
              ],
            ),
          ),

          // ── TAB 2: AI SPORTO ASSISTANT ──
          Column(
            children: [
              // Quick Prompt Chips
              Container(
                color: colors.bgCard,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children:
                        [
                          l10n.chatScreenAiPromptRegistration,
                          l10n.chatScreenAiPromptElo,
                          l10n.chatScreenAiPromptCreateClub,
                          l10n.chatScreenAiPromptRules,
                        ].map((prompt) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ActionChip(
                              avatar: const Icon(
                                Icons.auto_awesome_rounded,
                                size: 14,
                                color: AppTheme.primary,
                              ),
                              label: Text(
                                prompt,
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor: AppTheme.primary.withValues(
                                alpha: 0.08,
                              ),
                              onPressed: () =>
                                  _sendAiMessage(presetText: prompt),
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ),

              // AI Chat Log
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _aiMessages.length + (_isAiReplying ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _aiMessages.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 14,
                              backgroundColor: AppTheme.primary,
                              child: Icon(
                                Icons.auto_awesome_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF3A3B3C)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                l10n.chatScreenAiTyping,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final msg = _aiMessages[index];
                    final isUser = msg['role'] == 'user';

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: isUser
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isUser) ...[
                            const CircleAvatar(
                              radius: 14,
                              backgroundColor: AppTheme.primary,
                              child: Icon(
                                Icons.auto_awesome_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isUser
                                    ? AppTheme.primary
                                    : (isDark
                                          ? const Color(0xFF3A3B3C)
                                          : Colors.white),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                msg['content'] ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                  color: isUser
                                      ? Colors.white
                                      : colors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // AI Input Bar
              Container(
                padding: const EdgeInsets.all(12),
                color: colors.bgCard,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _aiMessageController,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: l10n.chatScreenAiInputHint,
                          hintStyle: TextStyle(color: colors.textMuted),
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF3A3B3C)
                              : const Color(0xFFF0F2F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.send_rounded,
                        color: AppTheme.primary,
                      ),
                      onPressed: _sendAiMessage,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── TAB 3: LIVE SUPPORT CSKH ──
          Column(
            children: [
              Expanded(
                child: _isLoadingSupport
                    ? const Center(child: CircularProgressIndicator())
                    : _supportMessages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.headset_mic_rounded,
                              size: 54,
                              color: AppTheme.primary,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              l10n.chatScreenSupportTitle,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.chatScreenSupportDescription,
                              style: TextStyle(
                                color: colors.textMuted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _supportMessages.length,
                        itemBuilder: (context, index) {
                          final msg = _supportMessages[index];
                          final isUser = msg.isMine;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: isUser
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isUser
                                        ? AppTheme.primary
                                        : (isDark
                                              ? const Color(0xFF3A3B3C)
                                              : Colors.white),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    msg.content,
                                    style: TextStyle(
                                      color: isUser
                                          ? Colors.white
                                          : colors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                color: colors.bgCard,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _supportMessageController,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: l10n.chatScreenSupportInputHint,
                          hintStyle: TextStyle(color: colors.textMuted),
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF3A3B3C)
                              : const Color(0xFFF0F2F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.send_rounded,
                        color: AppTheme.primary,
                      ),
                      onPressed: _sendSupportMessage,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
