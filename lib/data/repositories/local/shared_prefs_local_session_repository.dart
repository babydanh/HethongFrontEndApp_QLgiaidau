import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_quanly_giaidau/core/services/app_logger.dart';
import 'package:app_quanly_giaidau/data/models/saved_tournament_model.dart';
import 'package:app_quanly_giaidau/domain/repositories/local_session_repository.dart';

class SharedPrefsLocalSessionRepository implements ILocalSessionRepository {
  static const _key = 'my_saved_tournaments';
  static const _log = AppLogger('SharedPrefsLocalSessionRepo');

  @override
  Future<List<SavedTournament>> getSavedTournaments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_key);
      if (jsonString == null) return [];

      final List<dynamic> list = jsonDecode(jsonString);
      return list
          .map((e) => SavedTournament.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      _log.error('Lỗi khi get saved tournaments', e, stack);
      return [];
    }
  }

  @override
  Future<void> saveTournament(SavedTournament tournament) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentList = await getSavedTournaments();
      
      currentList.removeWhere((t) => t.id == tournament.id);
      currentList.insert(0, tournament);
      
      await prefs.setString(
          _key, jsonEncode(currentList.map((e) => e.toJson()).toList()));
    } catch (e, stack) {
      _log.error('Lỗi khi save tournament', e, stack);
      rethrow;
    }
  }

  @override
  Future<void> removeTournament(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentList = await getSavedTournaments();
      
      currentList.removeWhere((t) => t.id == id);
      
      await prefs.setString(
          _key, jsonEncode(currentList.map((e) => e.toJson()).toList()));
    } catch (e, stack) {
      _log.error('Lỗi khi remove tournament', e, stack);
      rethrow;
    }
  }
}
