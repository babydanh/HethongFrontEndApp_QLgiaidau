import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/core/widgets/app_text_field.dart';
import 'package:app_quanly_giaidau/core/utils/navigation_helpers.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';

import 'package:app_quanly_giaidau/providers/user_provider.dart';

class TokenInputSheet extends ConsumerStatefulWidget {
  const TokenInputSheet({super.key});

  @override
  ConsumerState<TokenInputSheet> createState() => _TokenInputSheetState();
}

class _TokenInputSheetState extends ConsumerState<TokenInputSheet> {
  final _tokenController = TextEditingController();
  bool _isSubmittingToken = false;
  String? _tokenError;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _submitToken() async {
    final l10n = AppLocalizations.of(context)!;
    final token = _tokenController.text.trim().toUpperCase();
    if (token.isEmpty) {
      setState(() => _tokenError = l10n.tokenInputRequired);
      return;
    }

    setState(() {
      _isSubmittingToken = true;
      _tokenError = null;
    });

    final success = await ref.read(authProvider.notifier).validateToken(token);

    if (!mounted) return;

    if (success) {
      ref.invalidate(userProfileProvider);
      ref.invalidate(userRankingsProvider);
      final auth = ref.read(authProvider);
      final route = NavigationHelper.getTournamentRoute(
        auth.role,
        auth.tournamentId!,
      );
      Navigator.pop(context); // Close bottom sheet
      context.go(route);
    } else {
      final auth = ref.read(authProvider);
      setState(() {
        _isSubmittingToken = false;
        _tokenError = auth.errorMessage ?? l10n.tokenInputInvalid;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget inputField = AppTextFormField(
      controller: _tokenController,
      textAlign: TextAlign.center,
      textCapitalization: TextCapitalization.characters,
      hint: AppLocalizations.of(context)!.tokenInputHint,
      onChanged: (val) {
        if (_tokenError != null) {
          setState(() => _tokenError = null);
        }
      },
      onSubmitted: (_) {
        setState(() => _isSubmittingToken = true);
        _submitToken().then((_) {
          if (mounted && _tokenError != null) {
            setState(() => _isSubmittingToken = false);
          }
        });
      },
    );

    // Rung lắc nhẹ nếu điền sai mã
    if (_tokenError != null) {
      inputField = inputField.animate().shake(
        hz: 5,
        duration: 400.ms,
        curve: Curves.easeInOutCubic,
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        decoration: BoxDecoration(
          color: context.colors.bgCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: context.colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.tokenTournamentCodeTitle,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: context.colors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: context.colors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.tokenTournamentCodeDescription,
              style: TextStyle(
                fontSize: 13,
                color: context.colors.textSecondary.withValues(alpha: 0.8),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            inputField,
            if (_tokenError != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 16,
                    color: context.colors.error,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _tokenError!,
                    style: TextStyle(
                      color: context.colors.error,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 200.ms),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmittingToken
                    ? null
                    : () {
                        setState(() => _isSubmittingToken = true);
                        _submitToken().then((_) {
                          if (mounted && _tokenError != null) {
                            setState(() => _isSubmittingToken = false);
                          }
                        });
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppTheme.primary.withValues(
                    alpha: 0.4,
                  ),
                  shadowColor: Colors.transparent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmittingToken
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        AppLocalizations.of(context)!.lite_confirmButton,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
