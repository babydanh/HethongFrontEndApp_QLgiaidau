import 'package:app_quanly_giaidau/data/models/saved_tournament_model.dart';

abstract class ILocalSessionRepository {
  Future<List<SavedTournament>> getSavedTournaments();
  Future<void> saveTournament(SavedTournament tournament);
  Future<void> removeTournament(String id);
}
