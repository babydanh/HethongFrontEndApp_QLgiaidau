import 'package:app_quanly_giaidau/core/participants/participant_display.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/tournament_contact.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

const _manualMode = 'MANUAL';
const _profileMode = 'PROFILE';
const _customType = 'custom';
const _linkTypes = ['facebook', 'instagram', 'zalo', 'tiktok', 'website'];

/// One icon family for the link types (same outline style as the rest of the
/// app); the custom type and any unknown saved key use the plain link icon.
const _linkIcons = <String, IconData>{
  'facebook': Icons.facebook,
  'instagram': Icons.camera_alt_outlined,
  'zalo': Icons.chat_bubble_outline_rounded,
  'tiktok': Icons.music_note_rounded,
  'website': Icons.language_rounded,
  _customType: Icons.link_rounded,
};

IconData _iconFor(String key) => _linkIcons[key] ?? Icons.link_rounded;

String _capitalized(String key) => '${key[0].toUpperCase()}${key.substring(1)}';

/// The organiser contact editor, same fields as the Web "Liên hệ" tab: source
/// (typed in or account profile), name, phone, email and extra links.
///
/// It edits a copy of `contactInfo` and reports the whole map on every change,
/// so settings it does not show (`hidden`...) are sent back untouched.
class TournamentContactForm extends StatefulWidget {
  const TournamentContactForm({
    super.key,
    required this.initial,
    required this.onChanged,
    this.profileName,
    this.profileAvatarUrl,
  });

  final Map<String, dynamic> initial;
  final ValueChanged<Map<String, dynamic>> onChanged;

  /// Account the profile source reads from; shown read-only in the card.
  final String? profileName;
  final String? profileAvatarUrl;

  @override
  State<TournamentContactForm> createState() => _TournamentContactFormState();
}

class _TournamentContactFormState extends State<TournamentContactForm> {
  late Map<String, dynamic> _info = {...widget.initial};
  late final _name = TextEditingController(text: _text('organizerName'));
  late final _phone = TextEditingController(text: _text('phone'));
  late final _email = TextEditingController(text: _text('email'));
  final _linkValue = TextEditingController();
  final _linkLabel = TextEditingController();
  String _linkType = _linkTypes.first;
  String? _linkError;

  // Typed organiser details survive a switch to the profile source, as on Web.
  late String _draftName = _name.text;
  late String _draftPhone = _phone.text;

  String _text(String key) {
    final value = _info[key];
    return value is String ? value.trim() : '';
  }

  bool get _manual => _text('displayMode').toUpperCase() == _manualMode;

  bool get _hidden => _info['hidden'] != false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _linkValue.dispose();
    _linkLabel.dispose();
    super.dispose();
  }

  void _commit(Map<String, dynamic> next) {
    setState(() => _info = next);
    widget.onChanged(Map.of(next));
  }

  void _put(String key, String value) {
    final next = {..._info};
    value.trim().isEmpty ? next.remove(key) : next[key] = value.trim();
    _commit(next);
  }

  void _setMode(String mode) {
    if (_text('displayMode').toUpperCase() == mode) return;
    final next = {..._info, 'displayMode': mode};
    if (mode == _manualMode) {
      _phone.text = _draftPhone;
      _name.text = _draftName;
      next['organizerName'] = _draftName.trim();
      _draftPhone.trim().isEmpty
          ? next.remove('phone')
          : next['phone'] = _draftPhone.trim();
      next.remove('email');
    } else {
      next
        ..remove('organizerName')
        ..remove('phone')
        ..remove('email');
      _phone.clear();
      _email.clear();
    }
    _linkError = null;
    _commit(next);
  }

  void _addLink(AppLocalizations l10n) {
    final value = _linkValue.text.trim();
    final key = _linkType == _customType ? _linkLabel.text.trim() : _linkType;
    final error = value.isEmpty
        ? l10n.contactFormValueRequired
        : key.isEmpty
        ? l10n.contactFormLabelRequired
        : (key.toLowerCase() == 'phone' ||
              key.toLowerCase() == 'email' ||
              isContactMetadataKey(key))
        ? l10n.contactFormDuplicate
        : null;
    if (error != null) {
      setState(() => _linkError = error);
      return;
    }
    _linkValue.clear();
    _linkLabel.clear();
    _linkError = null;
    _commit({..._info, key: value});
  }

  void _removeLink(String key) => _commit({..._info}..remove(key));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sourceSwitch(l10n),
        if (_manual) ...[
          _field(
            const ValueKey('info-contact-name'),
            _name,
            l10n.contactFormOrganizerName,
            (value) {
              _draftName = value;
              _commit({..._info, 'organizerName': value.trim()});
            },
          ),
          const SizedBox(height: 10),
        ] else
          _profileCard(l10n),
        _field(
          const ValueKey('info-contact-phone'),
          _phone,
          l10n.contactPhone,
          (value) {
            if (_manual) _draftPhone = value;
            _put('phone', value);
          },
          keyboardType: TextInputType.phone,
        ),
        if (!_manual) ...[
          const SizedBox(height: 10),
          _field(
            const ValueKey('info-contact-email'),
            _email,
            l10n.contactEmail,
            (value) => _put('email', value),
            keyboardType: TextInputType.emailAddress,
          ),
        ],
        const SizedBox(height: 14),
        ..._linksSection(l10n),
      ],
    );
  }

  /// One row replaces the old two-button source selector.
  Widget _sourceSwitch(AppLocalizations l10n) {
    void toggle(bool profile) => _setMode(profile ? _profileMode : _manualMode);
    return InkWell(
      key: const ValueKey('info-contact-mode'),
      onTap: () => toggle(_manual),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Row(
          children: [
            Expanded(
              child: Text(
                l10n.contactFormSourceProfile,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Switch(value: !_manual, onChanged: toggle),
          ],
        ),
      ),
    );
  }

  /// Read-only: the name comes from the account. Whether the founder is shown
  /// to viewers is set by the eye on the Overview founder row, so only its
  /// current state is mentioned here, and only when hidden.
  Widget _profileCard(AppLocalizations l10n) {
    final colors = LavishColors.of(context);
    final name = widget.profileName?.trim() ?? '';
    final label = name.isEmpty ? l10n.contactFormSourceProfile : name;
    return Container(
      key: const ValueKey('info-contact-profile'),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: LavishColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LavishColors.accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          _profileAvatar(label),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (_hidden)
                  Text(
                    l10n.tournamentContactHiddenHint,
                    style: TextStyle(fontSize: 11, color: colors.faint),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileAvatar(String label) {
    final url = widget.profileAvatarUrl;
    final hasPhoto = url != null && url.isNotEmpty;
    return CircleAvatar(
      radius: 15,
      backgroundColor: avatarFallbackColor(label),
      backgroundImage: hasPhoto ? NetworkImage(url) : null,
      onBackgroundImageError: hasPhoto ? (_, _) {} : null,
      child: hasPhoto
          ? null
          : Text(
              avatarInitials(label),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
    );
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: color, width: 1.5),
  );

  Widget _field(
    Key key,
    TextEditingController controller,
    String label,
    ValueChanged<String> onChanged, {
    TextInputType? keyboardType,
  }) => TextField(
    key: key,
    controller: controller,
    keyboardType: keyboardType,
    onChanged: onChanged,
    decoration: InputDecoration(
      labelText: label,
      border: _border(LavishColors.of(context).chipLine),
    ),
  );

  List<Widget> _linksSection(AppLocalizations l10n) {
    final links = contactLinks(_info);
    return [
      Text(
        l10n.contactFormLinks,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
      for (final entry in links.entries) _linkRow(l10n, entry.key, entry.value),
      const SizedBox(height: 6),
      _typePicker(l10n),
      if (_linkType == _customType) ...[
        const SizedBox(height: 10),
        TextField(
          key: const ValueKey('info-contact-link-label'),
          controller: _linkLabel,
          decoration: InputDecoration(
            labelText: l10n.contactFormCustomLabel,
            hintText: l10n.contactFormCustomLabelHint,
            border: _border(LavishColors.of(context).chipLine),
          ),
        ),
      ],
      const SizedBox(height: 10),
      _valueField(l10n),
      if (_linkError != null) ...[
        const SizedBox(height: 6),
        Text(
          _linkError!,
          style: const TextStyle(fontSize: 13, color: LavishColors.bad),
        ),
      ],
    ];
  }

  Widget _linkRow(AppLocalizations l10n, String key, String value) {
    final colors = LavishColors.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.rowLine)),
      ),
      child: Row(
        children: [
          Icon(_iconFor(key), size: 18, color: colors.muted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            key: ValueKey('info-contact-link-remove-$key'),
            tooltip: l10n.contactFormRemove,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            onPressed: () => _removeLink(key),
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
        ],
      ),
    );
  }

  /// Six round icon buttons in one row; the selected one is filled.
  Widget _typePicker(AppLocalizations l10n) {
    final colors = LavishColors.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final type in [..._linkTypes, _customType])
          Tooltip(
            message: type == _customType
                ? l10n.contactFormTypeCustom
                : _capitalized(type),
            child: InkResponse(
              key: ValueKey('info-contact-link-type-$type'),
              radius: 24,
              onTap: () => setState(() => _linkType = type),
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _linkType == type ? LavishColors.accent : null,
                    border: Border.all(
                      color: _linkType == type
                          ? LavishColors.accent
                          : colors.chipLine,
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    _iconFor(type),
                    size: 18,
                    color: _linkType == type ? Colors.white : colors.muted,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// The tick sits inside the field (like the chat box) and Enter adds too.
  Widget _valueField(AppLocalizations l10n) {
    final custom = _linkType == _customType;
    return TextField(
      key: const ValueKey('info-contact-link-value'),
      controller: _linkValue,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _addLink(l10n),
      decoration: InputDecoration(
        prefixText: custom
            ? '${l10n.contactFormValue}  '
            : '${_capitalized(_linkType)}  ',
        prefixStyle: const TextStyle(
          color: LavishColors.accent,
          fontWeight: FontWeight.w800,
        ),
        hintText: l10n.contactFormValueHint,
        border: _border(LavishColors.accent),
        enabledBorder: _border(LavishColors.accent),
        focusedBorder: _border(LavishColors.accent),
        suffixIcon: IconButton(
          key: const ValueKey('info-contact-link-add'),
          tooltip: l10n.contactFormAdd,
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          onPressed: () => _addLink(l10n),
          icon: const Icon(Icons.check_rounded, color: LavishColors.accent),
        ),
      ),
    );
  }
}
