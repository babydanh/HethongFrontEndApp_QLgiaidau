import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/data/models/community_social_models.dart';
import 'package:app_quanly_giaidau/domain/repositories/community_repository.dart';
import 'package:flutter/material.dart';

class CommunitySocialSettingsSheet extends StatefulWidget {
  final ICommunityRepository repository;
  final String communityId;
  final String? sportSlug;
  final String? sportName;

  const CommunitySocialSettingsSheet({
    super.key,
    required this.repository,
    required this.communityId,
    this.sportSlug,
    this.sportName,
  });

  static Future<CommunitySocialSettings?> show(
    BuildContext context, {
    required ICommunityRepository repository,
    required String communityId,
    String? sportSlug,
    String? sportName,
  }) => showModalBottomSheet<CommunitySocialSettings>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CommunitySocialSettingsSheet(
      repository: repository,
      communityId: communityId,
      sportSlug: sportSlug,
      sportName: sportName,
    ),
  );

  @override
  State<CommunitySocialSettingsSheet> createState() =>
      _CommunitySocialSettingsSheetState();
}

class _CommunitySocialSettingsSheetState
    extends State<CommunitySocialSettingsSheet> {
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    try {
      final socialFuture = widget.repository
          .getSocialSettings(widget.communityId)
          .timeout(const Duration(seconds: 10))
          .catchError((_) => const CommunitySocialSettings());
      final presetsFuture = widget.repository
          .getTagPresets(widget.communityId)
          .timeout(const Duration(seconds: 10))
          .catchError((_) => const <CommunityTagPreset>[]);

      final results = await Future.wait([socialFuture, presetsFuture]);
      if (!mounted) return;
      setState(() {
        _settings = results[0] as CommunitySocialSettings;
        _presets = results[1] as List<CommunityTagPreset>;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      setState(() {
        _loading = false;
        _error =
            l10n?.communitySocialSettingsLoadError ??
            'Không thể tải cài đặt sinh hoạt CLB.';
      });
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final next = await widget.repository.updateSocialSettings(
        widget.communityId,
        _settings,
      );
      if (!mounted) return;
      setState(() {
        _settings = next;
        _saving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.communitySocialSettingsSaveSuccess ??
                  'Đã lưu cài đặt sinh hoạt CLB',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error =
              l10n?.communitySocialSettingsSaveError ?? 'Lưu cài đặt thất bại.';
        });
      }
    }
  }

  Future<void> _createPreset() async {
    final l10n = AppLocalizations.of(context);
    final name = _nameController.text.trim();
    if (name.isEmpty || _presets.length >= 20) return;
    try {
      final preset = await widget.repository.createTagPreset(
        widget.communityId,
        name: name,
        color: _color,
      );
      if (!mounted) return;
      setState(() {
        _presets = [..._presets, preset];
        _nameController.clear();
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              l10n?.communitySocialSettingsCreateTagError ??
              'Không thể tạo tag.',
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Container(
        constraints: const BoxConstraints(maxHeight: 720, minHeight: 240),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: _loading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: CircularProgressIndicator(),
                ),
              )
            : ListView(
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.communitySocialSettingsTitle,
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context, _settings),
                        tooltip: l10n.communitySocialSettingsClose,
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  Text(
                    l10n.communitySocialSettingsDescription,
                    style: TextStyle(color: colors.textSecondary, fontSize: 12),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        _error!,
                        style: TextStyle(color: colors.error, fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 16),
                  _select(
                    l10n.communitySocialSettingsPostingPolicy,
                    _settings.postingPolicy,
                    {
                      'MEMBERS': l10n.communitySocialSettingsMembers,
                      'ADMINS': l10n.communitySocialSettingsAdmins,
                      'OFF': l10n.communitySocialSettingsPostingOff,
                    },
                    (value) => setState(
                      () =>
                          _settings = _settings.copyWith(postingPolicy: value),
                    ),
                  ),
                  _select(
                    l10n.communitySocialSettingsTaggingPolicy,
                    _settings.memberTaggingPolicy,
                    {
                      'MEMBERS': l10n.communitySocialSettingsMembers,
                      'ADMINS': l10n.communitySocialSettingsAdmins,
                      'OFF': l10n.communitySocialSettingsTaggingOff,
                    },
                    (value) => setState(
                      () => _settings = _settings.copyWith(
                        memberTaggingPolicy: value,
                      ),
                    ),
                  ),
                  _toggle(
                    l10n.communitySocialSettingsApproval,
                    _settings.postApprovalRequired,
                    (value) => setState(
                      () => _settings = _settings.copyWith(
                        postApprovalRequired: value,
                      ),
                    ),
                  ),
                  _toggle(
                    l10n.communitySocialSettingsComments,
                    _settings.commentsEnabled,
                    (value) => setState(
                      () => _settings = _settings.copyWith(
                        commentsEnabled: value,
                      ),
                    ),
                  ),
                  _toggle(
                    l10n.communitySocialSettingsChat,
                    _settings.chatEnabled,
                    (value) => setState(
                      () => _settings = _settings.copyWith(chatEnabled: value),
                    ),
                  ),
                  _toggle(
                    l10n.communitySocialSettingsPublicFeed,
                    _settings.publicFeed,
                    (value) => setState(
                      () => _settings = _settings.copyWith(publicFeed: value),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildMatchPermissions(colors),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(
                      _saving
                          ? l10n.communitySocialSettingsSaving
                          : l10n.communitySocialSettingsSave,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    l10n.communitySocialSettingsTagPresetsTitle,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.communitySocialSettingsTagPresetsDescription,
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText: l10n.communitySocialSettingsTagNameHint,
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () async {
                          final picked = await showDialog<String>(
                            context: context,
                            builder: (_) => _ColorDialog(initial: _color),
                          );
                          if (picked != null) setState(() => _color = picked);
                        },
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: _hex(_color),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: colors.border),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _createPreset,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  if (_presets.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        children: _presets
                            .map(
                              (p) => InputChip(
                                label: Text(p.name),
                                avatar: CircleAvatar(
                                  backgroundColor: _hex(p.color),
                                  radius: 7,
                                ),
                                onDeleted: () async {
                                  await widget.repository.deleteTagPreset(
                                    widget.communityId,
                                    p.id,
                                  );
                                  if (mounted) {
                                    setState(
                                      () => _presets = _presets
                                          .where((item) => item.id != p.id)
                                          .toList(),
                                    );
                                  }
                                },
                              ),
                            )
                            .toList(),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildMatchPermissions(AppColorsExtension colors) {
    final sport = _normalizedSportSlug(widget.sportSlug);
    final preset = _presetForSport(sport);
    final defaults = _defaultPreset(sport);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quyền trận đấu',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Mặc định thành viên được tạo trận và chấm điểm live.',
            style: TextStyle(fontSize: 12, color: colors.textSecondary),
          ),
          _toggle(
            'Thành viên được tạo trận',
            _settings.memberMatchCreationEnabled,
            (value) => setState(
              () => _settings = _settings.copyWith(
                memberMatchCreationEnabled: value,
              ),
            ),
          ),
          _toggle(
            'Thành viên được chấm điểm',
            _settings.memberMatchScoringEnabled,
            (value) => setState(
              () => _settings = _settings.copyWith(
                memberMatchScoringEnabled: value,
              ),
            ),
          ),
          _toggle(
            'Cho phép thành viên xoá trận đã kết thúc',
            _settings.memberMatchDeletionEnabled,
            (value) => setState(
              () => _settings = _settings.copyWith(
                memberMatchDeletionEnabled: value,
              ),
            ),
          ),
          if (sport.isNotEmpty) ...[
            const Divider(height: 16),
            Text(
              'Preset chấm điểm${widget.sportName?.trim().isNotEmpty == true ? ' · ${widget.sportName!.trim()}' : ''}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Áp dụng cho trận tạo mới, trận đang đánh giữ nguyên luật cũ.',
              style: TextStyle(fontSize: 11, color: colors.textSecondary),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _numberSelect(
                    'Set thắng',
                    _presetInt(preset, 'setsToWin', defaults['setsToWin']!),
                    const [1, 2, 3, 4, 5],
                    (value) => _updatePreset(sport, 'setsToWin', value),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _numberSelect(
                    'Điểm mỗi set',
                    _presetInt(
                      preset,
                      'pointsPerSet',
                      defaults['pointsPerSet']!,
                    ),
                    const [1, 7, 11, 15, 21, 25, 30, 40, 99],
                    (value) => _updatePreset(sport, 'pointsPerSet', value),
                  ),
                ),
              ],
            ),
            _numberSelect(
              'Giới hạn điểm tối đa',
              _presetInt(preset, 'maxPoints', defaults['maxPoints']!),
              const [1, 7, 11, 15, 21, 25, 30, 40, 99],
              (value) => _updatePreset(sport, 'maxPoints', value),
            ),
            _toggle(
              'Phải hơn 2 điểm',
              _presetBool(
                preset,
                'mustWinByTwo',
                defaults['mustWinByTwo']! == 1,
              ),
              (value) => _updatePreset(sport, 'mustWinByTwo', value),
            ),
          ],
        ],
      ),
    );
  }

  Widget _numberSelect(
    String label,
    int value,
    List<int> values,
    ValueChanged<int> onChanged,
  ) {
    final effectiveValue = values.contains(value) ? value : values.first;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DropdownButtonFormField<int>(
        key: ValueKey('${label}_$effectiveValue'),
        initialValue: effectiveValue,
        isDense: true,
        decoration: InputDecoration(labelText: label, isDense: true),
        items: values
            .map((item) => DropdownMenuItem(value: item, child: Text('$item')))
            .toList(),
        onChanged: (next) {
          if (next != null) onChanged(next);
        },
      ),
    );
  }

  String _normalizedSportSlug(String? value) {
    final raw = value?.trim().toLowerCase() ?? '';
    if (raw.isEmpty) return '';
    if (raw.contains('pickle')) return 'pickleball';
    if (raw.contains('badminton') || raw.contains('cầu lông')) {
      return 'badminton';
    }
    if (raw.contains('table') || raw.contains('bóng bàn')) {
      return 'table_tennis';
    }
    if (raw.contains('football') ||
        raw.contains('soccer') ||
        raw.contains('bóng đá')) {
      return 'football';
    }
    if (raw.contains('tennis')) return 'tennis';
    return raw.replaceAll(RegExp(r'\s+'), '_');
  }

  Map<String, dynamic> _presetForSport(String sport) {
    final raw = _settings.matchScoringPresets[sport];
    return raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
  }

  Map<String, int> _defaultPreset(String sport) {
    switch (sport) {
      case 'tennis':
        return const {
          'setsToWin': 2,
          'pointsPerSet': 6,
          'maxPoints': 7,
          'mustWinByTwo': 1,
        };
      case 'badminton':
        return const {
          'setsToWin': 2,
          'pointsPerSet': 21,
          'maxPoints': 30,
          'mustWinByTwo': 1,
        };
      case 'table_tennis':
        return const {
          'setsToWin': 3,
          'pointsPerSet': 11,
          'maxPoints': 99,
          'mustWinByTwo': 1,
        };
      case 'football':
        return const {
          'setsToWin': 1,
          'pointsPerSet': 1,
          'maxPoints': 99,
          'mustWinByTwo': 0,
        };
      default:
        return const {
          'setsToWin': 2,
          'pointsPerSet': 11,
          'maxPoints': 15,
          'mustWinByTwo': 1,
        };
    }
  }

  int _presetInt(Map<String, dynamic> preset, String key, int fallback) {
    final value = preset[key];
    return value is num ? value.toInt() : int.tryParse('$value') ?? fallback;
  }

  bool _presetBool(Map<String, dynamic> preset, String key, bool fallback) =>
      preset[key] is bool ? preset[key] as bool : fallback;

  void _updatePreset(String sport, String key, Object value) {
    final presets = Map<String, dynamic>.from(_settings.matchScoringPresets);
    final preset = _presetForSport(sport);
    preset[key] = value;
    presets[sport] = preset;
    setState(
      () => _settings = _settings.copyWith(matchScoringPresets: presets),
    );
  }

  Widget _toggle(String title, bool value, ValueChanged<bool> onChanged) =>
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: Text(title),
        value: value,
        onChanged: onChanged,
      );
  Widget _select(
    String title,
    String value,
    Map<String, String> items,
    ValueChanged<String> onChanged,
  ) {
    final effectiveValue = items.containsKey(value) ? value : items.keys.first;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DropdownButtonFormField<String>(
        key: ValueKey('${title}_$effectiveValue'),
        initialValue: effectiveValue,
        decoration: InputDecoration(labelText: title, isDense: true),
        items: items.entries
            .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
            .toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }

  Color _hex(String value) {
    final hex = value.replaceFirst('#', '');
    return Color(
      int.tryParse('FF${hex.length == 6 ? hex : '3B82F6'}', radix: 16) ??
          0xFF3B82F6,
    );
  }
}

class _ColorDialog extends StatelessWidget {
  final String initial;
  const _ColorDialog({required this.initial});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.communitySocialSettingsColorTitle),
      content: Wrap(
        spacing: 12,
        runSpacing: 12,
        children:
            const [
                  '#3B82F6',
                  '#10B981',
                  '#F59E0B',
                  '#EF4444',
                  '#8B5CF6',
                  '#EC4899',
                ]
                .map(
                  (color) => InkWell(
                    onTap: () => Navigator.pop(context, color),
                    child: CircleAvatar(
                      backgroundColor: Color(
                        int.parse('FF${color.substring(1)}', radix: 16),
                      ),
                      radius: 18,
                    ),
                  ),
                )
                .toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.communitySocialSettingsClose),
        ),
      ],
    );
  }
}
