import '../models/player.dart';
import 'api_service.dart';

class PlayerService {
  final ApiService _api = ApiService();

  Future<List<Player>> getPlayers({String? position, String? search, int limit = 50}) async {
    String endpoint = '/players?limit=$limit';
    if (position != null) endpoint += '&position=$position';
    if (search != null) endpoint += '&search=$search';

    final response = await _api.get(endpoint);
    final items = response['items'] as List? ?? [];
    return items.map((json) => Player.fromJson(json)).toList();
  }

  Future<List<Player>> getBatters({int limit = 100}) async {
    final response = await _api.get('/players/batters?limit=$limit');
    final items = response['items'] as List? ?? [];
    return items.map((json) => Player.fromJson(json)).toList();
  }

  Future<List<Player>> getPitchers({int limit = 100}) async {
    final response = await _api.get('/players/pitchers?limit=$limit');
    final items = response['items'] as List? ?? [];
    return items.map((json) => Player.fromJson(json)).toList();
  }

  Future<List<Player>> searchPlayers(String query, {int limit = 50}) async {
    final response = await _api.get('/players/search?q=$query&limit=$limit');
    final items = response['items'] as List? ?? [];
    return items.map((json) => Player.fromJson(json)).toList();
  }

  Future<Player> getPlayer(String playerId) async {
    final response = await _api.get('/players/$playerId');
    return Player.fromJson(response);
  }

  Future<Player> getPlayerAdvanced(String playerId) async {
    final response = await _api.get('/players/$playerId/advanced');
    return Player.fromJson(response);
  }

  Future<void> syncPlayers() async {
    await _api.post('/players/sync', {});
  }

  // Eligibility Management
  Future<EligibilityStatus> getPlayerEligibility(String playerId, String leagueId) async {
    final response = await _api.get('/players/$playerId/eligibility/$leagueId');
    return EligibilityStatus.fromJson(response);
  }

  Future<EligibilityStatus> setPlayerEligibility(
    String playerId,
    String leagueId, {
    required DraftEligibility eligibility,
    String? note,
    String? ownerTeamId,
  }) async {
    final response = await _api.put('/players/$playerId/eligibility/$leagueId', {
      'eligibility': eligibility.value,
      if (note != null) 'note': note,
      if (ownerTeamId != null) 'ownerTeamId': ownerTeamId,
    });
    return EligibilityStatus.fromJson(response);
  }

  Future<Map<String, EligibilityStatus>> getLeagueEligibilities(String leagueId) async {
    final response = await _api.get('/players/eligibility/$leagueId');
    final Map<String, EligibilityStatus> result = {};
    if (response is Map) {
      response.forEach((key, value) {
        result[key] = EligibilityStatus.fromJson(value);
      });
    }
    return result;
  }

  Future<void> bulkSetEligibility(
    String leagueId,
    List<BulkEligibilityUpdate> updates,
  ) async {
    await _api.put('/players/eligibility/$leagueId/bulk', {
      'players': updates.map((u) => u.toJson()).toList(),
    });
  }

  void dispose() {
    _api.dispose();
  }
}

// Eligibility status model
class EligibilityStatus {
  final String playerId;
  final String leagueId;
  final DraftEligibility eligibility;
  final String? note;
  final String? ownerTeamId;
  final String? updatedAt;

  EligibilityStatus({
    required this.playerId,
    required this.leagueId,
    required this.eligibility,
    this.note,
    this.ownerTeamId,
    this.updatedAt,
  });

  factory EligibilityStatus.fromJson(Map<String, dynamic> json) => EligibilityStatus(
    playerId: json['playerId'] ?? '',
    leagueId: json['leagueId'] ?? '',
    eligibility: DraftEligibility.fromString(json['eligibility']),
    note: json['note'],
    ownerTeamId: json['ownerTeamId'],
    updatedAt: json['updatedAt'],
  );
}

class BulkEligibilityUpdate {
  final String playerId;
  final DraftEligibility eligibility;
  final String? note;
  final String? ownerTeamId;

  BulkEligibilityUpdate({
    required this.playerId,
    required this.eligibility,
    this.note,
    this.ownerTeamId,
  });

  Map<String, dynamic> toJson() => {
    'playerId': playerId,
    'eligibility': eligibility.value,
    if (note != null) 'note': note,
    if (ownerTeamId != null) 'ownerTeamId': ownerTeamId,
  };
}
