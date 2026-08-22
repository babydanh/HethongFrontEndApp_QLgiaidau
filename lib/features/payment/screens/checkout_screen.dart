import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/payment_model.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/providers/query_providers.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final String tournamentId;
  final String participantId;
  final String? divisionId;
  final double amount;
  final String? tournamentName;

  const CheckoutScreen({
    super.key,
    required this.tournamentId,
    required this.participantId,
    this.divisionId,
    required this.amount,
    this.tournamentName,
  });

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String _selectedGateway = 'PAYOS';
  bool _isSubmitting = false;

  Future<void> _handleCheckout(
    double effectiveAmount,
    String? effectiveName,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final rawDivisionId = widget.divisionId?.trim();
    if (rawDivisionId != null &&
        rawDivisionId.isNotEmpty &&
        !isValidUuid(rawDivisionId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.checkout_invalidDivision),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      if (effectiveAmount <= 0) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.checkout_freeConfirm),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/payments');
          }
        }
        return;
      }

      final result = await ref
          .read(paymentRepositoryProvider)
          .createPaymentLink(
            CreatePaymentDto(
              tournamentId: widget.tournamentId,
              participantId: widget.participantId,
              divisionId: widget.divisionId,
            ),
          );

      if (result != null && mounted) {
        final paymentId = result['paymentId'] ?? '';
        final paymentUrl = result['paymentUrl']?.toString() ?? '';
        final qrCode = result['qrCode']?.toString() ?? '';
        final expiresAt = result['expiresAt']?.toString();
        final confirmedAmount =
            double.tryParse(result['amount']?.toString() ?? '') ??
            effectiveAmount;
        if (paymentUrl.isNotEmpty || qrCode.isNotEmpty) {
          final uri = Uri.parse(paymentUrl);
          final opened = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
          if (!opened) {
            throw Exception(l10n.checkout_cannotOpenPayOS);
          }
          if (mounted) {
            context.pushReplacement(
              '/payment/payos-verify',
              extra: {
                'paymentId': paymentId,
                'amount': confirmedAmount,
                'tournamentId': widget.tournamentId,
                'tournamentName': effectiveName,
                'paymentUrl': paymentUrl,
                'qrCode': qrCode,
                'expiresAt': expiresAt,
                'orderCode': result['orderCode']?.toString(),
              },
            );
          }
        } else {
          throw Exception(l10n.checkout_noPaymentLink);
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.checkout_createGatewayError),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ErrorParser.parse(
                e,
                l10n.checkout_createPaymentError,
              ),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;

    final tournamentAsync = widget.tournamentId.isNotEmpty
        ? ref.watch(tournamentProvider(widget.tournamentId))
        : null;
    final tournament = tournamentAsync?.asData?.value;

    final effectiveAmount = widget.amount > 0
        ? widget.amount
        : (tournament?.entryFee != null && tournament!.entryFee! > 0
              ? tournament.entryFee!
              : 0.0);

    final effectiveName =
        (widget.tournamentName != null && widget.tournamentName!.isNotEmpty)
        ? widget.tournamentName
        : (tournament?.name ?? '');

    final isFree = effectiveAmount <= 0;

    return Scaffold(
      backgroundColor: colors.bgDark,
      appBar: AppBar(
        backgroundColor: colors.bgDark,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/profile');
            }
          },
        ),
        title: Text(
          l10n.checkout_title,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                color: colors.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                children: [
                  Text(
                    isFree ? l10n.checkout_freeBadge : l10n.checkout_entryFeeLabel,
                    style: TextStyle(
                      color: isFree
                          ? const Color(0xFF10B981)
                          : colors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isFree ? '0đ' : '${fmt.format(effectiveAmount.ceil())}đ',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (effectiveName != null && effectiveName.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      effectiveName,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            if (!isFree) ...[
              Text(
                l10n.checkout_paymentMethodLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: colors.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),

              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => setState(() => _selectedGateway = 'PAYOS'),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.bgCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _selectedGateway == 'PAYOS'
                            ? AppTheme.primary
                            : colors.border,
                        width: _selectedGateway == 'PAYOS' ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.checkout_payOSLabel,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.checkout_payOSDescription,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _selectedGateway == 'PAYOS'
                                ? AppTheme.primary
                                : Colors.transparent,
                            border: Border.all(
                              color: _selectedGateway == 'PAYOS'
                                  ? AppTheme.primary
                                  : colors.border,
                              width: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            Text(
              l10n.checkout_confirmInstruction,
              style: TextStyle(
                fontSize: 12,
                color: colors.textMuted,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : () => _handleCheckout(effectiveAmount, effectiveName),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        isFree
                            ? l10n.checkout_freeConfirmButton
                            : l10n.checkout_payButton(fmt.format(effectiveAmount.ceil())),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}