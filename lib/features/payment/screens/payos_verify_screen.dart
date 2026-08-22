import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class PayOSVerifyScreen extends ConsumerStatefulWidget {
  final String paymentId;
  final double amount;
  final String tournamentId;
  final String? tournamentName;
  final String? paymentUrl;
  final String? qrCode;
  final String? expiresAt;
  final String? orderCode;

  const PayOSVerifyScreen({
    super.key,
    required this.paymentId,
    required this.amount,
    required this.tournamentId,
    this.tournamentName,
    this.paymentUrl,
    this.qrCode,
    this.expiresAt,
    this.orderCode,
  });

  @override
  ConsumerState<PayOSVerifyScreen> createState() => _PayOSVerifyScreenState();
}

class _PayOSVerifyScreenState extends ConsumerState<PayOSVerifyScreen> {
  bool _isChecking = false;
  Timer? _autoCheckTimer;
  int _checkAttempts = 0;

  @override
  void initState() {
    super.initState();
    // PayOS links expire after 15 minutes, so keep polling for the full lifetime.
    _autoCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_checkAttempts >= 180) {
        _autoCheckTimer?.cancel();
        return;
      }
      _checkAttempts++;
      _verifyPaymentStatus(silent: true);
    });
  }

  @override
  void dispose() {
    _autoCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _verifyPaymentStatus({bool silent = false}) async {
    final l10n = AppLocalizations.of(context)!;
    if (!silent) {
      setState(() => _isChecking = true);
    }

    try {
      final payment = await ref
          .read(paymentRepositoryProvider)
          .getPaymentById(widget.paymentId);
      if (payment != null) {
        if (payment.isCompleted && mounted) {
          _autoCheckTimer?.cancel();
          context.pushReplacement(
            '/payment/result',
            extra: {
              'status': 'success',
              'tournamentId': widget.tournamentId,
              'amount': widget.amount,
            },
          );
          return;
        } else if (payment.isTerminalFailure && mounted) {
          _autoCheckTimer?.cancel();
          context.pushReplacement(
            '/payment/result',
            extra: {
              'status': 'fail',
              'tournamentId': widget.tournamentId,
              'amount': widget.amount,
            },
          );
          return;
        }
      }
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.payosVerifyPaymentNotReceived),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorParser.parse(e, l10n.payosVerifyPaymentError)),
          ),
        );
      }
    } finally {
      if (!silent && mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fmt = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bgDark,
      appBar: AppBar(
        title: Text(l10n.payosVerifyTitle),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5622).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  size: 40,
                  color: Color(0xFFFF5622),
                ),
              ).animate().scale(
                delay: 100.ms,
                duration: 400.ms,
                curve: Curves.easeOutBack,
              ),
              const SizedBox(height: 24),
              Text(
                l10n.payosVerifyPayOSHeading,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.payosVerifyInstruction,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: colors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              if (widget.qrCode != null && widget.qrCode!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: colors.border),
                  ),
                  child: QrImageView(
                    data: widget.qrCode!,
                    size: 220,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.payosVerifyQrLabel,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
              ],
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colors.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.payosVerifyAmountLabel,
                          style: TextStyle(color: colors.textSecondary),
                        ),
                        Text(
                          '${fmt.format(widget.amount.ceil())}đ',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.payosVerifyStatusLabel,
                          style: TextStyle(color: colors.textSecondary),
                        ),
                        Row(
                          children: [
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.payosVerifyPendingStatus,
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
              if (widget.paymentUrl != null && widget.paymentUrl!.isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () => launchUrl(
                      Uri.parse(widget.paymentUrl!),
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: Text(l10n.payosVerifyOpenPaymentPage),
                  ),
                ),
              const SizedBox(height: 16),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _isChecking ? null : () => _verifyPaymentStatus(),
                  icon: _isChecking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_rounded),
                  label: Text(
                    l10n.payosVerifyPaidButton,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  _autoCheckTimer?.cancel();
                  context.pushReplacement('/home');
                },
                child: Text(
                  l10n.payosVerifyCancelButton,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
