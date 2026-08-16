import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:flutter/material.dart';

/// Editor danh sách liên hệ của CLB, đồng bộ web (SettingsTab.tsx):
/// - 5 loại sẵn có: Facebook, Zalo, Website, Instagram, TikTok + "Khác..." (nhãn tự do)
/// - Thêm/xóa từng dòng, giá trị bắt buộc không trống
class ClubSocialLinksEditor extends StatefulWidget {
  final Map<String, String> initialLinks;
  final ValueChanged<Map<String, String>> onChanged;

  const ClubSocialLinksEditor({
    super.key,
    this.initialLinks = const {},
    required this.onChanged,
  });

  @override
  State<ClubSocialLinksEditor> createState() => _ClubSocialLinksEditorState();
}

class _ClubSocialLinksEditorState extends State<ClubSocialLinksEditor> {
  static const _presetTypes = {
    'facebook': 'Facebook',
    'zalo': 'Zalo',
    'website': 'Website',
    'instagram': 'Instagram',
    'tiktok': 'TikTok',
  };
  static const _customKey = 'custom';

  late Map<String, String> _links;
  String _newType = 'facebook';
  final _customLabelCtrl = TextEditingController();
  final _newValueCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _links = {...widget.initialLinks};
  }

  @override
  void dispose() {
    _customLabelCtrl.dispose();
    _newValueCtrl.dispose();
    super.dispose();
  }

  void _notify() => widget.onChanged(Map.unmodifiable(_links));

  void _addLink() {
    final value = _newValueCtrl.text.trim();
    if (value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập giá trị liên kết.')),
      );
      return;
    }
    String key;
    if (_newType == _customKey) {
      final label = _customLabelCtrl.text.trim();
      if (label.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng nhập nhãn liên kết.')),
        );
        return;
      }
      key = label;
    } else {
      key = _newType;
    }
    setState(() {
      _links = {..._links, key: value};
    });
    _customLabelCtrl.clear();
    _newValueCtrl.clear();
    _notify();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã thêm liên hệ mới!')),
    );
  }

  void _removeLink(String key) {
    setState(() => _links = {..._links}..remove(key));
    _notify();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã xóa liên hệ!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_links.isNotEmpty) ...[
          ..._links.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.bgSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.border.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key[0].toUpperCase() + entry.key.substring(1),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: colors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            entry.value,
                            style: TextStyle(fontSize: 13, color: colors.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline_rounded,
                          size: 18, color: colors.error),
                      onPressed: () => _removeLink(entry.key),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        // Form thêm liên kết mới
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _newType,
                isDense: true,
                decoration: const InputDecoration(isDense: true),
                items: [
                  ..._presetTypes.entries.map(
                    (type) => DropdownMenuItem(value: type.key, child: Text(type.value)),
                  ),
                  const DropdownMenuItem(value: _customKey, child: Text('Khác...')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _newType = value);
                },
              ),
            ),
          ],
        ),
        if (_newType == _customKey) ...[
          const SizedBox(height: 8),
          TextField(
            controller: _customLabelCtrl,
            decoration: const InputDecoration(
              labelText: 'Tên kênh (Telegram, Viber...)',
              isDense: true,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _newValueCtrl,
                decoration: const InputDecoration(
                  hintText: 'Đường dẫn liên kết hoặc số điện thoại...',
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: _addLink,
              child: const Text('Thêm liên kết'),
            ),
          ],
        ),
      ],
    );
  }
}
