import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_widgets.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/tournament_manage_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Chế độ ghép cặp khi sinh VĐV ảo cho nội dung đôi, đối chiếu bộ chọn của
/// Web `MockDataModal`: AUTO ghép 2 dòng liên tiếp thành 1 cặp hoàn chỉnh,
/// INDIVIDUAL_WAITING sinh VĐV lẻ ở trạng thái chờ BTC ghép.
enum MockPairingMode { auto, individualWaiting }

/// Giá trị gửi API (`SeedMockParticipantsDto.pairingMode` của Backend).
String mockPairingModeWire(MockPairingMode mode) =>
    mode == MockPairingMode.auto ? 'AUTO' : 'INDIVIDUAL_WAITING';

/// Sheet sinh VĐV ảo (task 3.4, đối chiếu Web `MockDataModal` +
/// `handleSeedMockData`/`handleClearMockData`): chọn hạng mục, nội dung đôi
/// chọn chế độ ghép, nhập danh sách tên mỗi dòng một VĐV rồi
/// `POST /tournaments/:id/mock-participants`; "Dọn dẹp" xoá hết VĐV ảo của
/// hạng mục qua `DELETE /tournaments/:id/mock-participants` sau confirm.
class MockParticipantsSheet extends ConsumerStatefulWidget {
  const MockParticipantsSheet({
    super.key,
    required this.tournamentId,
    required this.divisions,
    required this.initialDivisionId,
    this.onRefresh,
  });

  final String tournamentId;

  /// Hạng mục của giải để chọn nơi sinh VĐV ảo; trống thì sinh ở cấp giải.
  final List<TournamentDivision> divisions;

  /// Hạng mục chọn sẵn khi mở sheet (dòng hạng mục bấm nút vào).
  final String initialDivisionId;

  /// Gọi sau khi sinh/dọn xong để màn cha tải lại dữ liệu.
  final Future<void> Function()? onRefresh;

  static Future<void> show(
    BuildContext context, {
    required String tournamentId,
    required List<TournamentDivision> divisions,
    required String initialDivisionId,
    Future<void> Function()? onRefresh,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    enableDrag: false,
    showDragHandle: false,
    builder: (_) => MockParticipantsSheet(
      tournamentId: tournamentId,
      divisions: divisions,
      initialDivisionId: initialDivisionId,
      onRefresh: onRefresh,
    ),
  );

  @override
  ConsumerState<MockParticipantsSheet> createState() =>
      _MockParticipantsSheetState();
}

class _MockParticipantsSheetState extends ConsumerState<MockParticipantsSheet> {
  late String _divisionId = widget.initialDivisionId;
  MockPairingMode _pairMode = MockPairingMode.auto;
  final _namesController = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Dòng vào luôn thuộc danh sách, nhưng nếu không khớp thì chọn hạng mục
    // đầu tiên thay vì gửi tham số lạ lên API.
    if (widget.divisions.isNotEmpty &&
        !widget.divisions.any((division) => division.id == _divisionId)) {
      _divisionId = widget.divisions.first.id;
    }
  }

  @override
  void dispose() {
    _namesController.dispose();
    super.dispose();
  }

  TournamentDivision? get _selectedDivision {
    for (final division in widget.divisions) {
      if (division.id == _divisionId) return division;
    }
    return null;
  }

  bool get _isDoubles => _selectedDivision?.isDoubles ?? false;

  /// Tên VĐV nhập mỗi dòng một tên (Web: `mockNamesText.split('\n')`).
  List<String> get _parsedNames => _namesController.text
      .split('\n')
      .map((name) => name.trim())
      .where((name) => name.isNotEmpty)
      .toList(growable: false);

  /// Web `canSeedMock`: không có hạng mục nào thì sinh ở cấp giải, có thì
  /// phải chọn được hạng mục.
  bool get _canGenerate =>
      _parsedNames.isNotEmpty &&
      (widget.divisions.isEmpty || _divisionId.isNotEmpty);

  Future<void> _generate() async {
    if (_busy || !_canGenerate) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _busy = true;
      _error = null;
    });
    final names = _parsedNames;
    // Web: nội dung đôi theo chế độ đang chọn, còn lại luôn AUTO.
    final individual =
        _isDoubles && _pairMode == MockPairingMode.individualWaiting;
    try {
      await ref
          .read(tournamentManagementRepositoryProvider)
          .seedMockParticipants(
            widget.tournamentId,
            names,
            divisionId: _divisionId.isEmpty ? null : _divisionId,
            pairingMode: mockPairingModeWire(
              _isDoubles ? _pairMode : MockPairingMode.auto,
            ),
          );
      await widget.onRefresh?.call();
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              individual
                  ? l10n.mockSeedIndividualSuccess(names.length)
                  : l10n.mockSeedSuccess(names.length),
            ),
          ),
        );
      Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        setState(() {
          _error =
              tournamentSheetServerMessage(error) ??
              ErrorParser.parse(error, l10n.mockActionFailed, l10n);
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _clear() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await confirmTournamentManagementAction(
      context,
      title: l10n.mockClear,
      message: l10n.mockClearConfirmMessage,
      confirmLabel: l10n.mockClear,
      destructive: true,
    );
    if (!confirmed || !mounted || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(tournamentManagementRepositoryProvider)
          .clearMockParticipants(
            widget.tournamentId,
            divisionId: _divisionId.isEmpty ? null : _divisionId,
          );
      await widget.onRefresh?.call();
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.mockCleared)));
    } catch (error) {
      if (mounted) {
        setState(() {
          _error =
              tournamentSheetServerMessage(error) ??
              ErrorParser.parse(error, l10n.mockActionFailed, l10n);
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final individual =
        _isDoubles && _pairMode == MockPairingMode.individualWaiting;
    return TournamentManageSheet(
      title: l10n.mockSheetTitle,
      busy: _busy,
      actions: [
        FilledButton(
          key: const ValueKey('mock-generate'),
          onPressed: (_busy || !_canGenerate) ? null : _generate,
          child: Text(
            individual ? l10n.mockGenerateIndividual : l10n.mockGenerate,
          ),
        ),
        OutlinedButton(
          key: const ValueKey('mock-clear'),
          onPressed: _busy ? null : _clear,
          child: Text(l10n.mockClear),
        ),
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).maybePop(),
          child: Text(l10n.tournamentManagementCancel),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.mockSheetDescription,
            style: TextStyle(color: colors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.info.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.info.withValues(alpha: 0.25)),
            ),
            child: Text(
              l10n.mockSheetNote,
              style: TextStyle(color: colors.textSecondary, fontSize: 12),
            ),
          ),
          const SizedBox(height: 16),
          if (widget.divisions.isNotEmpty) ...[
            Text(
              l10n.mockDivisionLabel,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              key: const ValueKey('mock-division-select'),
              initialValue: _divisionId,
              isExpanded: true,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: [
                for (final division in widget.divisions)
                  DropdownMenuItem(
                    value: division.id,
                    child: Text(
                      '${division.name} '
                      '(${division.isDoubles ? l10n.mockDivisionDoublesBadge : l10n.mockDivisionSinglesBadge})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: _busy
                  ? null
                  : (value) => setState(() => _divisionId = value ?? ''),
            ),
          ],
          if (_isDoubles) ...[
            const SizedBox(height: 16),
            Text(
              l10n.mockPairModeLabel,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(child: _pairModeCard(MockPairingMode.auto)),
                const SizedBox(width: 8),
                Expanded(
                  child: _pairModeCard(MockPairingMode.individualWaiting),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Text(
            l10n.mockNamesLabel,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            key: const ValueKey('mock-names'),
            controller: _namesController,
            enabled: !_busy,
            maxLines: 6,
            minLines: 4,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: l10n.mockNamesPlaceholder,
              hintStyle: TextStyle(
                color: colors.textMuted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            style: const TextStyle(fontSize: 13, height: 1.5),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: colors.error)),
          ],
        ],
      ),
    );
  }

  /// Thẻ chọn chế độ ghép, đối chiếu hai nút của Web `MockDataModal`:
  /// tiêu đề + mô tả, viền nổi khi đang chọn.
  Widget _pairModeCard(MockPairingMode mode) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final selected = _pairMode == mode;
    return InkWell(
      key: ValueKey('mock-pair-mode-${mode.name}'),
      onTap: _busy ? null : () => setState(() => _pairMode = mode),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? colors.info.withValues(alpha: 0.08) : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? colors.info : colors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              mode == MockPairingMode.auto
                  ? l10n.mockPairModeAuto
                  : l10n.mockPairModeIndividual,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              mode == MockPairingMode.auto
                  ? l10n.mockPairModeAutoHint
                  : l10n.mockPairModeIndividualHint,
              style: TextStyle(color: colors.textSecondary, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
