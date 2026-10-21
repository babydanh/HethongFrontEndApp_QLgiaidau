import 'dart:async';

import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/swiss.dart';
import 'package:app_quanly_giaidau/features/bracket/utils/swiss_pairing_draft.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _validateDebounce = Duration(milliseconds: 250);

/// [errorKey] value for a request that got no response (offline, timeout).
const swissErrorNetwork = 'NETWORK';

/// [errorKey] value for any failure that is not a [SwissApiException].
const swissErrorUnknown = 'UNKNOWN';

class SwissPairingArgs {
  const SwissPairingArgs({
    required this.tournamentId,
    required this.divisionId,
    this.stageId,
  });

  final String tournamentId;
  final String divisionId;
  final String? stageId;

  @override
  bool operator ==(Object other) =>
      other is SwissPairingArgs &&
      other.tournamentId == tournamentId &&
      other.divisionId == divisionId &&
      other.stageId == stageId;

  @override
  int get hashCode => Object.hash(tournamentId, divisionId, stageId);
}

class SwissPairingState {
  const SwissPairingState({
    this.loading = false,
    this.errorKey,
    this.preview,
    this.draft,
    this.warnings = const [],
    this.errors = const [],
    this.valid = false,
    this.submitting = false,
    this.canUndo = false,
  });

  final bool loading;

  /// API error code (e.g. `SWISS_ROUND_EXISTS`), [swissErrorNetwork] or
  /// [swissErrorUnknown]; the screen maps it to a localized message.
  final String? errorKey;
  final SwissPreview? preview;
  final SwissDraft? draft;
  final List<SwissWarning> warnings;
  final List<SwissError> errors;

  /// True only once `validate` approved the current draft.
  final bool valid;
  final bool submitting;
  final bool canUndo;

  bool get canConfirm {
    final current = draft;
    return !loading &&
        !submitting &&
        preview != null &&
        current != null &&
        isDraftComplete(current) &&
        valid &&
        errors.isEmpty;
  }

  SwissPairingState copyWith({
    bool? loading,
    String? errorKey,
    bool clearError = false,
    SwissPreview? preview,
    SwissDraft? draft,
    List<SwissWarning>? warnings,
    List<SwissError>? errors,
    bool? valid,
    bool? submitting,
    bool? canUndo,
  }) => SwissPairingState(
    loading: loading ?? this.loading,
    errorKey: clearError ? null : errorKey ?? this.errorKey,
    preview: preview ?? this.preview,
    draft: draft ?? this.draft,
    warnings: warnings ?? this.warnings,
    errors: errors ?? this.errors,
    valid: valid ?? this.valid,
    submitting: submitting ?? this.submitting,
    canUndo: canUndo ?? this.canUndo,
  );
}

final swissPairingProvider = NotifierProvider.autoDispose
    .family<SwissPairingNotifier, SwissPairingState, SwissPairingArgs>(
      SwissPairingNotifier.new,
    );

class SwissPairingNotifier extends Notifier<SwissPairingState> {
  SwissPairingNotifier(this.args);

  final SwissPairingArgs args;
  SwissDraftHistory? _history;
  Timer? _debounce;

  /// Bumped on every draft change, reload and submit; a validate reply is only
  /// applied when it still carries the latest value.
  int _generation = 0;

  @override
  SwissPairingState build() {
    ref.onDispose(() => _debounce?.cancel());
    Future<void>.microtask(reload);
    return const SwissPairingState(loading: true);
  }

  /// Fetches the machine proposal and replaces the draft with it. A failure
  /// keeps whatever draft is already on screen.
  Future<void> reload({String? keepErrorKey}) async {
    final generation = _bump();
    state = state.copyWith(loading: true, clearError: true);
    try {
      final preview = await ref
          .read(tournamentRepositoryProvider)
          .swissPreview(
            args.tournamentId,
            divisionId: args.divisionId,
            stageId: args.stageId,
          );
      if (!ref.mounted || generation != _generation) return;
      final draft = draftFromPreview(preview);
      _history = SwissDraftHistory(draft);
      state = SwissPairingState(
        preview: preview,
        draft: draft,
        warnings: preview.warnings,
        valid: true,
        errorKey: keepErrorKey,
      );
    } catch (error) {
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(loading: false, errorKey: _keyOf(error));
    }
  }

  Future<void> autoPair() => reload();

  void move(String participantId, SwissSlotRef to) {
    final history = _history;
    final current = state.draft;
    if (history == null || current == null || state.submitting) return;
    final next = moveParticipant(current, participantId, to);
    if (identical(next, current)) return;
    history.push(next);
    _draftChanged(next);
  }

  void undo() {
    final history = _history;
    if (history == null || !history.canUndo || state.submitting) return;
    _draftChanged(history.undo());
  }

  /// Returns true when the round was created. Refuses (false) while a request
  /// is in flight, when the draft is not confirmable, or when warnings remain
  /// and [confirmWarnings] is not set.
  Future<bool> confirm({bool confirmWarnings = false}) async {
    final current = state.draft;
    if (!state.canConfirm || current == null) return false;
    if (state.warnings.isNotEmpty && !confirmWarnings) return false;

    _debounce?.cancel();
    _bump();
    state = state.copyWith(submitting: true, clearError: true);
    try {
      await ref
          .read(tournamentRepositoryProvider)
          .swissNextRound(
            args.tournamentId,
            draftToRequest(
              current,
              divisionId: args.divisionId,
              stageId: args.stageId,
            ),
            confirmWarnings: confirmWarnings,
          );
      if (!ref.mounted) return true;
      state = state.copyWith(submitting: false);
      return true;
    } on SwissApiException catch (error) {
      if (!ref.mounted) return false;
      await _onConfirmFailed(error);
      return false;
    } catch (_) {
      if (ref.mounted) {
        state = state.copyWith(submitting: false, errorKey: swissErrorUnknown);
      }
      return false;
    }
  }

  Future<void> _onConfirmFailed(SwissApiException error) async {
    final key = _keyOf(error);
    if (error.code == 'SWISS_ROUND_EXISTS') {
      // Someone else created the round: drop the stale draft, show the new one.
      state = state.copyWith(submitting: false);
      await reload(keepErrorKey: key);
      return;
    }
    state = state.copyWith(
      submitting: false,
      errorKey: key,
      warnings: error.code == 'SWISS_WARNINGS_UNCONFIRMED'
          ? error.warnings
          : null,
      valid: error.code == 'SWISS_INVALID_PAIRING' ? false : null,
    );
  }

  void _draftChanged(SwissDraft draft) {
    final generation = _bump();
    _debounce?.cancel();
    state = state.copyWith(
      draft: draft,
      canUndo: _history?.canUndo ?? false,
      valid: false,
      errors: const [],
      clearError: true,
    );
    _debounce = Timer(_validateDebounce, () => _validate(draft, generation));
  }

  Future<void> _validate(SwissDraft draft, int generation) async {
    try {
      final result = await ref
          .read(tournamentRepositoryProvider)
          .swissValidate(
            args.tournamentId,
            draftToRequest(
              draft,
              divisionId: args.divisionId,
              stageId: args.stageId,
            ),
          );
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(
        valid: result.valid,
        errors: result.errors,
        warnings: result.warnings,
      );
    } catch (error) {
      if (!ref.mounted || generation != _generation) return;
      // Could not verify: stay unconfirmable; the next edit retries.
      state = state.copyWith(valid: false, errorKey: _keyOf(error));
    }
  }

  int _bump() => ++_generation;

  String _keyOf(Object error) {
    if (error is! SwissApiException) return swissErrorUnknown;
    return error.code ??
        (error.status == null ? swissErrorNetwork : swissErrorUnknown);
  }
}
