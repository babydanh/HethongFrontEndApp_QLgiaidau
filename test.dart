import 'package:flutter_riverpod/flutter_riverpod.dart';

class TokenManagementNotifier extends AsyncNotifier<List<int>> {
  final String tournamentId;
  
  TokenManagementNotifier(this.tournamentId);

  @override
  Future<List<int>> build() async {
    return [1, 2, 3];
  }
}

final tokenManagementProvider = AsyncNotifierProvider.family<TokenManagementNotifier, List<int>, String>(
  TokenManagementNotifier.new,
);

void main() {}
