import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/data/models/token_model.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';

class TokenManagementNotifier extends AsyncNotifier<List<TokenModel>> {
  static const _log = AppLogger('TokenManagementNotifier');

  final String tournamentId;

  TokenManagementNotifier(this.tournamentId);

  @override
  Future<List<TokenModel>> build() async {
    return _fetchTokens(tournamentId);
  }

  Future<List<TokenModel>> _fetchTokens(String tournamentId) async {
    _log.info('Fetching tokens for tournament: $tournamentId');
    return ref
        .watch(tokenRepositoryProvider)
        .getTokensByTournament(tournamentId);
  }

  Future<bool> regenerateToken(String role) async {
    _log.info('Đang yêu cầu tạo lại token cho role: $role');
    state = const AsyncValue.loading();
    try {
      final newCode = _generateRandomCode(role);
      await ref
          .read(tokenRepositoryProvider)
          .regenerateToken(tournamentId: tournamentId, role: role, newCode: newCode);
      state = AsyncValue.data(await _fetchTokens(tournamentId));
      _log.success('Tạo token mới thành công');
      return true;
    } catch (e, stack) {
      _log.error('Lỗi khi tạo token mới', e, stack);
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  String _generateRandomCode(String role) {
    // Generate a simple code: ROL-XXXX-XXXX
    final prefix = switch (role) {
      'admin' => 'ADM',
      'referee' => 'REF',
      'viewer' => 'VWR',
      _ => 'TKN',
    };
    final p1 = (1000 + DateTime.now().millisecond % 9000).toString();
    final p2 = (1000 + DateTime.now().microsecond % 9000).toString();
    return '$prefix-$p1-$p2';
  }
}

final tokenManagementProvider = AsyncNotifierProvider.family<TokenManagementNotifier, List<TokenModel>, String>(
  TokenManagementNotifier.new,
);
