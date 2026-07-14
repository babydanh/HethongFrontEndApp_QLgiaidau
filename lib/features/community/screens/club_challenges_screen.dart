import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:intl/intl.dart';

class ChallengeItem {
  final String id;
  final String challengerClubName;
  final String? challengedClubId;
  final String? challengedClubName;
  final String status;
  final String? message;
  final DateTime createdAt;
  final DateTime? scheduledDate;

  const ChallengeItem({
    required this.id, required this.challengerClubName,
    this.challengedClubId, this.challengedClubName,
    required this.status, this.message, required this.createdAt, this.scheduledDate,
  });

  factory ChallengeItem.fromJson(Map<String, dynamic> json) {
    final challenger = json['challengerClub'] as Map? ?? json['challenger'] as Map?;
    final challenged = json['challengedClub'] as Map? ?? json['challenged'] as Map?;
    return ChallengeItem(
      id: json['id'] ?? '',
      challengerClubName: challenger?['name']?.toString() ?? json['challengerClubName'] ?? '',
      challengedClubId: challenged?['id']?.toString() ?? json['challengedClubId'],
      challengedClubName: challenged?['name']?.toString() ?? json['challengedClubName'],
      status: json['status'] ?? 'PENDING',
      message: json['message'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      scheduledDate: json['scheduledDate'] != null ? DateTime.parse(json['scheduledDate']) : null,
    );
  }
}

final _challengesProvider = FutureProvider.family<List<ChallengeItem>, String>((ref, clubId) async {
  try {
    final dio = ref.read(dioClientProvider).dio;
    final response = await dio.get('/communities/$clubId/challenges');
    if (response.statusCode == 200) {
      final List list = response.data['data'] ?? [];
      return list.map((j) => ChallengeItem.fromJson(j as Map<String, dynamic>)).toList();
    }
    return [];
  } catch (_) { return []; }
});

class ClubChallengesScreen extends ConsumerStatefulWidget {
  final String clubId;
  const ClubChallengesScreen({super.key, required this.clubId});

  @override
  ConsumerState<ClubChallengesScreen> createState() => _ClubChallengesScreenState();
}

class _ClubChallengesScreenState extends ConsumerState<ClubChallengesScreen> {
  @override
  Widget build(BuildContext context) {
    final challengesAsync = ref.watch(_challengesProvider(widget.clubId));
    return Scaffold(
      backgroundColor: context.colors.bgDark,
      appBar: AppBar(title: const Text('Thử thách'), centerTitle: true,
        actions: [IconButton(icon: const Icon(Icons.add_rounded), onPressed: () => _showCreateDialog(context))]),
      body: challengesAsync.when(
        data: (list) {
          if (list.isEmpty) return _buildEmpty(context);
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(_challengesProvider(widget.clubId)),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (ctx, i) => _buildCard(context, list[i]),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(width: 80, height: 80, decoration: BoxDecoration(color: context.colors.bgSurface, borderRadius: BorderRadius.circular(20)),
      child: Icon(Icons.sports_kabaddi_rounded, size: 40, color: context.colors.textMuted.withValues(alpha: 0.4))),
    const SizedBox(height: 16),
    Text('Chưa có thử thách', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.colors.textPrimary)),
  ]));

  Widget _buildCard(BuildContext context, ChallengeItem c) {
    final isPending = c.status == 'PENDING';
    final isAccepted = c.status == 'ACCEPTED';
    final statusColor = isPending ? context.colors.warning : (isAccepted ? context.colors.success : context.colors.textMuted);
    final statusLabel = isPending ? 'Chờ duyệt' : (isAccepted ? 'Đã chấp nhận' : (c.status == 'REJECTED' ? 'Từ chối' : c.status));
    final dateStr = DateFormat('dd/MM/yyyy').format(c.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: context.colors.bgCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: context.colors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(isAccepted ? Icons.check_circle_rounded : Icons.sports_kabaddi_rounded, color: statusColor, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c.challengerClubName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.colors.textPrimary)),
            Text(dateStr, style: TextStyle(fontSize: 11, color: context.colors.textMuted)),
          ])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
            child: Text(statusLabel, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: statusColor))),
        ]),
        if (c.message != null && c.message!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(c.message!, style: TextStyle(fontSize: 13, color: context.colors.textSecondary)),
        ],
        if (isPending) ...[
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            OutlinedButton.icon(onPressed: () => _handleChallenge(c.id, 'REJECTED'), icon: const Icon(Icons.close, size: 16), label: const Text('Từ chối', style: TextStyle(fontSize: 12))),
            const SizedBox(width: 8),
            ElevatedButton.icon(onPressed: () => _handleChallenge(c.id, 'ACCEPTED'), icon: const Icon(Icons.check, size: 16), label: const Text('Chấp nhận', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(backgroundColor: context.colors.success)),
          ]),
        ],
      ]),
    );
  }

  Future<void> _handleChallenge(String challengeId, String status) async {
    try {
      final dio = ref.read(dioClientProvider).dio;
      await dio.patch('/communities/${widget.clubId}/challenges/$challengeId', data: {'status': status});
      ref.invalidate(_challengesProvider(widget.clubId));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  void _showCreateDialog(BuildContext context) {
    final msgCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: context.colors.bgCard,
      title: const Text('Tạo thử thách mới'),
      content: TextField(
        controller: msgCtrl, maxLines: 3,
        style: TextStyle(color: context.colors.textPrimary),
        decoration: InputDecoration(hintText: 'Lời nhắn...', hintStyle: TextStyle(color: context.colors.textMuted)),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
        ElevatedButton(onPressed: () async {
          Navigator.pop(ctx);
          try {
            final dio = ref.read(dioClientProvider).dio;
            await dio.post('/communities/${widget.clubId}/challenges', data: {'message': msgCtrl.text.trim()});
            if (!context.mounted) return;
            ref.invalidate(_challengesProvider(widget.clubId));
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
            }
          }
        }, child: const Text('Gửi')),
      ],
    ));
  }
}
