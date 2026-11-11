import 'package:app_quanly_giaidau/core/di/repository_providers.dart';
import 'package:app_quanly_giaidau/domain/entities/user.dart';
import 'package:app_quanly_giaidau/domain/repositories/tournament_management_repository.dart';
import 'package:app_quanly_giaidau/providers/auth_provider.dart';
import 'package:app_quanly_giaidau/providers/tournament_co_organizer_provider.dart';
import 'package:app_quanly_giaidau/providers/user_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _StaffRepo implements TournamentManagementRepository {
  _StaffRepo(this.staff, {this.fail = false});

  final List<Map<String, dynamic>> staff;
  final bool fail;
  int calls = 0;

  @override
  Future<List<Map<String, dynamic>>> getStaff(String id) async {
    calls++;
    if (fail) throw Exception('network down');
    return staff;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestAuth extends AuthNotifier {
  _TestAuth(this.role);

  final UserRole role;

  @override
  AuthState build() =>
      AuthState(status: AuthStatus.authenticated, role: role);
}

ProviderContainer _container(
  _StaffRepo repo, {
  UserRole role = UserRole.admin,
}) {
  final container = ProviderContainer(
    overrides: [
      authProvider.overrideWith(() => _TestAuth(role)),
      userProfileProvider.overrideWith(
        (ref) async => const UserProfile(id: 'me', fullName: 'Me'),
      ),
      tournamentManagementRepositoryProvider.overrideWithValue(repo),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<bool> _ask(ProviderContainer container) async {
  await container.read(userProfileProvider.future);
  return container.read(tournamentCoOrganizerProvider('t1').future);
}

void main() {
  test('TC-COORG-PROV-01 admin invited as CO_ORGANIZER is staff', () async {
    final repo = _StaffRepo([
      {'userId': 'me', 'role': 'CO_ORGANIZER'},
    ]);
    expect(await _ask(_container(repo)), isTrue);
  });

  test('TC-COORG-PROV-02 a REFEREE row or another user does not count', () async {
    final repo = _StaffRepo([
      {'userId': 'me', 'role': 'REFEREE'},
      {'userId': 'other', 'role': 'CO_ORGANIZER'},
    ]);
    expect(await _ask(_container(repo)), isFalse);
  });

  test('TC-COORG-PROV-03 fails closed when the staff request fails', () async {
    final repo = _StaffRepo(const [], fail: true);
    expect(await _ask(_container(repo)), isFalse);
  });

  test('TC-COORG-PROV-04 non-admin skips the request entirely', () async {
    final repo = _StaffRepo([
      {'userId': 'me', 'role': 'CO_ORGANIZER'},
    ]);
    expect(await _ask(_container(repo, role: UserRole.viewer)), isFalse);
    expect(repo.calls, 0);
  });
}
