import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/di.dart';
import 'package:app_quanly_giaidau/domain/entities/tournament.dart';
import 'package:app_quanly_giaidau/features/tournament/screens/tournament_management_widgets.dart';
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
    final canRequestPayout =
        completed &&
        profile != null &&
        profile.id.isNotEmpty &&
        profile.id == tournament.creatorId;
    final accessMessage = !completed
        ? l10n.tournamentManagementPayoutRequiresCompleted
        : profile == null
        ? l10n.tournamentManagementPayoutAccessUnverified
        : profile.id.isEmpty || profile.id != tournament.creatorId
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
  final TextEditingController _bankName = TextEditingController();
  final TextEditingController _accountNumber = TextEditingController();
  final TextEditingController _accountName = TextEditingController();
  final TextEditingController _amount = TextEditingController();
  bool _isRequesting = false;
  String? _requestError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _TournamentFinanceContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.canRequestPayout != widget.canRequestPayout) {
      _load();
      if (!widget.canRequestPayout) {
        _bankName.clear();
        _accountNumber.clear();
        _accountName.clear();
        _amount.clear();
        _requestError = null;
      }
    }
  }

  void _load() {
    final repository = ref.read(tournamentManagementRepositoryProvider);
    _feesFuture = repository.getFeesConfig();
    _payoutsFuture = widget.canRequestPayout
        ? repository.getMyPayouts()
        : Future.value(const <Map<String, dynamic>>[]);
  }

  void _reload() => setState(() {
    _requestError = null;
    _load();
  });

  @override
  void dispose() {
    _bankName.dispose();
    _accountNumber.dispose();
    _accountName.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final money = NumberFormat.currency(
      locale: locale,
      name: 'VND',
      symbol: '₫',
      decimalDigits: 0,
    );
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TournamentManagementSectionCard(
          title: l10n.tournamentManagementFinance,
          subtitle: l10n.tournamentManagementFinanceDescription,
          child: FutureBuilder<Map<String, dynamic>>(
            future: _feesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(),
                  ),
                );
              if (snapshot.hasError)
                return TournamentManagementError(onRetry: _reload);
              return _FeeConfiguration(
                values: snapshot.data ?? const {},
                tournament: widget.tournament,
              );
            },
          ),
        ),
        if (widget.canRequestPayout) ...[
          const SizedBox(height: 16),
          TournamentManagementSectionCard(
            title: l10n.tournamentManagementPayoutRequest,
            subtitle: l10n.tournamentManagementPayoutDescription,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.tournamentManagementPayoutMinimum(10000),
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
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _isRequesting ? null : _submitPayout,
                    icon: _isRequesting
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text(
                      _isRequesting
                          ? l10n.tournamentManagementSubmitting
                          : l10n.tournamentManagementRequestPayout,
                    ),
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
          const SizedBox(height: 16),
          TournamentManagementSectionCard(
            title: l10n.tournamentManagementPayoutHistory,
            subtitle: l10n.tournamentManagementPayoutHistoryDescription,
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _payoutsFuture,
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
                  return TournamentManagementError(onRetry: _reload);
                }
                final payouts =
                    (snapshot.data ?? const <Map<String, dynamic>>[])
                        .where(
                          (record) => _payoutBelongsToTournament(
                            record,
                            widget.tournament.id,
                          ),
                        )
                        .toList(growable: false);
                if (payouts.isEmpty) {
                  return TournamentManagementEmpty(
                    title: l10n.tournamentManagementPayoutHistoryEmpty,
                    icon: Icons.receipt_long_outlined,
                  );
                }
                return Column(
                  children: [
                    for (final payout in payouts)
                      _PayoutRecord(payout: payout, money: money),
                  ],
                );
              },
            ),
          ),
        ] else if (widget.payoutAccessMessage != null) ...[
          const SizedBox(height: 16),
          _PayoutAccessNotice(
            message: widget.payoutAccessMessage!,
            onRetry: widget.onRetryAccess,
          ),
        ],
      ],
    );
  }

  Future<void> _submitPayout() async {
    if (_isRequesting || !widget.canRequestPayout) return;
    final bankName = _bankName.text.trim();
    final accountNumber = _accountNumber.text.trim();
    final accountName = _accountName.text.trim();
    final amount = int.tryParse(_amount.text.trim());
    if (bankName.isEmpty ||
        accountNumber.isEmpty ||
        accountName.isEmpty ||
        amount == null ||
        amount < 10000) {
      setState(() => _requestError = 'validation');
      return;
    }
    setState(() {
      _isRequesting = true;
      _requestError = null;
    });
    try {
      await ref
          .read(tournamentManagementRepositoryProvider)
          .requestPayout(
            tournamentId: widget.tournament.id,
            bankName: bankName,
            bankAccountNumber: accountNumber,
            bankAccountName: accountName,
            amountRequested: amount,
          );
      if (!mounted) return;
      _bankName.clear();
      _accountNumber.clear();
      _accountName.clear();
      _amount.clear();
      setState(() {
        _requestError = null;
        _payoutsFuture = widget.canRequestPayout
            ? ref.read(tournamentManagementRepositoryProvider).getMyPayouts()
            : Future.value(const <Map<String, dynamic>>[]);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.tournamentManagementPayoutRequested,
          ),
        ),
      );
    } catch (_) {
      // Do not put request payloads or response details into UI or logs. Keep
      // the form values so the organizer can correct or retry the request.
      if (mounted) setState(() => _requestError = 'server');
    } finally {
      if (mounted) setState(() => _isRequesting = false);
    }
  }
}

class _FeeConfiguration extends ConsumerStatefulWidget {
  const _FeeConfiguration({required this.values, required this.tournament});
  final Map<String, dynamic> values;
  final Tournament tournament;

  @override
  ConsumerState<_FeeConfiguration> createState() => _FeeConfigurationState();
}

class _FeeConfigurationState extends ConsumerState<_FeeConfiguration> {
  late final TextEditingController _entryFeeController = TextEditingController(
    text: (widget.tournament.entryFee ?? 0).round().toString(),
  );
  bool _isSaving = false;
  bool _hasError = false;

  @override
  void didUpdateWidget(covariant _FeeConfiguration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tournament.entryFee != widget.tournament.entryFee) {
      _entryFeeController.text = (widget.tournament.entryFee ?? 0)
          .round()
          .toString();
    }
  }

  @override
  void dispose() {
    _entryFeeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isClub = widget.tournament.communityId?.isNotEmpty == true;
    final isRanked = widget.tournament.isRanked;
    final publicationFee = _asNumber(
      widget.values[isClub
          ? 'feeClub'
          : isRanked
          ? 'feePublicRanked'
          : 'feePublicUnranked'],
    );
    final platformPercentage = _asNumber(
      widget.values[isClub
          ? 'pctClub'
          : isRanked
          ? 'pctPublicRanked'
          : 'pctPublicUnranked'],
    );
    final allowEntryFees = widget.values['allowEntryFees'] != false;
    final lockedStatuses = const {
      'REGISTRATION_CLOSED',
      'IN_PROGRESS',
      'ONGOING',
      'ACTIVE',
      'LIVE',
      'FINISHED',
      'COMPLETED',
      'CANCELLED',
    };
    final isLocked = lockedStatuses.contains(
      widget.tournament.status.toUpperCase(),
    );
    final canEditEntryFee = allowEntryFees && !isLocked;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _entryFeeController,
          enabled: canEditEntryFee && !_isSaving,
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
        if (_hasError) ...[
          const SizedBox(height: 8),
          Text(
            l10n.tournamentManagementSaveError,
            style: TextStyle(color: context.colors.error),
          ),
        ],
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: !canEditEntryFee || _isSaving ? null : _saveEntryFee,
            icon: _isSaving
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(
              _isSaving
                  ? l10n.tournamentManagementSaving
                  : l10n.tournamentManagementSave,
            ),
          ),
        ),
        const SizedBox(height: 8),
        _FeeLine(
          label: l10n.tournamentManagementPublishFee,
          value: publicationFee == null
              ? l10n.tournamentManagementNotSet
              : _money(context, publicationFee),
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

  Future<void> _saveEntryFee() async {
    if (_isSaving) return;
    final digits = _entryFeeController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final entryFee = digits.isEmpty ? 0 : int.tryParse(digits);
    if (entryFee == null) {
      setState(() => _hasError = true);
      return;
    }
    setState(() {
      _isSaving = true;
      _hasError = false;
    });
    try {
      await ref.read(tournamentRepositoryProvider).update(
        widget.tournament.id,
        {'entryFee': entryFee},
      );
      if (!mounted) return;
      ref.invalidate(tournamentProvider(widget.tournament.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.tournamentManagementEntryFeeUpdated,
          ),
        ),
      );
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  double? _asNumber(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  String _money(BuildContext context, double value) => NumberFormat.currency(
    locale: Localizations.localeOf(context).toString(),
    name: 'VND',
    symbol: '₫',
    decimalDigits: 0,
  ).format(value);
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
