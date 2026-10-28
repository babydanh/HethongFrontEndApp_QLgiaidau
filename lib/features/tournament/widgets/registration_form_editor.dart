import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/lavish_kit.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_manage_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── Model: câu hỏi là Map thô để giữ nguyên các thuộc tính App không sửa ───

/// Types the editor can create (a subset of the Web `RegistrationFieldType`).
/// Other types already saved by the Web builder are shown and preserved.
const registrationFormCreatableTypes = [
  'TEXT',
  'NUMBER',
  'SELECT',
  'MULTI_SELECT',
];

bool _isChoice(Object? type) => type == 'SELECT' || type == 'MULTI_SELECT';

/// Questions stored in `tournamentConfig.registrationForm.fields` (any status).
List<Map<String, dynamic>> readRegistrationFormFields(
  Map<String, dynamic> tournamentConfig,
) {
  final form = tournamentConfig['registrationForm'];
  final raw = form is Map ? form['fields'] : null;
  if (raw is! List) return [];
  return [
    for (final field in raw)
      if (field is Map &&
          field['id'] != null &&
          field['label'] != null &&
          field['type'] != null)
        Map<String, dynamic>.from(field),
  ];
}

List<String> _cleanOptions(Object? options) {
  if (options is! List) return [];
  final seen = <String>{};
  for (final option in options) {
    final text = option.toString().trim();
    if (text.isNotEmpty) seen.add(text);
  }
  return seen.toList();
}

/// First invalid question (Web `validateRegistrationFormForPublish`), or null.
({String code, String label})? validateRegistrationFields(
  List<Map<String, dynamic>> fields,
) {
  for (final field in fields) {
    final label = field['label'].toString().trim();
    if (label.isEmpty) return (code: 'missingLabel', label: label);
    if (_isChoice(field['type']) &&
        _cleanOptions(field['options']).length < 2) {
      return (code: 'choiceOptions', label: label);
    }
  }
  return null;
}

Map<String, dynamic> _normalizeField(Map<String, dynamic> field) {
  final normalized = {
    ...field,
    'label': field['label'].toString().trim(),
    'required': field['required'] == true,
  };
  if (_isChoice(field['type'])) {
    normalized['options'] = _cleanOptions(field['options']);
  } else {
    normalized.remove('options');
  }
  return normalized;
}

/// New full `tournamentConfig` (the server overwrites the whole JSONB):
/// every other key is kept and the form is saved as PUBLISHED, which is the
/// only status the registration screen reads.
Map<String, dynamic> buildRegistrationFormConfig({
  required Map<String, dynamic> tournamentConfig,
  required List<Map<String, dynamic>> fields,
  required List<String> allDivisionIds,
}) {
  final existing = tournamentConfig['registrationForm'];
  final form = existing is Map
      ? Map<String, dynamic>.from(existing)
      : <String, dynamic>{};
  final divisionIds = form['divisionIds'];
  return {
    ...tournamentConfig,
    'registrationForm': {
      ...form,
      'version': 1,
      'status': 'PUBLISHED',
      'divisionIds': divisionIds is List && divisionIds.isNotEmpty
          ? divisionIds
          : allDivisionIds,
      'fields': [for (final field in fields) _normalizeField(field)],
    },
  };
}

// ─── Màn hình ───

/// Form đăng ký tuỳ biến cho BTC (màn 9): họ tên + số điện thoại cố định,
/// câu hỏi tuỳ biến kéo đổi thứ tự / vuốt xoá, lưu vào
/// `tournamentConfig.registrationForm` bằng `updateTournament`.
///
/// [answeredFieldIds]: id câu hỏi đã có VĐV trả lời (xoá thì cảnh báo mất).
class RegistrationFormEditorScreen extends ConsumerStatefulWidget {
  const RegistrationFormEditorScreen({
    super.key,
    required this.tournament,
    this.answeredFieldIds = const {},
  });

  final Tournament tournament;
  final Set<String> answeredFieldIds;

  @override
  ConsumerState<RegistrationFormEditorScreen> createState() =>
      _RegistrationFormEditorScreenState();
}

class _RegistrationFormEditorScreenState
    extends ConsumerState<RegistrationFormEditorScreen> {
  late final List<Map<String, dynamic>> _fields = readRegistrationFormFields(
    widget.tournament.tournamentConfig,
  );
  bool _busy = false;
  String? _error;

  /// Type of the next question, picked with the chips under the add button.
  String _newType = registrationFormCreatableTypes.first;

  /// Same lock as the Web builder: closed registration or a started event.
  bool get _locked {
    final status = widget.tournament.status;
    return widget.tournament.isRegistrationLocked ||
        const {
          AppConstants.statusRegistrationClosed,
          AppConstants.statusInProgress,
          AppConstants.statusCompleted,
          AppConstants.statusCancelled,
        }.contains(status);
  }

  Future<void> _addField(String type) async {
    final l10n = AppLocalizations.of(context)!;
    final field = <String, dynamic>{
      'id': 'custom_${DateTime.now().microsecondsSinceEpoch}',
      'label': l10n.registrationFormNewQuestion,
      'type': type,
      'required': false,
      if (_isChoice(type)) 'options': <String>[],
    };
    final edited = await _FieldEditorSheet.show(context, field);
    if (edited == null || !mounted) return;
    setState(() => _fields.add(edited));
  }

  Future<void> _editField(int index) async {
    final edited = await _FieldEditorSheet.show(context, _fields[index]);
    if (edited == null || !mounted) return;
    setState(() => _fields[index] = edited);
  }

  Future<bool> _confirmDelete(Map<String, dynamic> field) async {
    final l10n = AppLocalizations.of(context)!;
    final label = _displayLabel(l10n, field);
    final answered = widget.answeredFieldIds.contains(field['id']);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.registrationFormDeleteTitle),
        content: Text(
          answered
              ? l10n.registrationFormDeleteAnswered(label)
              : l10n.registrationFormDeleteConfirm(label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.tournamentManagementCancel),
          ),
          FilledButton(
            key: const ValueKey('registration-delete-confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.tournamentManagementDelete),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _save() async {
    if (_busy || _locked) return;
    final l10n = AppLocalizations.of(context)!;
    final invalid = validateRegistrationFields(_fields);
    if (invalid != null) {
      setState(() {
        _error = invalid.code == 'missingLabel'
            ? l10n.registrationFormErrorMissingLabel
            : l10n.registrationFormErrorChoice(invalid.label);
      });
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final config = buildRegistrationFormConfig(
        tournamentConfig: widget.tournament.tournamentConfig,
        fields: _fields,
        allDivisionIds: [for (final d in widget.tournament.divisions) d.id],
      );
      await ref.read(tournamentManagementRepositoryProvider).updateTournament(
        widget.tournament.id,
        {'tournamentConfig': config},
      );
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(SnackBar(content: Text(l10n.tournamentManagementSaved)));
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error =
            tournamentSheetServerMessage(error) ??
            l10n.tournamentManagementSaveError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = LavishColors.of(context);
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: colors.text,
        ),
        title: Text(l10n.registrationFormTitle),
        actions: [
          TextButton(
            key: const ValueKey('registration-form-save'),
            onPressed: _busy || _locked ? null : _save,
            style: TextButton.styleFrom(
              foregroundColor: LavishColors.accent,
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            child: Text(l10n.registrationFormSave),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          if (_locked)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
              child: Text(
                l10n.registrationFormLocked,
                style: TextStyle(fontSize: 13, color: colors.muted),
              ),
            ),
          if (_error != null)
            Padding(
              key: const ValueKey('registration-form-error'),
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
              child: Text(
                _error!,
                style: const TextStyle(fontSize: 13, color: LavishColors.bad),
              ),
            ),
          IgnorePointer(
            ignoring: _locked || _busy,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _systemRow('name', l10n.registrationFormSystemName, l10n),
                _systemRow('phone', l10n.registrationFormSystemPhone, l10n),
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  itemCount: _fields.length,
                  onReorderItem: _reorder,
                  itemBuilder: (context, index) => _fieldRow(l10n, index),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                  child: LavishButton(
                    buttonKey: const ValueKey('registration-add-button'),
                    kind: LavishButtonKind.outline,
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: l10n.registrationFormAdd,
                    onPressed: () => _addField(_newType),
                  ),
                ),
                LavishGroupHeader(l10n.registrationFormTypeLabel),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final type in registrationFormCreatableTypes)
                        LavishChipButton(
                          key: ValueKey('registration-add-$type'),
                          label: _typeLabel(l10n, type),
                          selected: _newType == type,
                          onPressed: () => setState(() => _newType = type),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // onReorderItem already adjusts newIndex for the removed item.
  void _reorder(int oldIndex, int newIndex) {
    setState(() => _fields.insert(newIndex, _fields.removeAt(oldIndex)));
  }

  /// Name and phone: always required, never movable or deletable, so the drag
  /// glyph is drawn dim without a handle behind it.
  Widget _systemRow(String id, String title, AppLocalizations l10n) {
    final colors = LavishColors.of(context);
    return LavishRow(
      key: ValueKey('registration-form-system-$id'),
      leading: Icon(
        Icons.drag_indicator_rounded,
        size: 18,
        color: colors.faint,
      ),
      title: title,
      trailing: [
        LavishPill(l10n.registrationFormRequired, tone: LavishTone.bad),
      ],
    );
  }

  Widget _fieldRow(AppLocalizations l10n, int index) {
    final field = _fields[index];
    final id = field['id'].toString();
    final type = field['type'].toString();
    final options = _cleanOptions(field['options']);
    final typeText = _typeLabel(l10n, type);
    final subtitle = options.isEmpty
        ? typeText
        : '$typeText: ${options.join(', ')}';
    final required = field['required'] == true;
    return Dismissible(
      key: ValueKey('registration-field-$id'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(field),
      onDismissed: (_) => setState(() => _fields.removeAt(index)),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: LavishColors.bad,
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: LavishRow(
        background: LavishColors.of(context).surface,
        onTap: () => _editField(index),
        leading: ReorderableDragStartListener(
          key: ValueKey('registration-field-handle-$id'),
          index: index,
          child: Tooltip(
            message: l10n.registrationFormDragHint,
            child: Icon(
              Icons.drag_indicator_rounded,
              size: 18,
              color: LavishColors.of(context).faint,
            ),
          ),
        ),
        title: _displayLabel(l10n, field),
        subtitle: subtitle,
        trailing: [
          LavishPill(
            required
                ? l10n.registrationFormRequired
                : l10n.registrationFormOptional,
            tone: required ? LavishTone.bad : LavishTone.neutral,
          ),
        ],
      ),
    );
  }
}

String _displayLabel(AppLocalizations l10n, Map<String, dynamic> field) {
  final label = field['label'].toString().trim();
  return label.isEmpty ? l10n.registrationFormUnnamed : label;
}

String _typeLabel(AppLocalizations l10n, String type) => switch (type) {
  'NUMBER' => l10n.registrationFormTypeNumber,
  'SELECT' => l10n.registrationFormTypeSelect,
  'MULTI_SELECT' => l10n.registrationFormTypeMultiSelect,
  'TEXTAREA' => l10n.registrationFormTypeTextarea,
  'EMAIL' => l10n.registrationFormTypeEmail,
  'PHONE' => l10n.registrationFormTypePhone,
  'CHECKBOX' => l10n.registrationFormTypeCheckbox,
  'FILE' => l10n.registrationFormTypeFile,
  _ => l10n.registrationFormTypeText,
};

/// Bottom sheet that edits one question; returns the edited copy or null.
class _FieldEditorSheet extends StatefulWidget {
  const _FieldEditorSheet({required this.field});

  final Map<String, dynamic> field;

  static Future<Map<String, dynamic>?> show(
    BuildContext context,
    Map<String, dynamic> field,
  ) => showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _FieldEditorSheet(field: field),
  );

  @override
  State<_FieldEditorSheet> createState() => _FieldEditorSheetState();
}

class _FieldEditorSheetState extends State<_FieldEditorSheet> {
  late final TextEditingController _label = TextEditingController(
    text: widget.field['label'].toString(),
  );
  late final TextEditingController _options = TextEditingController(
    text: _cleanOptions(widget.field['options']).join('\n'),
  );
  late String _type = widget.field['type'].toString();
  late bool _required = widget.field['required'] == true;

  @override
  void dispose() {
    _label.dispose();
    _options.dispose();
    super.dispose();
  }

  void _done() => Navigator.of(context).pop({
    ...widget.field,
    'label': _label.text,
    'type': _type,
    'required': _required,
    if (_isChoice(_type)) 'options': _options.text.split('\n'),
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Keep an already saved Web-only type selectable so it is not lost.
    final types = {...registrationFormCreatableTypes, _type};
    return TournamentManageSheet(
      title: l10n.registrationFormTitle,
      heightFactor: 0.8,
      actions: [
        FilledButton(
          key: const ValueKey('registration-editor-done'),
          onPressed: _done,
          child: Text(l10n.registrationFormDone),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const ValueKey('registration-editor-label'),
            controller: _label,
            maxLength: 200,
            decoration: InputDecoration(
              labelText: l10n.registrationFormQuestionName,
              counterText: '',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Text(l10n.registrationFormTypeLabel),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final type in types)
                ChoiceChip(
                  key: ValueKey('registration-editor-type-$type'),
                  label: Text(_typeLabel(l10n, type)),
                  selected: _type == type,
                  onSelected: (_) => setState(() => _type = type),
                ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.registrationFormRequiredAnswer),
            value: _required,
            onChanged: (value) => setState(() => _required = value),
          ),
          if (_isChoice(_type))
            TextField(
              key: const ValueKey('registration-editor-options'),
              controller: _options,
              minLines: 3,
              maxLines: 8,
              decoration: InputDecoration(
                labelText: l10n.registrationFormOptionsLabel,
                alignLabelWithHint: true,
                border: const OutlineInputBorder(),
              ),
            ),
        ],
      ),
    );
  }
}
