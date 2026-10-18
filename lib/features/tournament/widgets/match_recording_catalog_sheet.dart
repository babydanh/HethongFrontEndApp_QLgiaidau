import 'dart:async';

import 'package:app_quanly_giaidau/core/config/app_theme.dart';
import 'package:app_quanly_giaidau/data/models/match_recording_catalog_model.dart';
import 'package:app_quanly_giaidau/features/tournament/widgets/match_recording_player_sheet.dart';
import 'package:app_quanly_giaidau/l10n/app_localizations.dart';
import 'package:app_quanly_giaidau/providers/match_recording_catalog_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showMatchRecordingCatalogSheet(
  BuildContext context, {
  required String matchId,
  required String matchLabel,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) =>
        MatchRecordingCatalogSheet(matchId: matchId, matchLabel: matchLabel),
  );
}

class MatchRecordingCatalogSheet extends ConsumerStatefulWidget {
  const MatchRecordingCatalogSheet({
    super.key,
    required this.matchId,
    required this.matchLabel,
  });

  final String matchId;
  final String matchLabel;

  @override
  ConsumerState<MatchRecordingCatalogSheet> createState() =>
      _MatchRecordingCatalogSheetState();
}

class _MatchRecordingCatalogSheetState
    extends ConsumerState<MatchRecordingCatalogSheet> {
  bool _loadingInitial = true;
  bool _initialError = false;
  int? _initialFailureStatusCode;
  bool _hasCamera = false;
  bool _loadingFiles = false;
  bool _filesError = false;
  int? _filesFailureStatusCode;
  List<String> _days = const <String>[];
  String? _selectedDay;
  List<MatchRecordingFileModel> _files = const <MatchRecordingFileModel>[];
  int _requestGeneration = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_loadInitial(showLoading: false));
    });
  }

  @override
  void didUpdateWidget(covariant MatchRecordingCatalogSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.matchId == widget.matchId) return;
    _requestGeneration++;
    _loadingInitial = true;
    _initialError = false;
    _initialFailureStatusCode = null;
    _hasCamera = false;
    _loadingFiles = false;
    _filesError = false;
    _filesFailureStatusCode = null;
    _days = const <String>[];
    _selectedDay = null;
    _files = const <MatchRecordingFileModel>[];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_loadInitial(showLoading: false));
    });
  }

  @override
  void dispose() {
    _requestGeneration++;
    super.dispose();
  }

  Future<void> _loadInitial({required bool showLoading}) async {
    final generation = ++_requestGeneration;
    if (showLoading && mounted) {
      setState(() {
        _loadingInitial = true;
        _initialError = false;
        _initialFailureStatusCode = null;
        _loadingFiles = false;
        _filesError = false;
        _filesFailureStatusCode = null;
        _files = const <MatchRecordingFileModel>[];
      });
    }

    try {
      final repository = ref.read(matchRecordingCatalogRepositoryProvider);
      final control = await repository.getMatchControlState(widget.matchId);
      if (!_isCurrent(generation)) return;
      if (!control.hasCamera) {
        setState(() {
          _loadingInitial = false;
          _hasCamera = false;
          _days = const <String>[];
          _selectedDay = null;
          _files = const <MatchRecordingFileModel>[];
        });
        return;
      }

      final dayModel = await repository.listRecordingDays(widget.matchId);
      if (!_isCurrent(generation)) return;
      final days = dayModel.days;
      final selectedDay = days.isEmpty ? null : days.first;
      setState(() {
        _loadingInitial = false;
        _initialError = false;
        _initialFailureStatusCode = null;
        _hasCamera = true;
        _days = days;
        _selectedDay = selectedDay;
        _loadingFiles = selectedDay != null;
        _filesError = false;
        _filesFailureStatusCode = null;
        _files = const <MatchRecordingFileModel>[];
      });
      if (selectedDay != null) {
        await _loadFiles(selectedDay, generation);
      }
    } catch (error) {
      if (!_isCurrent(generation)) return;
      setState(() {
        _loadingInitial = false;
        _initialError = true;
        _initialFailureStatusCode = _terminalReadStatusCode(error);
        _loadingFiles = false;
      });
    }
  }

  Future<void> _loadFiles(String day, int generation) async {
    try {
      final files = await ref
          .read(matchRecordingCatalogRepositoryProvider)
          .listRecordings(widget.matchId, period: day);
      if (!_isCurrent(generation)) return;
      setState(() {
        _loadingFiles = false;
        _filesError = false;
        _filesFailureStatusCode = null;
        _files = files;
      });
    } catch (error) {
      if (!_isCurrent(generation)) return;
      setState(() {
        _loadingFiles = false;
        _filesError = true;
        _filesFailureStatusCode = _terminalReadStatusCode(error);
        _files = const <MatchRecordingFileModel>[];
      });
    }
  }

  bool _isCurrent(int generation) =>
      mounted && generation == _requestGeneration;

  void _selectDay(String? day) {
    if (day == null || day == _selectedDay || !_days.contains(day)) return;
    final generation = ++_requestGeneration;
    setState(() {
      _selectedDay = day;
      _loadingFiles = true;
      _filesFailureStatusCode = null;
      _filesError = false;
      _files = const <MatchRecordingFileModel>[];
    });
    unawaited(_loadFiles(day, generation));
  }

  void _retryFiles() {
    final day = _selectedDay;
    if (day == null) return;
    final generation = ++_requestGeneration;
    setState(() {
      _loadingFiles = true;
      _filesFailureStatusCode = null;
      _filesError = false;
      _files = const <MatchRecordingFileModel>[];
    });
    unawaited(_loadFiles(day, generation));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppTheme.spacingMD,
            AppTheme.spacingSM,
            AppTheme.spacingMD,
            MediaQuery.viewInsetsOf(context).bottom + AppTheme.spacingMD,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.tournamentManagementRecordingTitle,
                          style: theme.textTheme.titleLarge,
                        ),
                        Text(
                          widget.matchLabel,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.close,
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingMD),
              if (_loadingInitial)
                _LoadingMessage(
                  message: l10n.tournamentManagementRecordingLoading,
                )
              else if (_initialError)
                _ErrorMessage(
                  message: _recordingErrorMessage(
                    l10n,
                    _initialFailureStatusCode,
                  ),
                  retryLabel: _isTerminalReadFailure(_initialFailureStatusCode)
                      ? null
                      : l10n.opsRetry,
                  onRetry: _isTerminalReadFailure(_initialFailureStatusCode)
                      ? null
                      : () => unawaited(_loadInitial(showLoading: true)),
                )
              else if (!_hasCamera)
                _InfoMessage(
                  message: l10n.tournamentManagementRecordingNoCamera,
                )
              else if (_days.isEmpty)
                _InfoMessage(message: l10n.tournamentManagementRecordingNoDays)
              else ...[
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.tournamentManagementRecordingDay,
                    border: const OutlineInputBorder(),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      key: const ValueKey('recording-day-selector'),
                      value: _selectedDay,
                      isExpanded: true,
                      items: [
                        for (final day in _days)
                          DropdownMenuItem<String>(
                            value: day,
                            child: Text(day, maxLines: 1),
                          ),
                      ],
                      onChanged: _isTerminalReadFailure(_filesFailureStatusCode)
                          ? null
                          : _selectDay,
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingSM),
                if (_loadingFiles)
                  _LoadingMessage(
                    message: l10n.tournamentManagementRecordingFilesLoading,
                  )
                else if (_filesError)
                  _ErrorMessage(
                    message: _recordingErrorMessage(
                      l10n,
                      _filesFailureStatusCode,
                    ),
                    retryLabel: _isTerminalReadFailure(_filesFailureStatusCode)
                        ? null
                        : l10n.opsRetry,
                    onRetry: _isTerminalReadFailure(_filesFailureStatusCode)
                        ? null
                        : _retryFiles,
                  )
                else if (_files.isEmpty)
                  _InfoMessage(
                    message: l10n.tournamentManagementRecordingNoFiles,
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _files.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final file = _files[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const ExcludeSemantics(
                          child: Icon(Icons.video_file_outlined),
                        ),
                        title: Text(
                          file.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: file.sizeBytes == null
                            ? null
                            : Text(
                                l10n.tournamentManagementRecordingFileSize(
                                  file.sizeBytes!,
                                ),
                              ),
                      );
                    },
                  ),
                if (_selectedDay != null &&
                    _files.isNotEmpty &&
                    !_loadingFiles &&
                    !_filesError) ...[
                  const SizedBox(height: AppTheme.spacingSM),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.icon(
                      onPressed: () => showMatchRecordingPlayerSheet(
                        context,
                        matchId: widget.matchId,
                        period: _selectedDay!,
                      ),
                      icon: const Icon(Icons.play_circle_outline),
                      label: Text(l10n.recordingPlayDay),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

int? _terminalReadStatusCode(Object error) {
  if (error is! DioException) return null;
  final statusCode = error.response?.statusCode;
  return _isTerminalReadFailure(statusCode) ? statusCode : null;
}

bool _isTerminalReadFailure(int? statusCode) =>
    statusCode == 401 ||
    statusCode == 403 ||
    statusCode == 404 ||
    statusCode == 409;

String _recordingErrorMessage(AppLocalizations l10n, int? statusCode) =>
    switch (statusCode) {
      401 => l10n.authSessionExpired,
      403 => l10n.tournamentManagementRecordingAccessDenied,
      404 => l10n.tournamentManagementRecordingUnavailable,
      _ => l10n.tournamentManagementRecordingLoadError,
    };

class _LoadingMessage extends StatelessWidget {
  const _LoadingMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingLG),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppTheme.spacingSM),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.message, this.retryLabel, this.onRetry});

  final String message;
  final String? retryLabel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        message,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
      if (onRetry != null && retryLabel != null)
        TextButton(onPressed: onRetry, child: Text(retryLabel!)),
    ],
  );
}

class _InfoMessage extends StatelessWidget {
  const _InfoMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMD),
    child: Text(message, textAlign: TextAlign.center),
  );
}
