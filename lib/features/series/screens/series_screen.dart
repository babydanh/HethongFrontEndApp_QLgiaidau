import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:intl/intl.dart';

class SeriesItem {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String status;
  final int legCount;
  final int participantCount;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? bannerUrl;

  const SeriesItem({
    required this.id, required this.name, required this.slug,
    this.description, required this.status, this.legCount = 0,
    this.participantCount = 0, this.startDate, this.endDate, this.bannerUrl,
  });

  factory SeriesItem.fromJson(Map<String, dynamic> json) => SeriesItem(
    id: json['id'] ?? '', name: json['name'] ?? '', slug: json['slug'] ?? '',
    description: json['description'], status: json['status'] ?? 'UPCOMING',
    legCount: json['_count']?['legs'] ?? json['legCount'] ?? 0,
    participantCount: json['_count']?['participants'] ?? json['participantCount'] ?? 0,
    startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
    endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
    bannerUrl: json['bannerUrl'],
  );
}

final _seriesListProvider = FutureProvider<List<SeriesItem>>((ref) async {
  try {
    final dio = ref.read(dioClientProvider).dio;
    final response = await dio.get('/series');
    if (response.statusCode == 200) {
      final List<dynamic> list = response.data['data'] ?? [];
      return list.map((j) => SeriesItem.fromJson(j as Map<String, dynamic>)).toList();
    }
    return [];
  } catch (_) { return []; }
});

class SeriesScreen extends ConsumerWidget {
  const SeriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seriesAsync = ref.watch(_seriesListProvider);
    return Scaffold(
      backgroundColor: context.colors.bgDark,
      appBar: AppBar(title: const Text('Chuỗi giải đấu'), centerTitle: true),
      body: seriesAsync.when(
        data: (list) {
          if (list.isEmpty) return _buildEmpty(context);
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(_seriesListProvider),
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
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

  Widget _buildEmpty(BuildContext context) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 80, height: 80, decoration: BoxDecoration(color: context.colors.bgSurface, borderRadius: BorderRadius.circular(20)),
        child: Icon(Icons.emoji_events_outlined, size: 40, color: context.colors.textMuted.withValues(alpha: 0.4))),
      const SizedBox(height: 16),
      Text('Chưa có chuỗi giải đấu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.colors.textPrimary)),
      const SizedBox(height: 6),
      Text('Các chuỗi giải đấu sẽ xuất hiện tại đây', style: TextStyle(fontSize: 13, color: context.colors.textMuted)),
    ]));
  }

  Widget _buildCard(BuildContext context, SeriesItem series) {
    final isActive = series.status == 'ONGOING' || series.status == 'ACTIVE';
    final statusColor = isActive ? context.colors.error : (series.status == 'COMPLETED' ? context.colors.success : context.colors.info);
    final statusLabel = isActive ? 'Đang diễn ra' : (series.status == 'COMPLETED' ? 'Đã kết thúc' : 'Sắp diễn ra');
    final dateStr = series.startDate != null ? DateFormat('dd/MM/yyyy').format(series.startDate!) : '';
    final fmt = NumberFormat('#,###', 'vi_VN');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isActive ? context.colors.error.withValues(alpha: 0.3) : context.colors.border),
        boxShadow: isActive ? [BoxShadow(color: context.colors.error.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))] : null,
      ),
      child: InkWell(
        onTap: () {/* TODO: series detail */},
        borderRadius: BorderRadius.circular(12),
        child: Row(children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
            child: Icon(Icons.emoji_events_rounded, color: statusColor, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(series.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: context.colors.textPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Row(children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                child: Text(statusLabel, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: statusColor))),
              if (dateStr.isNotEmpty) ...[const SizedBox(width: 8), Text(dateStr, style: TextStyle(fontSize: 11, color: context.colors.textMuted))],
            ]),
            const SizedBox(height: 4),
            Text('${series.legCount} chặng • ${fmt.format(series.participantCount)} VĐV', style: TextStyle(fontSize: 11, color: context.colors.textMuted)),
          ])),
          Icon(Icons.chevron_right_rounded, color: context.colors.textMuted),
        ]),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}
