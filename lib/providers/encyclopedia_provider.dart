import 'package:flutter/foundation.dart';
import '../models/encyclopedia.dart';
import '../services/encyclopedia_service.dart';

class EncyclopediaProvider extends ChangeNotifier {
  final EncyclopediaService _service = EncyclopediaService();

  // State
  EncyclopediaSummary? _summary;
  List<ImportedSeason> _seasons = [];
  Leaderboard? _currentLeaderboard;
  LeaderboardCategories? _leaderboardCategories;
  PlayerCareerStats? _playerCareerStats;
  List<PlayerSeasonStats> _playerSeasons = [];
  PlayerComparison? _playerComparison;
  List<TeamHistoricalStats> _teamStats = [];
  TeamHistoricalStats? _selectedTeam;
  SearchResults? _searchResults;

  bool _isLoading = false;
  String? _error;

  // Getters
  EncyclopediaSummary? get summary => _summary;
  List<ImportedSeason> get seasons => _seasons;
  Leaderboard? get currentLeaderboard => _currentLeaderboard;
  LeaderboardCategories? get leaderboardCategories => _leaderboardCategories;
  PlayerCareerStats? get playerCareerStats => _playerCareerStats;
  List<PlayerSeasonStats> get playerSeasons => _playerSeasons;
  PlayerComparison? get playerComparison => _playerComparison;
  List<TeamHistoricalStats> get teamStats => _teamStats;
  TeamHistoricalStats? get selectedTeam => _selectedTeam;
  SearchResults? get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ============================================
  // Encyclopedia Summary / Dashboard
  // ============================================

  Future<void> loadSummary(String leagueId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _summary = await _service.getSummary(leagueId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load encyclopedia summary: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================
  // Season Import Management
  // ============================================

  Future<void> loadSeasons(String leagueId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _seasons = await _service.getSeasons(leagueId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load seasons: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ImportedSeason?> importSeason({
    required String leagueId,
    required int year,
    String dataSource = 'manual',
    List<Map<String, dynamic>>? playerStats,
    List<Map<String, dynamic>>? teamStats,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final season = await _service.importSeason(
        leagueId: leagueId,
        year: year,
        dataSource: dataSource,
        playerStats: playerStats,
        teamStats: teamStats,
      );
      _seasons.add(season);
      _isLoading = false;
      notifyListeners();
      return season;
    } catch (e) {
      _error = 'Failed to import season: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> deleteSeason(String leagueId, String seasonId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.deleteSeason(leagueId, seasonId);
      _seasons.removeWhere((s) => s.seasonId == seasonId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete season: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ============================================
  // Player Leaderboards
  // ============================================

  Future<void> loadLeaderboard(
    String leagueId,
    String statCode, {
    String type = 'seasonal',
    int? season,
    int limit = 10,
    int offset = 0,
    String? search,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _service.getLeaderboard(
        leagueId,
        statCode,
        type: type,
        season: season,
        limit: limit,
        offset: offset,
        search: search,
      );
      _currentLeaderboard = result.leaderboard;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load leaderboard: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadLeaderboardCategories(String leagueId) async {
    try {
      _leaderboardCategories =
          await _service.getLeaderboardCategories(leagueId);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load leaderboard categories: $e';
      notifyListeners();
    }
  }

  // ============================================
  // Player Career Statistics
  // ============================================

  Future<void> loadPlayerCareerStats(String leagueId, String playerId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _playerCareerStats =
          await _service.getPlayerCareerStats(leagueId, playerId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load player career stats: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPlayerSeasons(String leagueId, String playerId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _playerSeasons = await _service.getPlayerSeasons(leagueId, playerId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load player seasons: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================
  // MLB vs League Comparison
  // ============================================

  Future<void> loadPlayerComparison(
    String leagueId,
    String playerId, {
    int? season,
    String type = 'single_season',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _playerComparison = await _service.getPlayerComparison(
        leagueId,
        playerId,
        season: season,
        type: type,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load player comparison: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================
  // Team Historical Statistics
  // ============================================

  Future<void> loadAllTeamStats(String leagueId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _teamStats = await _service.getAllTeamStats(leagueId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load team stats: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTeamStats(String leagueId, String teamId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedTeam = await _service.getTeamStats(leagueId, teamId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load team stats: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================
  // Search
  // ============================================

  Future<void> search(
    String leagueId,
    String query, {
    String type = 'all',
  }) async {
    if (query.length < 2) {
      _searchResults = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _searchResults = await _service.search(leagueId, query, type: type);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to search: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _searchResults = null;
    notifyListeners();
  }

  // ============================================
  // Utility
  // ============================================

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearPlayerData() {
    _playerCareerStats = null;
    _playerSeasons = [];
    _playerComparison = null;
    notifyListeners();
  }

  void clearTeamData() {
    _selectedTeam = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
