import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/community_social_models.dart';
import 'package:app_quanly_giaidau/domain/repositories/community_repository.dart';
import 'package:flutter/material.dart';

class CommunitySocialSettingsSheet extends StatefulWidget {
  final ICommunityRepository repository;
  final String communityId;

  const CommunitySocialSettingsSheet({super.key, required this.repository, required this.communityId});

  static Future<void> show(BuildContext context, {required ICommunityRepository repository, required String communityId}) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => CommunitySocialSettingsSheet(repository: repository, communityId: communityId),
      );

  @override
  State<CommunitySocialSettingsSheet> createState() => _CommunitySocialSettingsSheetState();
}

class _CommunitySocialSettingsSheetState extends State<CommunitySocialSettingsSheet> {
  CommunitySocialSettings _settings = const CommunitySocialSettings();
  List<CommunityTagPreset> _presets = const [];
  final _nameController = TextEditingController();
  String _color = '#3B82F6';
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        widget.repository.getSocialSettings(widget.communityId),
        widget.repository.getTagPresets(widget.communityId),
      ]);
      if (!mounted) return;
      setState(() {
        _settings = results[0] as CommunitySocialSettings;
        _presets = results[1] as List<CommunityTagPreset>;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = 'Không thể tải cài đặt sinh hoạt CLB.'; });
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final next = await widget.repository.updateSocialSettings(widget.communityId, _settings);
      if (!mounted) return;
      setState(() { _settings = next; _saving = false; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu cài đặt sinh hoạt CLB')));
    } catch (_) {
      if (mounted) setState(() { _saving = false; _error = 'Lưu cài đặt thất bại. Vui lòng thử lại.'; });
    }
  }

  Future<void> _createPreset() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _presets.length >= 20) return;
    try {
      final preset = await widget.repository.createTagPreset(widget.communityId, name: name, color: _color);
      if (!mounted) return;
      setState(() { _presets = [..._presets, preset]; _nameController.clear(); });
    } catch (_) {
      if (mounted) setState(() => _error = 'Không thể tạo tag.');
    }
  }

  @override
  void dispose() { _nameController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SafeArea(
      child: Container(
        constraints: const BoxConstraints(maxHeight: 720),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
        decoration: BoxDecoration(color: colors.bgCard, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        child: _loading
            ? const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator()))
            : ListView(children: [
                Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: colors.border, borderRadius: BorderRadius.circular(4)))),
                const SizedBox(height: 14),
                Row(children: [Expanded(child: Text('Sinh hoạt CLB', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: colors.textPrimary))), IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))]),
                Text('Điều khiển bảng tin, bình luận, chat và tag thành viên.', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                if (_error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_error!, style: TextStyle(color: colors.error, fontSize: 12))),
                const SizedBox(height: 16),
                _select('Quyền đăng bài', _settings.postingPolicy, {'MEMBERS': 'Thành viên', 'ADMINS': 'Ban quản trị', 'OFF': 'Tắt đăng bài'}, (value) => setState(() => _settings = _settings.copyWith(postingPolicy: value))),
                _select('Quyền gắn thẻ', _settings.memberTaggingPolicy, {'MEMBERS': 'Thành viên', 'ADMINS': 'Ban quản trị', 'OFF': 'Tắt gắn thẻ'}, (value) => setState(() => _settings = _settings.copyWith(memberTaggingPolicy: value))),
                _toggle('Bài thành viên phải duyệt', _settings.postApprovalRequired, (value) => setState(() => _settings = _settings.copyWith(postApprovalRequired: value))),
                _toggle('Cho phép bình luận', _settings.commentsEnabled, (value) => setState(() => _settings = _settings.copyWith(commentsEnabled: value))),
                _toggle('Mở chat CLB', _settings.chatEnabled, (value) => setState(() => _settings = _settings.copyWith(chatEnabled: value))),
                _toggle('Cho khách xem bảng tin', _settings.publicFeed, (value) => setState(() => _settings = _settings.copyWith(publicFeed: value))),
                const SizedBox(height: 14),
                FilledButton.icon(onPressed: _saving ? null : _save, icon: const Icon(Icons.save_outlined), label: Text(_saving ? 'Đang lưu...' : 'Lưu cài đặt')),
                const SizedBox(height: 22),
                Text('Tag vui của CLB', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: colors.textPrimary)),
                const SizedBox(height: 4),
                Text('Tạo nhãn màu để gán nhanh cho thành viên.', style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                const SizedBox(height: 10),
                Row(children: [Expanded(child: TextField(controller: _nameController, decoration: const InputDecoration(hintText: 'Ví dụ: MVP tuần', isDense: true))), const SizedBox(width: 8), InkWell(onTap: () async { final picked = await showDialog<String>(context: context, builder: (_) => _ColorDialog(initial: _color)); if (picked != null) setState(() => _color = picked); }, child: Container(width: 42, height: 42, decoration: BoxDecoration(color: _hex(_color), borderRadius: BorderRadius.circular(8), border: Border.all(color: colors.border)))), const SizedBox(width: 8), IconButton.filled(onPressed: _createPreset, icon: const Icon(Icons.add))]),
                if (_presets.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10), child: Wrap(spacing: 7, runSpacing: 7, children: _presets.map((p) => InputChip(label: Text(p.name), avatar: CircleAvatar(backgroundColor: _hex(p.color), radius: 7), onDeleted: () async { await widget.repository.deleteTagPreset(widget.communityId, p.id); if (mounted) setState(() => _presets = _presets.where((item) => item.id != p.id).toList()); })).toList())),
              ]),
      ),
    );
  }

  Widget _toggle(String title, bool value, ValueChanged<bool> onChanged) => SwitchListTile.adaptive(contentPadding: EdgeInsets.zero, title: Text(title), value: value, onChanged: onChanged);
  Widget _select(String title, String value, Map<String, String> items, ValueChanged<String> onChanged) => Padding(padding: const EdgeInsets.only(bottom: 8), child: DropdownButtonFormField<String>(initialValue: value, decoration: InputDecoration(labelText: title, isDense: true), items: items.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(), onChanged: (v) { if (v != null) onChanged(v); }));
  Color _hex(String value) {
    final hex = value.replaceFirst('#', '');
    return Color(int.tryParse('FF${hex.length == 6 ? hex : '3B82F6'}', radix: 16) ?? 0xFF3B82F6);
  }
}

class _ColorDialog extends StatelessWidget {
  final String initial;
  const _ColorDialog({required this.initial});
  @override
  Widget build(BuildContext context) => AlertDialog(title: const Text('Chọn màu tag'), content: Wrap(spacing: 12, runSpacing: 12, children: const ['#3B82F6', '#10B981', '#F59E0B', '#EF4444', '#8B5CF6', '#EC4899'].map((color) => InkWell(onTap: () => Navigator.pop(context, color), child: CircleAvatar(backgroundColor: Color(int.parse('FF${color.substring(1)}', radix: 16)), radius: 18))).toList()), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng'))]);
}
