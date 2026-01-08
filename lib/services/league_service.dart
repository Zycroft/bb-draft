import '../models/league.dart';
import '../models/team.dart';
import 'api_service.dart';

class LeagueService {
  final ApiService _api = ApiService();

  Future<List<League>> getMyLeagues() async {
    final response = await _api.get('/leagues');
    if (response is List) {
      return response.map((json) => League.fromJson(json)).toList();
    }
    return [];
  }

  Future<League> getLeague(String leagueId) async {
    final response = await _api.get('/leagues/$leagueId');
    return League.fromJson(response);
  }

  Future<League> createLeague({
    required String name,
    int maxTeams = 12,
    String draftFormat = 'serpentine',
    int pickTimer = 90,
    int rounds = 23,
  }) async {
    final response = await _api.post('/leagues', {
      'name': name,
      'maxTeams': maxTeams,
      'draftFormat': draftFormat,
      'pickTimer': pickTimer,
      'rounds': rounds,
    });
    return League.fromJson(response);
  }

  Future<League> updateLeague(String leagueId, {String? name, Map<String, dynamic>? settings}) async {
    final response = await _api.put('/leagues/$leagueId', {
      if (name != null) 'name': name,
      if (settings != null) 'settings': settings,
    });
    return League.fromJson(response);
  }

  Future<void> deleteLeague(String leagueId) async {
    await _api.delete('/leagues/$leagueId');
  }

  Future<JoinLeagueResult> joinLeague(String inviteCode, {String? teamName}) async {
    final response = await _api.post('/leagues/join', {
      'inviteCode': inviteCode,
      if (teamName != null) 'teamName': teamName,
    });
    return JoinLeagueResult(
      league: League.fromJson(response['league']),
      team: Team.fromJson(response['team']),
    );
  }

  Future<String> regenerateInviteCode(String leagueId) async {
    final response = await _api.post('/leagues/$leagueId/regenerate-code', {});
    return response['inviteCode'];
  }

  // Draft Order Management
  Future<DraftOrder> getDraftOrder(String leagueId) async {
    final response = await _api.get('/leagues/$leagueId/draft-order');
    return DraftOrder.fromJson(response);
  }

  Future<List<DraftOrderEntry>> setDraftOrder(String leagueId, List<DraftOrderEntry> order) async {
    final response = await _api.put('/leagues/$leagueId/draft-order', {
      'order': order.map((e) => e.toJson()).toList(),
    });
    return (response['order'] as List).map((e) => DraftOrderEntry.fromJson(e)).toList();
  }

  Future<List<DraftOrderEntry>> randomizeDraftOrder(String leagueId) async {
    final response = await _api.post('/leagues/$leagueId/draft-order/randomize', {});
    return (response['order'] as List).map((e) => DraftOrderEntry.fromJson(e)).toList();
  }

  Future<void> swapDraftPositions(String leagueId, String teamId1, String teamId2) async {
    await _api.post('/leagues/$leagueId/draft-order/swap', {
      'teamId1': teamId1,
      'teamId2': teamId2,
    });
  }

  // Team Management (Commissioner)
  Future<List<Team>> getLeagueTeams(String leagueId) async {
    final response = await _api.get('/leagues/$leagueId/teams');
    if (response is List) {
      return response.map((json) => Team.fromJson(json)).toList();
    }
    return [];
  }

  Future<void> removeTeam(String leagueId, String teamId) async {
    await _api.delete('/leagues/$leagueId/teams/$teamId');
  }

  Future<void> transferTeam(String leagueId, String teamId, String newOwnerId) async {
    await _api.post('/leagues/$leagueId/teams/$teamId/transfer', {
      'newOwnerId': newOwnerId,
    });
  }

  // Announcements
  Future<void> sendAnnouncement(String leagueId, String message, {String? title}) async {
    await _api.post('/leagues/$leagueId/announcements', {
      'message': message,
      if (title != null) 'title': title,
    });
  }

  void dispose() {
    _api.dispose();
  }
}

class JoinLeagueResult {
  final League league;
  final Team team;

  JoinLeagueResult({required this.league, required this.team});
}

// Draft Order Models
class DraftOrder {
  final String leagueId;
  final int seasonYear;
  final String orderMethod;
  final bool serpentine;
  final List<DraftOrderEntry> order;
  final String? lockedAt;
  final String lastModified;
  final String modifiedBy;
  final String status;

  DraftOrder({
    required this.leagueId,
    required this.seasonYear,
    required this.orderMethod,
    required this.serpentine,
    required this.order,
    this.lockedAt,
    required this.lastModified,
    required this.modifiedBy,
    required this.status,
  });

  factory DraftOrder.fromJson(Map<String, dynamic> json) => DraftOrder(
    leagueId: json['leagueId'] ?? '',
    seasonYear: json['seasonYear'] ?? DateTime.now().year,
    orderMethod: json['orderMethod'] ?? 'manual',
    serpentine: json['serpentine'] ?? true,
    order: (json['order'] as List? ?? [])
        .map((e) => DraftOrderEntry.fromJson(e))
        .toList(),
    lockedAt: json['lockedAt'],
    lastModified: json['lastModified'] ?? '',
    modifiedBy: json['modifiedBy'] ?? '',
    status: json['status'] ?? 'unlocked',
  );

  bool get isLocked => status == 'locked';
}

class DraftOrderEntry {
  final int position;
  final String teamId;
  final String teamName;

  DraftOrderEntry({
    required this.position,
    required this.teamId,
    required this.teamName,
  });

  factory DraftOrderEntry.fromJson(Map<String, dynamic> json) => DraftOrderEntry(
    position: json['position'] ?? 0,
    teamId: json['teamId'] ?? '',
    teamName: json['teamName'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'position': position,
    'teamId': teamId,
    'teamName': teamName,
  };
}
