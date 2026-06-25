import 'package:app_quanly_giaidau/domain/entities/saved_tournament.dart';

abstract class ILocalSessionRepository {
  Future<List<SavedTournament>> getSavedTournaments();
  Future<void> saveTournament(SavedTournament tournament);
  Future<void> removeTournament(String id);
}
