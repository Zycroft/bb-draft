import '../models/encyclopedia.dart';
import 'api_service.dart';

class EncyclopediaService {
  final ApiService _api = ApiService();

  // ============================================
  // Encyclopedia Summary / Dashboard
  // ============================================

  Future<EncyclopediaSummary> getSummary(String leagueId) async {
    final response = await _api.get('/encyclopedia/$leagueId/summary');
    return EncyclopediaSummary.fromJson(response);
  }

  // ============================================
  // Season Import Management
  // ============================================

  Future<List<ImportedSeason>> getSeasons(String leagueId) async {
    final response = await _api.get('/encyclopedia/$leagueId/seasons');
    return (response['seasons'] as List? ?? [])
        .map((s) => ImportedSeason.fromJson(s))
        .toList();
  }

  Future<ImportedSeason> importSeason({
    required String leagueId,
    required int year,
    String dataSource = 'manual',
    List<Map<String, dynamic>>? playerStats,
    List<Map<String, dynamic>>? teamStats,
  }) async {
    final response = await _api.post('/encyclopedia/$leagueId/seasons', {
      'year': year,
      'dataSource': dataSource,
      if (playerStats != null) 'playerStats': playerStats,
      if (teamStats != null) 'teamStats': teamStats,
    });
    return ImportedSeason.fromJson(response);
  }

  Future<void> deleteSeason(String leagueId, String seasonId) async {
    await _api.delete('/encyclopedia/$leagueId/seasons/$seasonId');
  }

  // ============================================
  // Player Leaderboards
  // ============================================

  Future<LeaderboardResult> getLeaderboard(
    String leagueId,
    String statCode, {
    String type = 'seasonal',
    int? season,
    int limit = 10,
    int offset = 0,
    String? search,
  }) async {
    String endpoint = '/encyclopedia/$leagueId/leaderboards/$statCode';
    endpoint += '?type=$type&limit=$limit&offset=$offset';
    if (season != null) endpoint += '&season=$season';
    if (search != null) endpoint += '&search=$search';

    final response = await _api.get(endpoint);
    return LeaderboardResult(
      leaderboard: Leaderboard.fromJson(response['leaderboard']),
      searchedPlayer: response['searchedPlayer'] != null
          ? LeaderboardEntry.fromJson(response['searchedPlayer'])
          : null,
      statInfo: response['statInfo'] != null
          ? StatCategory.fromJson(response['statInfo'])
          : null,
    );
  }

  Future<LeaderboardCategories> getLeaderboardCategories(
      String leagueId) async {
    final response = await _api.get('/encyclopedia/$leagueId/leaderboards');
    return LeaderboardCategories.fromJson(response);
  }

  // ============================================
  // Player Career Statistics
  // ============================================

  Future<PlayerCareerStats> getPlayerCareerStats(
      String leagueId, String playerId) async {
    final response =
        await _api.get('/encyclopedia/$leagueId/players/$playerId/career');
    return PlayerCareerStats.fromJson(response);
  }

  Future<List<PlayerSeasonStats>> getPlayerSeasons(
      String leagueId, String playerId) async {
    final response =
        await _api.get('/encyclopedia/$leagueId/players/$playerId/seasons');
    return (response['seasons'] as List? ?? [])
        .map((s) => PlayerSeasonStats.fromJson(s))
        .toList();
  }

  // ============================================
  // MLB vs League Comparison
  // ============================================

  Future<PlayerComparison> getPlayerComparison(
    String leagueId,
    String playerId, {
    int? season,
    String type = 'single_season',
  }) async {
    String endpoint = '/encyclopedia/$leagueId/compare/$playerId?type=$type';
    if (season != null) endpoint += '&season=$season';

    final response = await _api.get(endpoint);
    return PlayerComparison.fromJson(response);
  }

  // ============================================
  // Team Historical Statistics
  // ============================================

  Future<List<TeamHistoricalStats>> getAllTeamStats(String leagueId) async {
    final response = await _api.get('/encyclopedia/$leagueId/teams');
    return (response['teams'] as List? ?? [])
        .map((t) => TeamHistoricalStats.fromJson(t))
        .toList();
  }

  Future<TeamHistoricalStats> getTeamStats(
      String leagueId, String teamId) async {
    final response = await _api.get('/encyclopedia/$leagueId/teams/$teamId');
    return TeamHistoricalStats.fromJson(response);
  }

  Future<TeamLeaderboardResult> getTeamLeaderboard(
    String leagueId,
    String category, {
    int limit = 10,
  }) async {
    final response = await _api.get(
        '/encyclopedia/$leagueId/teams/leaderboard/$category?limit=$limit');
    return TeamLeaderboardResult(
      leaderboardId: response['leaderboardId'] ?? '',
      leagueId: response['leagueId'] ?? '',
      category: response['category'] ?? category,
      statCode: response['statCode'] ?? category,
      entries: (response['entries'] as List? ?? [])
          .map((e) => TeamLeaderboardEntry.fromJson(e))
          .toList(),
      generatedAt: response['generatedAt'] ?? '',
    );
  }

  // ============================================
  // Search
  // ============================================

  Future<SearchResults> search(
    String leagueId,
    String query, {
    String type = 'all',
  }) async {
    final response =
        await _api.get('/encyclopedia/$leagueId/search?q=$query&type=$type');
    return SearchResults(
      players: (response['players'] as List? ?? [])
          .map((p) => PlayerSeasonStats.fromJson(p))
          .toList(),
      teams: (response['teams'] as List? ?? [])
          .map((t) => TeamHistoricalStats.fromJson(t))
          .toList(),
    );
  }

  void dispose() {
    _api.dispose();
  }
}

// Result classes

class LeaderboardResult {
  final Leaderboard leaderboard;
  final LeaderboardEntry? searchedPlayer;
  final StatCategory? statInfo;

  LeaderboardResult({
    required this.leaderboard,
    this.searchedPlayer,
    this.statInfo,
  });
}


class TeamLeaderboardResult {
  final String leaderboardId;
  final String leagueId;
  final String category;
  final String statCode;
  final List<TeamLeaderboardEntry> entries;
  final String generatedAt;

  TeamLeaderboardResult({
    required this.leaderboardId,
    required this.leagueId,
    required this.category,
    required this.statCode,
    required this.entries,
    required this.generatedAt,
  });
}

class SearchResults {
  final List<PlayerSeasonStats> players;
  final List<TeamHistoricalStats> teams;

  SearchResults({
    required this.players,
    required this.teams,
  });
}
