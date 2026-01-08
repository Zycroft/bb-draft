import '../models/team.dart';
import 'api_service.dart';

class TeamService {
  final ApiService _api = ApiService();

  Future<List<Team>> getMyTeams() async {
    final response = await _api.get('/users/me/teams');
    if (response is List) {
      return response.map((json) => Team.fromJson(json)).toList();
    }
    return [];
  }

  Future<Team> getTeam(String teamId) async {
    final response = await _api.get('/teams/$teamId');
    return Team.fromJson(response);
  }

  Future<Team> createTeam({
    required String leagueId,
    required String name,
    String? abbreviation,
  }) async {
    final response = await _api.post('/teams', {
      'leagueId': leagueId,
      'name': name,
      if (abbreviation != null) 'abbreviation': abbreviation,
    });
    return Team.fromJson(response);
  }

  Future<Team> updateTeam(String teamId, {String? name, String? abbreviation}) async {
    final response = await _api.put('/teams/$teamId', {
      if (name != null) 'name': name,
      if (abbreviation != null) 'abbreviation': abbreviation,
    });
    return Team.fromJson(response);
  }

  Future<List<RosterPlayer>> getRoster(String teamId) async {
    final response = await _api.get('/teams/$teamId/roster');
    if (response is List) {
      return response.map((json) => RosterPlayer.fromJson(json)).toList();
    }
    return [];
  }

  Future<List<String>> updateDraftQueue(String teamId, List<String> queue) async {
    final response = await _api.put('/teams/$teamId/queue', {'queue': queue});
    return List<String>.from(response['queue'] ?? []);
  }

  Future<void> deleteTeam(String teamId) async {
    await _api.delete('/teams/$teamId');
  }

  void dispose() {
    _api.dispose();
  }
}
