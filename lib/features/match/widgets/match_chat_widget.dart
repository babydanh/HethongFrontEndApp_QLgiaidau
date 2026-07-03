import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';

/// Widget chat trực tiếp cho trận đấu — gửi/nhận tin nhắn realtime.
///
/// - Tạo/find chat room theo matchId
/// - Gửi tin nhắn qua REST API
/// - Poll mỗi 5s để lấy tin nhắn mới
/// - Hiển thị avatar + tên + nội dung + thời gian
class MatchChatWidget extends ConsumerStatefulWidget {
  final String matchId;
  final String tournamentId;

  const MatchChatWidget({
    super.key,
    required this.matchId,
    required this.tournamentId,
  });

  @override
  ConsumerState<MatchChatWidget> createState() => _MatchChatWidgetState();
}

class _MatchChatWidgetState extends ConsumerState<MatchChatWidget> {
  static const _log = AppLogger('MatchChat');
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  String? _roomId;
  bool _isLoading = true;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _initRoom();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _initRoom() async {
    try {
      final dio = ref.read(dioProvider);
      // Tìm hoặc tạo room cho match này
      final roomsResp = await dio.get('/chat/rooms');
      final roomsData = roomsResp.data['data'] as List? ?? [];
      final matchRoomId = 'match_${widget.matchId}';

      Map<String, dynamic>? existingRoom;
      for (final r in roomsData) {
        if (r['name'] == matchRoomId || r['id'] == matchRoomId) {
          existingRoom = r as Map<String, dynamic>;
          break;
        }
      }

      if (existingRoom != null) {
        _roomId = existingRoom['id'] as String?;
      } else {
        final createResp = await dio.post('/chat/rooms', data: {
          'name': matchRoomId,
          'type': 'GROUP',
          'memberIds': [],
        });
        _roomId = createResp.data['data']?['id'] as String? ?? createResp.data['id'] as String?;
      }

      if (_roomId != null) await _loadMessages();
    } catch (e, stack) {
      _log.error('Lỗi khởi tạo chat room', e, stack);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }

    // Poll every 5 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _loadMessages());
  }

  Future<void> _loadMessages() async {
    if (_roomId == null) return;
    try {
      final dio = ref.read(dioProvider);
      final resp = await dio.get('/chat/rooms/$_roomId/messages');
      final data = resp.data['data'] as List? ?? resp.data as List? ?? [];
      if (mounted) {
        setState(() => _messages = data.cast<Map<String, dynamic>>());
      }
    } catch (_) {}
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _roomId == null) return;
    _msgCtrl.clear();
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/chat/messages', data: {
        'roomId': _roomId,
        'content': text,
      });
      await _loadMessages();
      // Scroll to bottom
      Future.delayed(const Duration(milliseconds: 200), () {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
        }
      });
    } catch (e, stack) {
      _log.error('Lỗi gửi tin nhắn', e, stack);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      children: [
        // Messages list
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : _messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded, size: 32, color: colors.textMuted),
                          const SizedBox(height: 8),
                          Text('Chưa có tin nhắn', style: TextStyle(fontSize: 12, color: colors.textMuted)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollCtrl,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      itemCount: _messages.length,
                      itemBuilder: (context, i) {
                        final msg = _messages[i];
                        final sender = msg['senderName'] as String? ?? msg['sender']?['fullName'] as String? ?? 'Người dùng';
                        final content = msg['content'] as String? ?? msg['messageText'] as String? ?? '';
                        final time = msg['createdAt'] as String? ?? msg['timestamp'] as String? ?? '';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                                child: Text(sender.isNotEmpty ? sender[0].toUpperCase() : '?',
                                    style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800, fontSize: 10)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(sender, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: colors.textPrimary)),
                                        const SizedBox(width: 6),
                                        Text(_formatTime(time), style: TextStyle(fontSize: 9, color: colors.textMuted)),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(content, style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
        // Input
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          decoration: BoxDecoration(
            color: colors.bgSurface,
            border: Border(top: BorderSide(color: colors.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _msgCtrl,
                  style: TextStyle(color: colors.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Nhập tin nhắn...',
                    hintStyle: TextStyle(color: colors.textMuted, fontSize: 12),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}

/// Widget placeholder cho camera/livestream.
class LiveCameraPlaceholder extends StatelessWidget {
  const LiveCameraPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      color: colors.bgSurface,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.videocam_rounded, size: 36, color: Colors.white54),
            ),
            const SizedBox(height: 12),
            Text('Camera trực tiếp', style: TextStyle(fontSize: 14, color: colors.textMuted, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Kết nối camera sân đấu...', style: TextStyle(fontSize: 11, color: colors.textMuted)),
          ],
        ),
      ),
    );
  }
}
