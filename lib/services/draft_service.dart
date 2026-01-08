import '../models/draft.dart';
import '../models/player.dart';
import 'api_service.dart';

class DraftService {
  final ApiService _api = ApiService();

  Future<Draft> getDraft(String draftId) async {
    final response = await _api.get('/drafts/$draftId');
    return Draft.fromJson(response);
  }

  Future<Draft> createDraft({
    required String leagueId,
    String? scheduledStart,
    DraftMode mode = DraftMode.live,
    DraftConfiguration? configuration,
  }) async {
    final response = await _api.post('/drafts', {
      'leagueId': leagueId,
      'mode': mode.value,
      if (scheduledStart != null) 'scheduledStart': scheduledStart,
      if (configuration != null) 'configuration': configuration.toJson(),
    });
    return Draft.fromJson(response);
  }

  Future<Draft> startDraft(String draftId) async {
    final response = await _api.post('/drafts/$draftId/start', {});
    return Draft.fromJson(response);
  }

  Future<MakePickResult> makePick({
    required String draftId,
    required String teamId,
    required String playerId,
  }) async {
    final response = await _api.post('/drafts/$draftId/pick', {
      'teamId': teamId,
      'playerId': playerId,
    });
    return MakePickResult(
      pick: DraftPick.fromJson(response['pick']),
      draft: Draft.fromJson(response['draft']),
      completed: response['completed'] ?? false,
    );
  }

  Future<Draft> pauseDraft(String draftId) async {
    final response = await _api.post('/drafts/$draftId/pause', {});
    return Draft.fromJson(response);
  }

  Future<Draft> resumeDraft(String draftId) async {
    final response = await _api.post('/drafts/$draftId/resume', {});
    return Draft.fromJson(response);
  }

  Future<List<DraftPick>> getDraftPicks(String draftId) async {
    final response = await _api.get('/drafts/$draftId/picks');
    if (response is List) {
      return response.map((json) => DraftPick.fromJson(json)).toList();
    }
    return [];
  }

  Future<List<String>> runLottery(String draftId, {String type = 'random'}) async {
    final response = await _api.post('/drafts/$draftId/lottery', {'type': type});
    return List<String>.from(response['draftOrder'] ?? []);
  }

  // Get skip queue
  Future<SkipQueueResult> getSkipQueue(String draftId) async {
    final response = await _api.get('/drafts/$draftId/skips');
    return SkipQueueResult(
      skips: (response['skips'] as List? ?? [])
          .map((s) => SkippedPick.fromJson(s))
          .toList(),
      catchUpAvailable: (response['catchUpAvailable'] as List? ?? [])
          .map((s) => SkippedPick.fromJson(s))
          .toList(),
    );
  }

  // Make a catch-up pick
  Future<MakePickResult> makeCatchUpPick({
    required String draftId,
    required String teamId,
    required String playerId,
    required String skipId,
  }) async {
    final response = await _api.post('/drafts/$draftId/catchup', {
      'teamId': teamId,
      'playerId': playerId,
      'skipId': skipId,
    });
    return MakePickResult(
      pick: DraftPick.fromJson(response['pick']),
      draft: Draft.fromJson(response['draft']),
      completed: false,
    );
  }

  // Update draft configuration
  Future<Draft> updateConfiguration(
    String draftId,
    DraftConfiguration configuration,
  ) async {
    final response = await _api.put('/drafts/$draftId/configuration', {
      'configuration': configuration.toJson(),
    });
    return Draft.fromJson(response);
  }

  // Get draft grid
  Future<DraftGridData> getDraftGrid(String draftId) async {
    final response = await _api.get('/drafts/$draftId/grid');
    return DraftGridData.fromJson(response);
  }

  // Get available players
  Future<AvailablePlayersResult> getAvailablePlayers(
    String draftId, {
    String? position,
    int limit = 100,
  }) async {
    String endpoint = '/drafts/$draftId/available?limit=$limit';
    if (position != null) endpoint += '&position=$position';

    final response = await _api.get(endpoint);
    return AvailablePlayersResult(
      players: (response['items'] as List? ?? [])
          .map((p) => Player.fromJson(p))
          .toList(),
      count: response['count'] ?? 0,
      draftedCount: response['draftedCount'] ?? 0,
    );
  }

  void dispose() {
    _api.dispose();
  }
}

class MakePickResult {
  final DraftPick pick;
  final Draft draft;
  final bool completed;

  MakePickResult({
    required this.pick,
    required this.draft,
    required this.completed,
  });
}

class SkipQueueResult {
  final List<SkippedPick> skips;
  final List<SkippedPick> catchUpAvailable;

  SkipQueueResult({
    required this.skips,
    required this.catchUpAvailable,
  });
}

class AvailablePlayersResult {
  final List<Player> players;
  final int count;
  final int draftedCount;

  AvailablePlayersResult({
    required this.players,
    required this.count,
    required this.draftedCount,
  });
}

class DraftGridData {
  final String gridId;
  final String leagueId;
  final int seasonYear;
  final String draftFormat;
  final int totalRounds;
  final int teamCount;
  final int currentRound;
  final int currentPick;
  final int currentOverallPick;
  final DraftStatus draftStatus;
  final OnTheClock? onTheClock;
  final List<GridTeam> teams;
  final List<GridRound> rounds;
  final List<SkippedPick> skipQueue;
  final String lastUpdated;

  DraftGridData({
    required this.gridId,
    required this.leagueId,
    required this.seasonYear,
    required this.draftFormat,
    required this.totalRounds,
    required this.teamCount,
    required this.currentRound,
    required this.currentPick,
    required this.currentOverallPick,
    required this.draftStatus,
    this.onTheClock,
    required this.teams,
    required this.rounds,
    required this.skipQueue,
    required this.lastUpdated,
  });

  factory DraftGridData.fromJson(Map<String, dynamic> json) {
    return DraftGridData(
      gridId: json['gridId'] ?? '',
      leagueId: json['leagueId'] ?? '',
      seasonYear: json['seasonYear'] ?? 2026,
      draftFormat: json['draftFormat'] ?? 'serpentine',
      totalRounds: json['totalRounds'] ?? 23,
      teamCount: json['teamCount'] ?? 0,
      currentRound: json['currentRound'] ?? 1,
      currentPick: json['currentPick'] ?? 1,
      currentOverallPick: json['currentOverallPick'] ?? 1,
      draftStatus: DraftStatus.fromString(json['draftStatus']),
      onTheClock: json['onTheClock'] != null
          ? OnTheClock.fromJson(json['onTheClock'])
          : null,
      teams: (json['teams'] as List? ?? [])
          .map((t) => GridTeam.fromJson(t))
          .toList(),
      rounds: (json['rounds'] as List? ?? [])
          .map((r) => GridRound.fromJson(r))
          .toList(),
      skipQueue: (json['skipQueue'] as List? ?? [])
          .map((s) => SkippedPick.fromJson(s))
          .toList(),
      lastUpdated: json['lastUpdated'] ?? '',
    );
  }
}

class GridTeam {
  final String teamId;
  final String teamName;
  final String? abbreviation;
  final int draftPosition;

  GridTeam({
    required this.teamId,
    required this.teamName,
    this.abbreviation,
    required this.draftPosition,
  });

  factory GridTeam.fromJson(Map<String, dynamic> json) => GridTeam(
    teamId: json['teamId'] ?? '',
    teamName: json['teamName'] ?? '',
    abbreviation: json['abbreviation'],
    draftPosition: json['draftPosition'] ?? 0,
  );
}

class GridRound {
  final int roundNumber;
  final String status;
  final List<DraftPick> picks;

  GridRound({
    required this.roundNumber,
    required this.status,
    required this.picks,
  });

  factory GridRound.fromJson(Map<String, dynamic> json) => GridRound(
    roundNumber: json['roundNumber'] ?? 0,
    status: json['status'] ?? 'pending',
    picks: (json['picks'] as List? ?? [])
        .map((p) => DraftPick.fromJson(p))
        .toList(),
  );
}
