import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_quanly_giaidau/core/config/app_constants.dart';
import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/core/di/core_di_providers.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/core/utils/error_parser.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

/// Tạo nhanh Public trên app. Không nhận communityId; quản lý chi tiết mở trên web.
class CreatePublicQuickTournamentScreen extends ConsumerStatefulWidget {
  const CreatePublicQuickTournamentScreen({super.key});

  @override
  ConsumerState<CreatePublicQuickTournamentScreen> createState() =>
      _CreatePublicQuickTournamentScreenState();
}

class _CreatePublicQuickTournamentScreenState
    extends ConsumerState<CreatePublicQuickTournamentScreen> {
  static const _log = AppLogger('CreatePublicQuickTournament');
  final _nameController = TextEditingController();
  final _maxTeamsController = TextEditingController(text: '16');
  String _sport = AppConstants.sportBadminton;
  String _format = AppConstants.formatSingles;
  String _bracket = AppConstants.bracketSingleElimination;
  String _visibility = 'PUBLIC';
  static const _registrationMode = 'APPROVAL';
  bool _isSubmitting = false;
  AppLocalizations get l10n => AppLocalizations.of(context)!;

  Map<String, String> _sportOptions() => {
    AppConstants.sportFootball: l10n.createClubTournament_sportFootball,
    AppConstants.sportPickleball: l10n.createClubTournament_sportPickleball,
    AppConstants.sportBadminton: l10n.createClubTournament_sportBadminton,
    AppConstants.sportTennis: l10n.createClubTournament_sportTennis,
    AppConstants.sportTableTennis: l10n.createClubTournament_sportTableTennis,
  };

  Map<String, String> _formatOptions() => {
    AppConstants.formatSingles: l10n.quickCreateFormatSingles,
    AppConstants.formatDoubles: l10n.quickCreateFormatDoubles,
    AppConstants.formatMixedDoubles: l10n.quickCreateFormatMixedDoubles,
  };

  Map<String, String> _bracketOptions() => {
    AppConstants.bracketSingleElimination: l10n.quickCreateBracketSingle,
    AppConstants.bracketDoubleElimination: l10n.quickCreateBracketDouble,
    AppConstants.bracketRoundRobin: l10n.quickCreateBracketRoundRobin,
    AppConstants.bracketGroupStageKnockout: l10n.quickCreateBracketGroup,
  };

  @override
  void dispose() {
    _nameController.dispose();
    _maxTeamsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final maxTeams = int.tryParse(_maxTeamsController.text.trim());
    if (name.isEmpty) {
      _showError(l10n.quickCreateNameRequired);
      return;
    }
    if (maxTeams == null || maxTeams < 2 || maxTeams > 32) {
      _showError(l10n.quickCreateMaxTeamsInvalid);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final response = await ref
          .read(dioClientProvider)
          .dio
          .post(
            '/tournaments/lite',
            data: {
              'name': name,
              'sport': _sport,
              'format': _format,
              if (_format == AppConstants.formatMixedDoubles)
                'genderRestriction': 'MIXED',
              'bracketType': _bracket,
              'maxTeams': maxTeams,
              'visibility': _visibility,
              'registrationMode': _registrationMode,
              'isRanked': false,
            },
          );
      final raw = response.data;
      final payload =
          raw is Map<String, dynamic> && raw['data'] is Map<String, dynamic>
          ? raw['data'] as Map<String, dynamic>
          : raw is Map<String, dynamic>
          ? raw
          : <String, dynamic>{};
      final tournamentId = payload['id']?.toString() ?? '';
      if (tournamentId.isEmpty) {
        throw FormatException(l10n.quickCreateMissingId);
      }
      _log.info('Tạo Public Quick thành công: $tournamentId');
      await _openWebManagement(tournamentId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.quickCreateCreated)));
        context.pop();
      }
    } catch (error, stack) {
      _log.error('Không thể tạo Public Quick', error, stack);
      if (mounted) {
        _showError(ErrorParser.parse(error, l10n.quickCreateSubmitError));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _openWebManagement(String tournamentId) async {
    final uri = Uri.parse(
      '${AppConstants.appDomain}/organizer/tournaments/$tournamentId/manage',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw FormatException(l10n.quickCreateOpenWebError);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: context.colors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.bgDark,
      appBar: AppBar(title: Text(l10n.quickCreateTitle), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            l10n.quickCreateHeading,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.quickCreateDescription,
            style: TextStyle(color: colors.textMuted, height: 1.35),
          ),
          const SizedBox(height: 20),
          _label(l10n.quickCreateNameLabel, colors),
          const SizedBox(height: 6),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(hintText: l10n.quickCreateNameHint),
          ),
          const SizedBox(height: 18),
          _label(l10n.quickCreateSportLabel, colors),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _sport,
            items: _sportOptions().entries
                .map(
                  (entry) => DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _sport = value ?? _sport),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _dropdown(
                  l10n.quickCreateFormatLabel,
                  _format,
                  _formatOptions(),
                  (value) => setState(() => _format = value),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _dropdown(
                  l10n.quickCreateBracketLabel,
                  _bracket,
                  _bracketOptions(),
                  (value) => setState(() => _bracket = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _label(l10n.quickCreateMaxTeamsLabel, colors),
          const SizedBox(height: 6),
          TextField(
            controller: _maxTeamsController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(hintText: l10n.quickCreateMaxTeamsHint),
          ),
          const SizedBox(height: 18),
          _choiceGroup(
            l10n.quickCreateVisibilityLabel,
            {
              'PUBLIC': l10n.quickCreateVisibilityPublic,
              'PRIVATE': l10n.quickCreateVisibilityPrivate,
            },
            _visibility,
            (value) => setState(() => _visibility = value),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border),
            ),
            child: Text(
              l10n.quickCreateRegistrationNote,
              style: TextStyle(
                fontSize: 12,
                color: colors.textSecondary,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border),
            ),
            child: Text(
              l10n.quickCreateClubNote,
              style: TextStyle(
                fontSize: 12,
                color: colors.textSecondary,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isSubmitting ? null : _submit,
            child: Text(
              _isSubmitting
                  ? l10n.quickCreateSubmitting
                  : l10n.quickCreateSubmit,
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text, AppColorsExtension colors) => Text(
    text,
    style: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: colors.textSecondary,
    ),
  );

  Widget _dropdown(
    String label,
    String value,
    Map<String, String> options,
    ValueChanged<String> onChanged,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: context.colors.textSecondary,
        ),
      ),
      const SizedBox(height: 6),
      DropdownButtonFormField<String>(
        initialValue: value,
        items: options.entries
            .map(
              (entry) => DropdownMenuItem(
                value: entry.key,
                child: Text(entry.value, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: (next) {
          if (next != null) onChanged(next);
        },
      ),
    ],
  );

  Widget _choiceGroup(
    String title,
    Map<String, String> options,
    String value,
    ValueChanged<String> onChanged,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: context.colors.textSecondary,
        ),
      ),
      const SizedBox(height: 8),
      RadioGroup<String>(
        groupValue: value,
        onChanged: (next) {
          if (next != null) onChanged(next);
        },
        child: Column(
          children: options.entries
              .map(
                (entry) => RadioListTile<String>(
                  value: entry.key,
                  title: Text(entry.value),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              )
              .toList(),
        ),
      ),
    ],
  );
}
