import 'package:app_quanly_giaidau/features/tournament/utils/tournament_contact.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

const _manualMode = 'MANUAL';
const _profileMode = 'PROFILE';
const _customType = 'custom';
const _linkTypes = ['facebook', 'instagram', 'zalo', 'tiktok', 'website'];

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
  });

  final Map<String, dynamic> initial;
  final ValueChanged<Map<String, dynamic>> onChanged;

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

  OutlineInputBorder get _border => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(
      color: LavishColors.of(context).chipLine,
      width: 1.5,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.contactFormSource,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          key: const ValueKey('info-contact-mode'),
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
              value: _manualMode,
              label: Text(l10n.contactFormSourceManual),
            ),
            ButtonSegment(
              value: _profileMode,
              label: Text(l10n.contactFormSourceProfile),
            ),
          ],
          selected: {_manual ? _manualMode : _profileMode},
          onSelectionChanged: (values) => _setMode(values.first),
        ),
        const SizedBox(height: 12),
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
          const SizedBox(height: 12),
        ],
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
          const SizedBox(height: 12),
          _field(
            const ValueKey('info-contact-email'),
            _email,
            l10n.contactEmail,
            (value) => _put('email', value),
            keyboardType: TextInputType.emailAddress,
          ),
        ],
        const SizedBox(height: 16),
        ..._linksSection(l10n),
      ],
    );
  }

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
    decoration: InputDecoration(labelText: label, border: _border),
  );

  List<Widget> _linksSection(AppLocalizations l10n) {
    final links = contactLinks(_info);
    final colors = LavishColors.of(context);
    return [
      Text(
        l10n.contactFormLinks,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      if (links.isEmpty)
        Text(
          l10n.contactFormNoLinks,
          style: TextStyle(fontSize: 12, color: colors.faint),
        ),
      for (final entry in links.entries)
        Row(
          children: [
            Expanded(
              child: Text(
                '${entry.key[0].toUpperCase()}${entry.key.substring(1)}: ${entry.value}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
            ),
            IconButton(
              key: ValueKey('info-contact-link-remove-${entry.key}'),
              tooltip: l10n.contactFormRemove,
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              onPressed: () => _removeLink(entry.key),
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
            ),
          ],
        ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final type in [..._linkTypes, _customType])
            ChoiceChip(
              label: Text(
                type == _customType
                    ? l10n.contactFormTypeCustom
                    : '${type[0].toUpperCase()}${type.substring(1)}',
              ),
              selected: _linkType == type,
              onSelected: (_) => setState(() => _linkType = type),
            ),
        ],
      ),
      if (_linkType == _customType) ...[
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('info-contact-link-label'),
          controller: _linkLabel,
          decoration: InputDecoration(
            labelText: l10n.contactFormCustomLabel,
            hintText: l10n.contactFormCustomLabelHint,
            border: _border,
          ),
        ),
      ],
      const SizedBox(height: 12),
      TextField(
        key: const ValueKey('info-contact-link-value'),
        controller: _linkValue,
        decoration: InputDecoration(
          labelText: l10n.contactFormValue,
          hintText: l10n.contactFormValueHint,
          border: _border,
        ),
      ),
      if (_linkError != null) ...[
        const SizedBox(height: 8),
        Text(
          _linkError!,
          style: const TextStyle(fontSize: 13, color: LavishColors.bad),
        ),
      ],
      const SizedBox(height: 12),
      LavishButton(
        buttonKey: const ValueKey('info-contact-link-add'),
        kind: LavishButtonKind.outline,
        label: l10n.contactFormAdd,
        onPressed: () => _addLink(l10n),
      ),
    ];
  }
}
