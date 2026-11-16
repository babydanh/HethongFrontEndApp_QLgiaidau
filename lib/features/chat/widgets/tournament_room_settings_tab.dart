import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament_chat_moderation.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Saves one change; returns false when the server refused it.
typedef RoomSettingsSaver =
    Future<bool> Function({int? slowModeSeconds, bool? locked});

/// "Settings" tab of the manage-room sheet: slow mode 0–60 s and lock.
class TournamentRoomSettingsTab extends StatefulWidget {
  const TournamentRoomSettingsTab({
    super.key,
    required this.slowModeSeconds,
    required this.locked,
    required this.onSave,
  });

  final int slowModeSeconds;
  final bool locked;
  final RoomSettingsSaver onSave;

  @override
  State<TournamentRoomSettingsTab> createState() =>
      _TournamentRoomSettingsTabState();
}

class _TournamentRoomSettingsTabState extends State<TournamentRoomSettingsTab> {
  late int _slowMode = widget.slowModeSeconds.clamp(0, kChatSlowModeMaxSeconds);
  late bool _locked = widget.locked;
  bool _saving = false;

  Future<void> _saveSlowMode(int seconds) async {
    final previous = widget.slowModeSeconds;
    setState(() => _saving = true);
    final ok = await widget.onSave(slowModeSeconds: seconds);
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (!ok) _slowMode = previous;
    });
  }

  Future<void> _saveLocked(bool locked) async {
    setState(() {
      _locked = locked;
      _saving = true;
    });
    final ok = await widget.onSave(locked: locked);
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (!ok) _locked = !locked;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        ListTile(
          title: Text(l10n.chatRoomSlowModeTitle),
          subtitle: Text(
            _slowMode > 0
                ? l10n.chatRoomSlowModeDuration(_slowMode)
                : l10n.chatRoomSlowModeOff,
            style: TextStyle(color: colors.textMuted),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Slider(
            value: _slowMode.toDouble(),
            max: kChatSlowModeMaxSeconds.toDouble(),
            divisions: kChatSlowModeMaxSeconds,
            label: '$_slowMode',
            onChanged: _saving
                ? null
                : (v) => setState(() => _slowMode = v.round()),
            onChangeEnd: _saving ? null : (v) => _saveSlowMode(v.round()),
          ),
        ),
        const Divider(height: 24),
        SwitchListTile(
          title: Text(l10n.chatRoomLockLabel),
          subtitle: Text(
            l10n.chatRoomLockHint,
            style: TextStyle(color: colors.textMuted),
          ),
          value: _locked,
          onChanged: _saving ? null : _saveLocked,
        ),
      ],
    );
  }
}
