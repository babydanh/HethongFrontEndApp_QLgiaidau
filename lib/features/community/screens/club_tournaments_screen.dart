import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:intl/intl.dart';

final _clubTournamentsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, clubId) async {
  try {
    final dio = ref.read(dioClientProvider).dio;
    final response = await dio.get('/communities/$clubId/tournaments');
    if (response.statusCode == 200) {
      return ((response.data['data'] ?? []) as List).cast<Map<String, dynamic>>();
    }
    return [];
  } catch (_) { return []; }
});

class ClubTournamentsScreen extends ConsumerWidget {
  final String clubId;
  const ClubTournamentsScreen({super.key, required this.clubId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_clubTournamentsProvider(clubId));
    return Scaffold(
      backgroundColor: context.colors.bgDark,
      appBar: AppBar(title: const Text('Giải đấu'), centerTitle: true,
        actions: [IconButton(icon: const Icon(Icons.add_rounded), onPressed: () => context.push('/club/$clubId/create-tournament'))]),
      body: async.when(
        data: (list) {
          if (list.isEmpty) return _buildEmpty(context);
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(_clubTournamentsProvider(clubId)),
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
      child: Icon(Icons.emoji_events_outlined, size: 40, color: context.colors.textMuted.withValues(alpha: 0.4))),
    const SizedBox(height: 16),
    const Text('Chưa có giải đấu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
    const SizedBox(height: 24),
    ElevatedButton.icon(onPressed: () => context.push('/club/$clubId/create-tournament'), icon: const Icon(Icons.add), label: const Text('Tạo giải đấu')),
  ]));

  Widget _buildCard(BuildContext context, Map<String, dynamic> t) {
    final name = t['name'] ?? '';
    final status = t['status'] ?? '';
    final date = t['startDate'] != null ? DateTime.parse(t['startDate']) : null;
    final dateStr = date != null ? DateFormat('dd/MM/yyyy').format(date) : '';
    final isLive = status == 'ONGOING' || status == 'IN_PROGRESS';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: context.colors.bgCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: isLive ? context.colors.error.withValues(alpha: 0.3) : context.colors.border)),
      child: InkWell(onTap: () => context.push('/intro/${t['id']}'), borderRadius: BorderRadius.circular(10),
        child: Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: (isLive ? context.colors.error : context.colors.info).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.emoji_events_rounded, color: isLive ? context.colors.error : context.colors.info, size: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.colors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
            if (dateStr.isNotEmpty) Text(dateStr, style: TextStyle(fontSize: 11, color: context.colors.textMuted)),
          ])),
          Icon(Icons.chevron_right_rounded, color: context.colors.textMuted),
        ]),
      ),
    );
  }
}
