import 'package:app_quanly_giaidau/data/models/tournament_model.dart';

abstract class ITournamentRepository {
  Future<Tournament> create(Tournament tournament);
  Future<Tournament?> getById(String id);
  Stream<Tournament?> watch(String id);
  Stream<List<Tournament>> watchAll();
  Future<void> update(String id, Map<String, dynamic> data);
  Future<void> updateStatus(String id, String status);
  Future<void> updateToken(String id, String role, String newToken);
  Future<void> delete(String id);
}
