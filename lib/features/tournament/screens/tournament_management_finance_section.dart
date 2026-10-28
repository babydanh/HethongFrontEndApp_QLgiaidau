import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/dialogs/confirm_dialog.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_widgets.dart';
import 'package:app_quanly_giaidau/features/tournament/utils/platform_fee.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class TournamentManagementFinanceSection extends ConsumerWidget {
  const TournamentManagementFinanceSection({
    super.key,
    required this.tournament,
  });
  final Tournament tournament;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final completed = tournament.status.toUpperCase() == 'COMPLETED';
    final user = ref.watch(userProfileProvider);
    final profile = user.asData?.value;
    final isOrganizer = profile?.hasRole('ORGANIZER') ?? false;
    final canRequestPayout =
        completed &&
        profile != null &&
        profile.id.isNotEmpty &&
        profile.id == tournament.creatorId &&
        isOrganizer;
    final accessMessage = !completed
        ? l10n.tournamentManagementPayoutRequiresCompleted
        : profile == null
        ? l10n.tournamentManagementPayoutAccessUnverified
        : profile.id.isEmpty ||
              profile.id != tournament.creatorId ||
              !isOrganizer
        ? l10n.tournamentManagementPayoutCreatorOnly
        : null;
    return _TournamentFinanceContent(
      tournament: tournament,
      canRequestPayout: canRequestPayout,
      payoutAccessMessage: accessMessage,
      onRetryAccess: user.hasError
          ? () => ref.invalidate(userProfileProvider)
          : null,
    );
  }
}

class _PayoutAccessNotice extends StatelessWidget {
  const _PayoutAccessNotice({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => TournamentManagementSectionCard(
    title: AppLocalizations.of(context)!.tournamentManagementPayoutRequest,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.lock_outline_rounded, color: context.colors.textMuted),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        if (onRetry != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                AppLocalizations.of(context)!.tournamentManagementRetry,
              ),
            ),
          ),
      ],
    ),
  );
}

class _TournamentFinanceContent extends ConsumerStatefulWidget {
  const _TournamentFinanceContent({
    required this.tournament,
    required this.canRequestPayout,
    required this.payoutAccessMessage,
    this.onRetryAccess,
  });
  final Tournament tournament;
  final bool canRequestPayout;
  final String? payoutAccessMessage;
  final VoidCallback? onRetryAccess;

  @override
  ConsumerState<_TournamentFinanceContent> createState() =>
      _TournamentFinanceContentState();
}

class _TournamentFinanceContentState
    extends ConsumerState<_TournamentFinanceContent> {
  late Future<Map<String, dynamic>> _feesFuture;
  late Future<List<Map<String, dynamic>>> _payoutsFuture;
  late final TextEditingController _entryFeeController = TextEditingController(
    text: _savedFee.toString(),
  );
  late int _savedFee = (widget.tournament.entryFee ?? 0).round();
  bool _isSavingFee = false;
  bool _feeError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _TournamentFinanceContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.canRequestPayout != widget.canRequestPayout) _load();
    if (oldWidget.tournament.entryFee != widget.tournament.entryFee) {
      _savedFee = (widget.tournament.entryFee ?? 0).round();
      _entryFeeController.text = _savedFee.toString();
    }
  }

  void _load() {
    final repository = ref.read(tournamentManagementRepositoryProvider);
    _feesFuture = repository.getFeesConfig();
    _payoutsFuture = widget.canRequestPayout
        ? repository.getMyPayouts()
        : Future.value(const <Map<String, dynamic>>[]);
  }

  void _reload() => setState(_load);

  @override
  void dispose() {
    _entryFeeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TournamentManagementSectionCard(
                title: l10n.tournamentManagementFinance,
                subtitle: l10n.tournamentManagementFinanceDescription,
                child: FutureBuilder<Map<String, dynamic>>(
                  future: _feesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return TournamentManagementError(
                        error: snapshot.error,
                        onRetry: _reload,
                      );
                    }
                    return _FeeConfiguration(
                      values: snapshot.data ?? const {},
                      tournament: widget.tournament,
                      controller: _entryFeeController,
                      isSaving: _isSavingFee,
                      hasError: _feeError,
                    );
                  },
                ),
              ),
              if (widget.canRequestPayout) ...[
                const SizedBox(height: 16),
                _PayoutRows(
                  tournamentId: widget.tournament.id,
                  payoutsFuture: _payoutsFuture,
                  onRequested: () => setState(() {
                    _payoutsFuture = ref
                        .read(tournamentManagementRepositoryProvider)
                        .getMyPayouts();
                  }),
                ),
              ] else if (widget.payoutAccessMessage != null) ...[
                const SizedBox(height: 16),
                _PayoutAccessNotice(
                  message: widget.payoutAccessMessage!,
                  onRetry: widget.onRetryAccess,
                ),
              ],
            ],
          ),
        ),
        _buildSaveBar(l10n),
      ],
    );
  }

  /// Pinned "save fee" bar: shown once the fee config is loaded, grey until
  /// the fee differs from the saved value, spinner while saving.
  Widget _buildSaveBar(
    AppLocalizations l10n,
  ) => FutureBuilder<Map<String, dynamic>>(
    future: _feesFuture,
    builder: (context, snapshot) {
      final values = snapshot.data;
      if (values == null) return const SizedBox.shrink();
      final colors = context.colors;
      final canEdit = _canEditEntryFee(values, widget.tournament);
      return DecoratedBox(
        decoration: BoxDecoration(
          color: colors.bgCard,
          border: Border(top: BorderSide(color: colors.border)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_feeError) ...[
                  Text(
                    l10n.tournamentManagementSaveError,
                    style: TextStyle(color: colors.error),
                  ),
                  const SizedBox(height: 8),
                ],
                ListenableBuilder(
                  listenable: _entryFeeController,
                  builder: (context, _) {
                    final dirty = _feeValueOf(_entryFeeController) != _savedFee;
                    return FilledButton(
                      onPressed: canEdit && dirty && !_isSavingFee
                          ? _saveEntryFee
                          : null,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isSavingFee)
                            const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            const Icon(Icons.save_outlined, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            _isSavingFee
                                ? l10n.tournamentManagementSaving
                                : l10n.financeFeeSave,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  Future<void> _saveEntryFee() async {
    if (_isSavingFee) return;
    final entryFee = _feeValueOf(_entryFeeController);
    if (entryFee == null) {
      setState(() => _feeError = true);
      return;
    }
    setState(() {
      _isSavingFee = true;
      _feeError = false;
    });
    try {
      await ref.read(tournamentRepositoryProvider).update(
        widget.tournament.id,
        {'entryFee': entryFee},
      );
      if (!mounted) return;
      _savedFee = entryFee;
      ref.invalidate(tournamentProvider(widget.tournament.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.tournamentManagementEntryFeeUpdated,
          ),
        ),
      );
    } catch (_) {
      if (mounted) setState(() => _feeError = true);
    } finally {
      if (mounted) setState(() => _isSavingFee = false);
    }
  }
}

/// Fee statuses in which the entry fee can no longer be edited.
const _lockedFeeStatuses = {
  'REGISTRATION_CLOSED',
  'IN_PROGRESS',
  'ONGOING',
  'ACTIVE',
  'LIVE',
  'FINISHED',
  'COMPLETED',
  'CANCELLED',
};

bool _canEditEntryFee(Map<String, dynamic> values, Tournament tournament) =>
    values['allowEntryFees'] != false &&
    !_lockedFeeStatuses.contains(tournament.status.toUpperCase());

/// Số tiền đang có trong ô lệ phí (chỉ giữ chữ số); null khi không parse
/// được (ví dụ số quá dài), 0 khi ô trống.
int? _feeValueOf(TextEditingController controller) {
  final digits = controller.text.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return 0;
  return int.tryParse(digits);
}

double? _asNumber(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

NumberFormat _vndFormat(BuildContext context) => NumberFormat.currency(
  locale: Localizations.localeOf(context).toString(),
  name: 'VND',
  symbol: '₫',
  decimalDigits: 0,
);

/// Entry fee field, quick-amount buttons, fee breakdown and the server fee
/// lines. The pinned save bar lives in the parent, which owns the controller.
class _FeeConfiguration extends StatelessWidget {
  const _FeeConfiguration({
    required this.values,
    required this.tournament,
    required this.controller,
    required this.isSaving,
    required this.hasError,
  });
  final Map<String, dynamic> values;
  final Tournament tournament;
  final TextEditingController controller;
  final bool isSaving;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isClub = tournament.communityId?.isNotEmpty == true;
    final isRanked = tournament.isRanked;
    final publicationFee = _asNumber(
      values[isClub
          ? 'feeClub'
          : isRanked
          ? 'feePublicRanked'
          : 'feePublicUnranked'],
    );
    final platformPercentage = _asNumber(
      values[isClub
          ? 'pctClub'
          : isRanked
          ? 'pctPublicRanked'
          : 'pctPublicUnranked'],
    );
    final allowEntryFees = values['allowEntryFees'] != false;
    final canEditEntryFee = _canEditEntryFee(values, tournament);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          enabled: canEditEntryFee && !isSaving,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: l10n.tournamentManagementEntryFee,
            border: const OutlineInputBorder(),
            prefixText: '₫ ',
          ),
        ),
        if (!canEditEntryFee) ...[
          const SizedBox(height: 8),
          Text(
            l10n.tournamentManagementEntryFeeDisabled,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 12),
        // Nút mức phí nhanh + bảng phân tích phí sàn, cập nhật tức thời theo
        // giá trị đang nhập trong ô (port modal "Quick Edit Entry Fee" của
        // Web; Web đọc tỷ lệ từ tournament.platformFeePercentage, App lấy tỷ
        // lệ phí nền tảng theo loại giải từ cấu hình fees đã có ở trên).
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final currentFee = _feeValueOf(controller) ?? 0;
            final breakdown = getPlatformFeeBreakdown(
              currentFee,
              platformFeePercentage: platformPercentage,
            );
            final quickEnabled = canEditEntryFee && !isSaving;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.financeFeeQuickAdjustLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _QuickFeeButton(
                      label: l10n.financeFeeQuickFree,
                      highlighted: currentFee == 0,
                      onPressed: quickEnabled
                          ? () => controller.text = '0'
                          : null,
                    ),
                    for (final amount in const [20000, 50000, 100000, 200000])
                      _QuickFeeButton(
                        label: l10n.financeFeeQuickAdd(amount ~/ 1000),
                        onPressed: quickEnabled
                            ? () => controller.text = (currentFee + amount)
                                  .toString()
                            : null,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _FeeBreakdownPanel(breakdown: breakdown),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        _FeeLine(
          label: l10n.tournamentManagementPublishFee,
          value: publicationFee == null
              ? l10n.tournamentManagementNotSet
              : _vndFormat(context).format(publicationFee),
        ),
        const SizedBox(height: 8),
        _FeeLine(
          label: l10n.tournamentManagementPlatformFeeRate,
          value: platformPercentage == null
              ? l10n.tournamentManagementNotSet
              : '${NumberFormat.decimalPattern(Localizations.localeOf(context).toString()).format(platformPercentage)}%',
        ),
        const SizedBox(height: 8),
        _FeeLine(
          label: l10n.tournamentManagementEntryFeesAllowed,
          value: allowEntryFees
              ? l10n.tournamentManagementYes
              : l10n.tournamentManagementNo,
        ),
        const SizedBox(height: 10),
        Text(
          l10n.tournamentManagementNoClientBalanceCalculation,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// "Request payout" and "payout history" as two tappable rows; the bank form
/// and the history list open in their own bottom sheets.
class _PayoutRows extends StatelessWidget {
  const _PayoutRows({
    required this.tournamentId,
    required this.payoutsFuture,
    required this.onRequested,
  });
  final String tournamentId;
  final Future<List<Map<String, dynamic>>> payoutsFuture;
  final VoidCallback onRequested;

  Future<void> _openRequestSheet(BuildContext context) async {
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _PayoutRequestSheet(tournamentId: tournamentId),
    );
    if (sent != true || !context.mounted) return;
    onRequested();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)!.tournamentManagementPayoutRequested,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TournamentManagementSectionCard(
      title: l10n.tournamentManagementPayoutRequest,
      subtitle: l10n.tournamentManagementPayoutDescription,
      child: Column(
        children: [
          _PayoutNavRow(
            icon: Icons.payments_outlined,
            title: l10n.tournamentManagementRequestPayout,
            subtitle: l10n.tournamentManagementPayoutMinimum(_minPayoutAmount),
            onTap: () => _openRequestSheet(context),
          ),
          Divider(height: 1, color: context.colors.borderLight),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: payoutsFuture,
            builder: (context, snapshot) {
              final count = snapshot.data
                  ?.where(
                    (record) =>
                        _payoutBelongsToTournament(record, tournamentId),
                  )
                  .length;
              return _PayoutNavRow(
                icon: Icons.receipt_long_outlined,
                title: l10n.tournamentManagementPayoutHistory,
                subtitle: count == null
                    ? null
                    : count == 0
                    ? l10n.tournamentManagementPayoutHistoryEmpty
                    : l10n.financePayoutHistoryCount(count),
                onTap: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  showDragHandle: true,
                  builder: (_) =>
                      _PayoutHistorySheet(tournamentId: tournamentId),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PayoutNavRow extends StatelessWidget {
  const _PayoutNavRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: colors.textMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(color: colors.textMuted, fontSize: 12),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: colors.textMuted),
          ],
        ),
      ),
    );
  }
}

/// Minimum payout amount (VND) enforced by the server and checked client side.
const _minPayoutAmount = 10000;

/// Bottom sheet with the bank form. Bank details only live in these
/// controllers: they are never logged, toasted or kept after the sheet closes.
class _PayoutRequestSheet extends ConsumerStatefulWidget {
  const _PayoutRequestSheet({required this.tournamentId});
  final String tournamentId;

  @override
  ConsumerState<_PayoutRequestSheet> createState() =>
      _PayoutRequestSheetState();
}

class _PayoutRequestSheetState extends ConsumerState<_PayoutRequestSheet> {
  final TextEditingController _bankName = TextEditingController();
  final TextEditingController _accountNumber = TextEditingController();
  final TextEditingController _accountName = TextEditingController();
  final TextEditingController _amount = TextEditingController();
  bool _isRequesting = false;
  String? _requestError;

  @override
  void dispose() {
    _bankName.dispose();
    _accountNumber.dispose();
    _accountName.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isRequesting) return;
    final l10n = AppLocalizations.of(context)!;
    final bankName = _bankName.text.trim();
    final accountNumber = _accountNumber.text.trim();
    final accountName = _accountName.text.trim();
    final amount = int.tryParse(_amount.text.trim());
    if (bankName.isEmpty ||
        accountNumber.isEmpty ||
        accountName.isEmpty ||
        amount == null ||
        amount < _minPayoutAmount) {
      setState(() => _requestError = 'validation');
      return;
    }
    final confirmed = await showConfirmDialog(
      context: context,
      title: l10n.financePayoutConfirmTitle,
      content: l10n.financePayoutConfirmBody(
        _vndFormat(context).format(amount),
      ),
      confirmText: l10n.tournamentManagementRequestPayout,
      cancelText: l10n.commonCancel,
      confirmColor: AppTheme.primary,
    );
    if (confirmed != true || !mounted || _isRequesting) return;
    setState(() {
      _isRequesting = true;
      _requestError = null;
    });
    try {
      await ref
          .read(tournamentManagementRepositoryProvider)
          .requestPayout(
            tournamentId: widget.tournamentId,
            bankName: bankName,
            bankAccountNumber: accountNumber,
            bankAccountName: accountName,
            amountRequested: amount,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      // Do not put request payloads or response details into UI or logs. Keep
      // the form values so the organizer can correct or retry the request.
      if (mounted) {
        setState(() {
          _isRequesting = false;
          _requestError = 'server';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopScope(
      canPop: !_isRequesting,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.tournamentManagementPayoutRequest,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.tournamentManagementPayoutMinimum(_minPayoutAmount),
              style: TextStyle(color: context.colors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bankName,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.tournamentManagementBankName,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _accountNumber,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.tournamentManagementBankAccountNumber,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _accountName,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.tournamentManagementBankAccountName,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: false,
              ),
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: l10n.tournamentManagementAmountRequested,
                border: const OutlineInputBorder(),
                prefixText: '₫ ',
              ),
            ),
            if (_requestError != null) ...[
              const SizedBox(height: 10),
              Text(
                _requestError == 'validation'
                    ? l10n.tournamentManagementPayoutValidationError
                    : l10n.tournamentManagementPayoutRequestError,
                style: TextStyle(color: context.colors.error),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _isRequesting ? null : _submit,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isRequesting)
                    const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    const Icon(Icons.send_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    _isRequesting
                        ? l10n.tournamentManagementSubmitting
                        : l10n.tournamentManagementRequestPayout,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.tournamentManagementPayoutAuthorizationNote,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet listing this tournament's payout requests (status and amount
/// only, never bank details).
class _PayoutHistorySheet extends ConsumerStatefulWidget {
  const _PayoutHistorySheet({required this.tournamentId});
  final String tournamentId;

  @override
  ConsumerState<_PayoutHistorySheet> createState() =>
      _PayoutHistorySheetState();
}

class _PayoutHistorySheetState extends ConsumerState<_PayoutHistorySheet> {
  late Future<List<Map<String, dynamic>>> _future = ref
      .read(tournamentManagementRepositoryProvider)
      .getMyPayouts();

  void _retry() => setState(() {
    _future = ref.read(tournamentManagementRepositoryProvider).getMyPayouts();
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final money = _vndFormat(context);
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.tournamentManagementPayoutHistory,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.tournamentManagementPayoutHistoryDescription,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Flexible(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return TournamentManagementError(
                      error: snapshot.error,
                      onRetry: _retry,
                    );
                  }
                  final payouts =
                      (snapshot.data ?? const <Map<String, dynamic>>[])
                          .where(
                            (record) => _payoutBelongsToTournament(
                              record,
                              widget.tournamentId,
                            ),
                          )
                          .toList(growable: false);
                  if (payouts.isEmpty) {
                    return TournamentManagementEmpty(
                      title: l10n.tournamentManagementPayoutHistoryEmpty,
                      icon: Icons.receipt_long_outlined,
                    );
                  }
                  return ListView(
                    shrinkWrap: true,
                    children: [
                      for (final payout in payouts)
                        _PayoutRecord(payout: payout, money: money),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nút mức phí nhanh (0đ / +20k / +50k / +100k / +200k) — port hàng nút
/// tăng nhanh trong modal sửa lệ phí của Web ("Miễn phí (0đ)", "+20.000₫"...).
class _QuickFeeButton extends StatelessWidget {
  const _QuickFeeButton({
    required this.label,
    required this.onPressed,
    this.highlighted = false,
  });

  final String label;
  final VoidCallback? onPressed;

  /// Đang được chọn (mức 0đ khi lệ phí hiện tại bằng 0).
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 34),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        foregroundColor: highlighted ? colors.success : colors.textSecondary,
        side: BorderSide(color: highlighted ? colors.success : colors.border),
      ),
      child: Text(label),
    );
  }
}

/// Bảng phân tích phí sàn theo giá trị lệ phí đang nhập — port khối
/// "Platform fee & net breakdown" của Web: lệ phí thu / VĐV, phí sàn (kèm
/// tỷ lệ %), và phần BTC thực nhận / VĐV.
class _FeeBreakdownPanel extends StatelessWidget {
  const _FeeBreakdownPanel({required this.breakdown});

  final PlatformFeeBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final money = NumberFormat.currency(
      locale: locale,
      name: 'VND',
      symbol: '₫',
      decimalDigits: 0,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.chipBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.borderLight),
      ),
      child: Column(
        children: [
          _BreakdownRow(
            label: Text(
              l10n.financeFeeCollectedPerPlayer,
              style: TextStyle(color: colors.textSecondary, fontSize: 12),
            ),
            value: Text(
              breakdown.entryFee > 0
                  ? money.format(breakdown.entryFee)
                  : l10n.financeFeeFreeLabel,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 6),
          _BreakdownRow(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    l10n.financeFeePlatformFeePerPlayer,
                    style: TextStyle(color: colors.textSecondary, fontSize: 12),
                  ),
                ),
                if (breakdown.percentage > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: colors.borderLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${NumberFormat.decimalPattern(locale).format(breakdown.percentage)}%',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            value: Text(
              breakdown.feePerPlayer > 0
                  ? '-${money.format(breakdown.feePerPlayer)}'
                  : money.format(0),
              textAlign: TextAlign.end,
              style: TextStyle(
                color: colors.warning,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Divider(height: 16, color: colors.borderLight),
          _BreakdownRow(
            label: Text(
              l10n.financeFeeOrganizerNetPerPlayer,
              style: TextStyle(
                color: colors.success,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            value: Text(
              money.format(breakdown.organizerNet),
              textAlign: TextAlign.end,
              style: TextStyle(
                color: colors.success,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({required this.label, required this.value});

  final Widget label;
  final Widget value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: label),
      const SizedBox(width: 12),
      value,
    ],
  );
}

class _FeeLine extends StatelessWidget {
  const _FeeLine({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Expanded(
          child: Text(label, style: TextStyle(color: colors.textSecondary)),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

bool _payoutBelongsToTournament(
  Map<String, dynamic> record,
  String tournamentId,
) {
  final tournamentValue = record['tournament'];
  if (tournamentValue is Map) {
    return (tournamentValue['id'] ?? '').toString() == tournamentId;
  }
  final payoutValue = record['payout'];
  if (payoutValue is Map) {
    return (payoutValue['tournamentId'] ??
                payoutValue['tournament_id'] ??
                record['tournamentId'] ??
                record['tournament_id'] ??
                '')
            .toString() ==
        tournamentId;
  }
  return (record['tournamentId'] ?? record['tournament_id'] ?? '').toString() ==
      tournamentId;
}

class _PayoutRecord extends StatelessWidget {
  const _PayoutRecord({required this.payout, required this.money});
  final Map<String, dynamic> payout;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final detailsValue = payout['payout'];
    final details = detailsValue is Map
        ? Map<String, dynamic>.from(detailsValue)
        : payout;
    final rawAmount = details['amountRequested'] ?? details['amount_requested'];
    final amount = rawAmount is num
        ? rawAmount.toDouble()
        : double.tryParse(rawAmount?.toString() ?? '');
    final status = _statusLabel(l10n, (details['status'] ?? '').toString());
    final rawDate =
        (details['createdAt'] ??
                details['created_at'] ??
                details['requestedAt'] ??
                '')
            .toString();
    final parsedDate = DateTime.tryParse(rawDate);
    final date = parsedDate == null
        ? ''
        : MaterialLocalizations.of(
            context,
          ).formatMediumDate(parsedDate.toLocal());
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.receipt_long_outlined, color: colors.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (date.isNotEmpty)
                  Text(
                    date,
                    style: TextStyle(color: colors.textMuted, fontSize: 12),
                  ),
              ],
            ),
          ),
          if (amount != null)
            Text(
              money.format(amount),
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }

  String _statusLabel(AppLocalizations l10n, String status) =>
      switch (status.toUpperCase()) {
        'PENDING' => l10n.tournamentManagementPayoutStatusPending,
        'APPROVED' => l10n.tournamentManagementPayoutStatusApproved,
        'REJECTED' => l10n.tournamentManagementPayoutStatusRejected,
        'PAID' || 'COMPLETED' => l10n.tournamentManagementPayoutStatusPaid,
        'PROCESSING' => l10n.tournamentManagementPayoutStatusProcessing,
        _ => l10n.tournamentManagementStatusOther,
      };
}
