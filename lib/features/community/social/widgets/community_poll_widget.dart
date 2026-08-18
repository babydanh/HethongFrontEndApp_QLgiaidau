import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/community_social_models.dart';
import 'package:app_quanly_giaidau/features/community/social/community_feed_notifier.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CommunityPollWidget extends ConsumerStatefulWidget {
  final String communityId;
  final CommunityPollModel poll;
  final String? tournamentId;
  final String? tournamentInviteCode;

  const CommunityPollWidget({super.key, required this.communityId, required this.poll, this.tournamentId, this.tournamentInviteCode});

  @override
  ConsumerState<CommunityPollWidget> createState() => _CommunityPollWidgetState();
}

class _CommunityPollWidgetState extends ConsumerState<CommunityPollWidget> {
  late CommunityPollModel _poll;
  bool _busy = false;

  @override
  void initState() { super.initState(); _poll = widget.poll; }

  Future<void> _vote(String optionId) async {
    if (_busy || _poll.isClosed) return;
    setState(() => _busy = true);
    try {
      final updated = await ref.read(communitySocialRepositoryProvider).votePoll(widget.communityId, _poll.id, optionId);
      if (mounted) setState(() => _poll = updated);
      final selected = _poll.options.where((option) => option.id == optionId).firstOrNull;
      final isRegistrationOption = selected?.isVoted == true && (selected?.optionText.contains('Có tham gia') == true || selected?.optionText.contains('Đăng ký') == true || selected?.optionText.contains('✅') == true);
      if (isRegistrationOption && widget.tournamentId != null && widget.tournamentInviteCode != null) {
        try {
          await ref.read(tournamentRepositoryProvider).joinLite(widget.tournamentInviteCode!);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã bình chọn và đăng ký tham gia giải.')));
        } catch (_) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã ghi nhận bình chọn. Bạn có thể đã đăng ký giải này trước đó.')));
        }
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể ghi nhận bình chọn.')));
    } finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _addOption() async {
    final controller = TextEditingController();
    final value = await showDialog<String>(context: context, builder: (dialogContext) => AlertDialog(
      title: const Text('Thêm lựa chọn'),
      content: TextField(controller: controller, autofocus: true, maxLength: 100, decoration: const InputDecoration(hintText: 'Nhập lựa chọn')),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Hủy')), FilledButton(onPressed: () => Navigator.pop(dialogContext, controller.text.trim()), child: const Text('Thêm'))],
    ));
    controller.dispose();
    if (value == null || value.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      final updated = await ref.read(communitySocialRepositoryProvider).addPollOption(widget.communityId, _poll.id, value);
      if (mounted) setState(() => _poll = updated);
    } catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể thêm lựa chọn.'))); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final total = _poll.options.fold<int>(0, (sum, option) => sum + option.voteCount);
    final sortedOptions = [..._poll.options]..sort((a, b) {
      int score(String text) {
        if (text.contains('Có tham gia') || text.contains('Đăng ký') || text.contains('✅')) return 1;
        if (text.contains('Chưa chắc chắn') || text.contains('suy nghĩ') || text.contains('⏳')) return 2;
        if (text.contains('Không') || text.contains('Bận') || text.contains('❌')) return 3;
        return 2;
      }
      return score(a.optionText).compareTo(score(b.optionText));
    });

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      decoration: BoxDecoration(color: colors.bgSurface, borderRadius: BorderRadius.circular(AppTheme.radiusMedium), border: Border.all(color: colors.borderLight)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(Icons.poll_outlined, color: AppTheme.primary), const SizedBox(width: AppTheme.spacingSM), Expanded(child: Text(_poll.question, style: const TextStyle(fontWeight: FontWeight.w600))), if (_poll.isClosed) Text('Đã đóng', style: TextStyle(color: colors.textMuted, fontSize: 12))]),
        const SizedBox(height: AppTheme.spacingSM),
        ...sortedOptions.map((option) {
          final ratio = total == 0 ? 0.0 : option.voteCount / total;
          return Padding(padding: const EdgeInsets.only(bottom: 8), child: InkWell(onTap: _busy || _poll.isClosed ? null : () => _vote(option.id), borderRadius: BorderRadius.circular(AppTheme.radiusSmall), child: Stack(children: [
            ClipRRect(borderRadius: BorderRadius.circular(AppTheme.radiusSmall), child: LinearProgressIndicator(value: ratio, minHeight: 42, color: AppTheme.primary.withValues(alpha: .18), backgroundColor: colors.bgCard)),
            Positioned.fill(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Row(children: [Expanded(child: Text(option.optionText, style: TextStyle(fontWeight: option.isVoted ? FontWeight.w600 : FontWeight.w400))), Text('${option.voteCount}', style: TextStyle(color: colors.textMuted, fontSize: 12)), if (option.isVoted) ...[const SizedBox(width: 4), Icon(Icons.check_circle, size: 16, color: AppTheme.primary)]]))),
          ])));
        }),
        if (_poll.allowAddOptions && !_poll.isClosed) Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: _busy ? null : _addOption, icon: const Icon(Icons.add, size: 18), label: const Text('Thêm lựa chọn'))),
        Text('$total lượt bình chọn', style: TextStyle(color: colors.textMuted, fontSize: 12)),
      ]),
    );
  }
}
