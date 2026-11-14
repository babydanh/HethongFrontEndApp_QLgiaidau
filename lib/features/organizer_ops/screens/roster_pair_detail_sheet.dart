import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/domain/entities/roster_import.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/screens/roster_import_draft.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/screens/roster_import_widgets.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/utils/roster_excel_parser.dart';
import 'package:app_quanly_giaidau/features/organizer_ops/utils/roster_pairing.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

/// Kết quả sửa một cặp. Trường chuỗi `null` nghĩa là để trống (không có dữ liệu).
/// [delete] true: người dùng chọn xóa cặp, các trường khác không có nghĩa.
class RosterRowEdit {
  const RosterRowEdit({
    required this.player1Name,
    required this.player1Email,
    required this.player1Phone,
    required this.player2Name,
    required this.player2Email,
    required this.player2Phone,
    required this.isPaid,
    required this.notes,
    required this.player1Link,
    required this.player2Link,
  }) : delete = false;

  const RosterRowEdit.delete()
    : player1Name = null,
      player1Email = null,
      player1Phone = null,
      player2Name = null,
      player2Email = null,
      player2Phone = null,
      isPaid = false,
      notes = null,
      player1Link = const RosterPlayerLink.auto(),
      player2Link = const RosterPlayerLink.auto(),
      delete = true;

  final String? player1Name;
  final String? player1Email;
  final String? player1Phone;
  final String? player2Name;
  final String? player2Email;
  final String? player2Phone;
  final bool isPaid;
  final String? notes;
  final RosterPlayerLink player1Link;
  final RosterPlayerLink player2Link;
  final bool delete;
}

/// Mở chi tiết một cặp. Trả `null` khi đóng không bấm `Xong`. Không gọi mạng, không đọc provider.
Future<RosterRowEdit?> showRosterPairDetailSheet(
  BuildContext context, {
  required RosterDraftRow row,
  required List<String> reasonCodes,
  required bool customResponseError,
  required List<RosterImportBatchCandidate> candidates1,
  required List<RosterImportBatchCandidate> candidates2,
  required bool showPlayer2,
  required bool readOnly,
  bool allowDelete = true,
}) {
  return showModalBottomSheet<RosterRowEdit>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _RosterPairDetail(
      row: row,
      reasonCodes: reasonCodes,
      customResponseError: customResponseError,
      candidates1: candidates1,
      candidates2: candidates2,
      showPlayer2: showPlayer2,
      readOnly: readOnly,
      allowDelete: allowDelete,
    ),
  );
}

class _RosterPairDetail extends StatefulWidget {
  const _RosterPairDetail({
    required this.row,
    required this.reasonCodes,
    required this.customResponseError,
    required this.candidates1,
    required this.candidates2,
    required this.showPlayer2,
    required this.readOnly,
    required this.allowDelete,
  });

  final RosterDraftRow row;
  final List<String> reasonCodes;
  final bool customResponseError;
  final List<RosterImportBatchCandidate> candidates1;
  final List<RosterImportBatchCandidate> candidates2;
  final bool showPlayer2;
  final bool readOnly;
  final bool allowDelete;

  @override
  State<_RosterPairDetail> createState() => _RosterPairDetailState();
}

class _RosterPairDetailState extends State<_RosterPairDetail> {
  late final TextEditingController _name1;
  late final TextEditingController _phone1;
  late final TextEditingController _email1;
  late final TextEditingController _name2;
  late final TextEditingController _phone2;
  late final TextEditingController _email2;
  late final TextEditingController _notes;
  late bool _isPaid;
  late RosterPlayerLink _link1;
  late RosterPlayerLink _link2;

  @override
  void initState() {
    super.initState();
    final parsed = widget.row.parsed;
    _name1 = TextEditingController(text: parsed.player1Name ?? '');
    _phone1 = TextEditingController(text: parsed.player1Phone ?? '');
    _email1 = TextEditingController(text: parsed.player1Email ?? '');
    _name2 = TextEditingController(text: parsed.player2Name ?? '');
    _phone2 = TextEditingController(text: parsed.player2Phone ?? '');
    _email2 = TextEditingController(text: parsed.player2Email ?? '');
    _notes = TextEditingController(text: parsed.notes ?? '');
    _isPaid = parsed.isPaid;
    _link1 = widget.row.player1Link;
    _link2 = widget.row.player2Link;
  }

  @override
  void dispose() {
    for (final controller in [
      _name1,
      _phone1,
      _email1,
      _name2,
      _phone2,
      _email2,
      _notes,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _clean(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : text;
  }

  void _done() {
    Navigator.of(context).pop(
      RosterRowEdit(
        player1Name: _clean(_name1),
        player1Email: _clean(_email1),
        player1Phone: _clean(_phone1),
        player2Name: _clean(_name2),
        player2Email: _clean(_email2),
        player2Phone: _clean(_phone2),
        isPaid: _isPaid,
        notes: _clean(_notes),
        player1Link: _link1,
        player2Link: _link2,
      ),
    );
  }

  Color _codeTone(AppColorsExtension colors, String code) {
    if (code == 'FOUND') return colors.success;
    if (code == 'NOT_FOUND') return colors.textMuted;
    if (rosterServerBlockingCodes.contains(code) ||
        rosterLocalBlockingCodes.contains(code)) {
      return colors.error;
    }
    return colors.warning;
  }

  Widget _reasons(AppLocalizations l10n, AppColorsExtension colors) {
    final chips = <Widget>[
      for (final code in widget.reasonCodes)
        rosterToneChip(rosterStatusLabel(l10n, code), _codeTone(colors, code)),
      if (widget.customResponseError)
        rosterToneChip(l10n.rosterImportCustomResponseInvalid, colors.error),
    ];
    if (chips.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        key: const ValueKey('roster-detail-reasons'),
        spacing: 6,
        runSpacing: 6,
        children: chips,
      ),
    );
  }

  Widget _field({
    required Key key,
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? errorText,
    int maxLines = 1,
    List<TextInputFormatter>? formatters,
  }) {
    return TextField(
      key: key,
      controller: controller,
      enabled: !widget.readOnly,
      keyboardType: keyboardType,
      maxLines: maxLines,
      inputFormatters: formatters,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        isDense: true,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _accountButton({
    required AppLocalizations l10n,
    required AppColorsExtension colors,
    required int player,
    required List<RosterImportBatchCandidate> candidates,
    required RosterPlayerLink link,
    required ValueChanged<RosterPlayerLink> onChanged,
  }) {
    if (candidates.isEmpty) return const SizedBox.shrink();
    var label = l10n.rosterListAccountAuto;
    if (link.choice == RosterLinkChoice.unlinked) {
      label = l10n.rosterListAccountNone;
    } else if (link.choice == RosterLinkChoice.linked) {
      for (final candidate in candidates) {
        if (candidate.userId == link.userId) {
          label = l10n.rosterImportCandidateLabel(
            candidate.fullName,
            candidate.email,
          );
        }
      }
    }
    return PopupMenuButton<RosterPlayerLink>(
      key: ValueKey('roster-detail-account-$player'),
      enabled: !widget.readOnly,
      onSelected: onChanged,
      itemBuilder: (_) => [
        PopupMenuItem(
          value: const RosterPlayerLink.auto(),
          child: Text(l10n.rosterListAccountAuto),
        ),
        PopupMenuItem(
          value: const RosterPlayerLink.unlinked(),
          child: Text(l10n.rosterImportLeaveUnlinked),
        ),
        for (final candidate in candidates)
          PopupMenuItem(
            value: RosterPlayerLink.linked(candidate.userId),
            child: Text(
              l10n.rosterImportCandidateLabel(
                candidate.fullName,
                candidate.email,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Row(
          children: [
            Icon(Icons.link_rounded, size: 20, color: colors.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 24,
              color: colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _playerBlock({
    required AppLocalizations l10n,
    required AppColorsExtension colors,
    required int player,
    required TextEditingController name,
    required TextEditingController phone,
    required TextEditingController email,
    required List<RosterImportBatchCandidate> candidates,
    required RosterPlayerLink link,
    required ValueChanged<RosterPlayerLink> onLink,
  }) {
    final emailText = email.text.trim();
    final emailInvalid =
        emailText.isNotEmpty && !rosterIsEmailFormat(emailText);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _field(
          key: ValueKey('roster-detail-name-$player'),
          controller: name,
          label: l10n.rosterListPlayerName(player),
        ),
        const SizedBox(height: 10),
        _field(
          key: ValueKey('roster-detail-phone-$player'),
          controller: phone,
          label: l10n.rosterListPlayerPhone(player),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 10),
        _field(
          key: ValueKey('roster-detail-email-$player'),
          controller: email,
          label: l10n.rosterListPlayerEmail(player),
          keyboardType: TextInputType.emailAddress,
          errorText: emailInvalid ? l10n.rosterListEmailInvalid : null,
        ),
        _accountButton(
          l10n: l10n,
          colors: colors,
          player: player,
          candidates: candidates,
          link: link,
          onChanged: onLink,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Material(
            color: colors.bgCard,
            clipBehavior: Clip.antiAlias,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.rosterListDetailTitle,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        key: const ValueKey('roster-detail-close'),
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close_rounded,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _reasons(l10n, colors),
                        _playerBlock(
                          l10n: l10n,
                          colors: colors,
                          player: 1,
                          name: _name1,
                          phone: _phone1,
                          email: _email1,
                          candidates: widget.candidates1,
                          link: _link1,
                          onLink: (value) => setState(() => _link1 = value),
                        ),
                        if (widget.showPlayer2) ...[
                          Divider(height: 28, color: colors.border),
                          _playerBlock(
                            l10n: l10n,
                            colors: colors,
                            player: 2,
                            name: _name2,
                            phone: _phone2,
                            email: _email2,
                            candidates: widget.candidates2,
                            link: _link2,
                            onLink: (value) => setState(() => _link2 = value),
                          ),
                        ],
                        const SizedBox(height: 8),
                        CheckboxListTile(
                          key: const ValueKey('roster-detail-paid'),
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          value: _isPaid,
                          onChanged: widget.readOnly
                              ? null
                              : (value) =>
                                    setState(() => _isPaid = value ?? false),
                          title: Text(l10n.rosterListPaid),
                        ),
                        const SizedBox(height: 4),
                        _field(
                          key: const ValueKey('roster-detail-notes'),
                          controller: _notes,
                          label: l10n.rosterListNotes,
                          maxLines: 4,
                          formatters: [
                            LengthLimitingTextInputFormatter(rosterNotesMax),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: colors.border)),
                  ),
                  child: Row(
                    children: [
                      if (widget.allowDelete)
                        TextButton.icon(
                          key: const ValueKey('roster-detail-delete'),
                          style: TextButton.styleFrom(
                            foregroundColor: colors.error,
                            minimumSize: const Size(48, 48),
                          ),
                          onPressed: widget.readOnly
                              ? null
                              : () => Navigator.of(
                                  context,
                                ).pop(const RosterRowEdit.delete()),
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: Text(l10n.rosterListDelete),
                        ),
                      const Spacer(),
                      FilledButton(
                        key: const ValueKey('roster-detail-done'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(96, 48),
                        ),
                        onPressed: widget.readOnly ? null : _done,
                        child: Text(l10n.rosterListDone),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
