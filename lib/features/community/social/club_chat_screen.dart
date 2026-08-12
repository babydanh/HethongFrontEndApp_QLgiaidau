import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:flutter/material.dart';
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
  List<_ClubChatMessage> _messages = const [];
  String? _roomId;
  String? _cursor;
  bool _loading = true;
  bool _sending = false;
  bool _loadingOlder = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadRoom();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _refreshMessages());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
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
      final response = await ref.read(dioClientProvider).dio.get(
        '/chat/rooms',
        queryParameters: {'type': 'CLUB', 'communityId': widget.communityId},
      );
      final payload = _asMap(response.data);
      final raw = payload['data'];
      final room = raw is List ? (raw.isEmpty ? const <String, dynamic>{} : _asMap(raw.first)) : _asMap(raw ?? payload);
      final id = room['id']?.toString();
      if (id == null || id.isEmpty) throw const FormatException('Không tạo được phòng chat');
      if (!mounted) return;
      setState(() => _roomId = id);
      await _refreshMessages(initial: true);
    } catch (error, stack) {
      _log.error('Không thể mở chat CLB', error, stack);
      if (mounted) setState(() { _loading = false; _error = 'Chưa thể mở trò chuyện. Thử lại sau.'; });
    }
  }

  Future<void> _refreshMessages({bool initial = false}) async {
    final roomId = _roomId;
    if (roomId == null || _loadingOlder) return;
    try {
      final response = await ref.read(dioClientProvider).dio.get(
        '/chat/rooms/$roomId/messages',
        queryParameters: {'limit': 50},
      );
      final payload = _asMap(response.data);
      final raw = payload['data'];
      final list = raw is List ? raw : (_asMap(raw)['items'] ?? const <Object?>[]);
      if (list is! List) return;
      final incoming = list.map(_ClubChatMessage.fromJson).where((message) => message.id.isNotEmpty).toList();
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
    } catch (error, stack) {
      _log.error('Không thể đồng bộ chat CLB', error, stack);
      if (mounted && initial) setState(() { _loading = false; _error = 'Mất kết nối. Kéo xuống để thử lại.'; });
    }
  }

  Future<void> _loadOlder() async {
    final roomId = _roomId;
    final cursor = _cursor;
    if (roomId == null || cursor == null || cursor.isEmpty || _loadingOlder) return;
    setState(() => _loadingOlder = true);
    try {
      final response = await ref.read(dioClientProvider).dio.get(
        '/chat/rooms/$roomId/messages',
        queryParameters: {'limit': 50, 'cursor': cursor},
      );
      final payload = _asMap(response.data);
      final raw = payload['data'];
      final list = raw is List ? raw : (_asMap(raw)['items'] ?? const <Object?>[]);
      if (list is! List) return;
      final older = list.map(_ClubChatMessage.fromJson).where((m) => m.id.isNotEmpty).toList();
      final ids = _messages.map((m) => m.id).toSet();
      if (mounted) {
        setState(() {
          _messages = [...older.where((m) => !ids.contains(m.id)), ..._messages];
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
    if (roomId == null || text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ref.read(dioClientProvider).dio.post(
        '/chat/messages',
        data: {'roomId': roomId, 'messageText': text},
      );
      _messageController.clear();
      await _refreshMessages();
      _scrollToBottom();
    } catch (error, stack) {
      _log.error('Không thể gửi tin chat CLB', error, stack);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gửi tin nhắn thất bại.')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
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
          Expanded(child: _buildMessages(colors)),
          SafeArea(child: _buildComposer(colors)),
        ],
      ),
    );
  }

  Widget _buildMessages(AppColorsExtension colors) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));
    if (_messages.isEmpty) return const Center(child: Text('Chưa có tin nhắn nào.'));
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return Align(
          alignment: Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: AppTheme.spacingSM),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            constraints: const BoxConstraints(maxWidth: 320),
            decoration: BoxDecoration(color: colors.bgCard, borderRadius: BorderRadius.circular(AppTheme.radiusLarge), border: Border.all(color: colors.borderLight)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(message.senderName, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.textMuted)),
              const SizedBox(height: 3),
              Text(message.text),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildComposer(AppColorsExtension colors) => Container(
    padding: const EdgeInsets.fromLTRB(AppTheme.spacingMD, 8, AppTheme.spacingSM, 8),
    decoration: BoxDecoration(color: colors.bgCard, border: Border(top: BorderSide(color: colors.borderLight))),
    child: Row(children: [
      Expanded(child: TextField(controller: _messageController, minLines: 1, maxLines: 4, textInputAction: TextInputAction.newline, decoration: const InputDecoration(hintText: 'Nhắn trong CLB', border: InputBorder.none))),
      IconButton(onPressed: _sending ? null : _sendMessage, icon: _sending ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send_rounded)),
    ]),
  );
}

class _ClubChatMessage {
  final String id;
  final String senderName;
  final String text;
  final DateTime createdAt;

  const _ClubChatMessage({required this.id, required this.senderName, required this.text, required this.createdAt});

  factory _ClubChatMessage.fromJson(Object? raw) {
    final json = _asMap(raw);
    final sender = _asMap(json['sender']);
    return _ClubChatMessage(
      id: json['id']?.toString() ?? '',
      senderName: json['senderName']?.toString() ?? sender['displayName']?.toString() ?? 'Thành viên CLB',
      text: (json['messageText'] ?? json['content'] ?? '').toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((key, item) => MapEntry(key.toString(), item));
  return const <String, dynamic>{};
}
