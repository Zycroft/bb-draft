class League {
  final String leagueId;
  final String name;
  final String commissionerId;
  final String inviteCode;
  final LeagueStatus status;
  final LeagueSettings settings;
  final int season;
  final String createdAt;
  final String updatedAt;
  final int? teamCount;
  final List<LeagueTeam>? teams;

  League({
    required this.leagueId,
    required this.name,
    required this.commissionerId,
    required this.inviteCode,
    required this.status,
    required this.settings,
    required this.season,
    required this.createdAt,
    required this.updatedAt,
    this.teamCount,
    this.teams,
  });

  bool isCommissioner(String userId) => commissionerId == userId;

  factory League.fromJson(Map<String, dynamic> json) {
    List<LeagueTeam>? teams;
    if (json['teams'] != null && json['teams'] is List) {
      teams = (json['teams'] as List)
          .map((t) => LeagueTeam.fromJson(t))
          .toList();
    }

    return League(
      leagueId: json['leagueId'] ?? '',
      name: json['name'] ?? '',
      commissionerId: json['commissionerId'] ?? '',
      inviteCode: json['inviteCode'] ?? '',
      status: LeagueStatus.fromString(json['status']),
      settings: LeagueSettings.fromJson(json['settings'] ?? {}),
      season: json['season'] ?? DateTime.now().year,
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      teamCount: json['teamCount'],
      teams: teams,
    );
  }

  Map<String, dynamic> toJson() => {
    'leagueId': leagueId,
    'name': name,
    'commissionerId': commissionerId,
    'inviteCode': inviteCode,
    'status': status.value,
    'settings': settings.toJson(),
    'season': season,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };
}

enum LeagueStatus {
  preDraft('pre_draft'),
  drafting('drafting'),
  inSeason('in_season'),
  completed('completed');

  final String value;
  const LeagueStatus(this.value);

  static LeagueStatus fromString(String? value) {
    switch (value) {
      case 'pre_draft':
        return LeagueStatus.preDraft;
      case 'drafting':
        return LeagueStatus.drafting;
      case 'in_season':
        return LeagueStatus.inSeason;
      case 'completed':
        return LeagueStatus.completed;
      default:
        return LeagueStatus.preDraft;
    }
  }

  String get displayName {
    switch (this) {
      case LeagueStatus.preDraft:
        return 'Pre-Draft';
      case LeagueStatus.drafting:
        return 'Drafting';
      case LeagueStatus.inSeason:
        return 'In Season';
      case LeagueStatus.completed:
        return 'Completed';
    }
  }
}

class LeagueSettings {
  final int maxTeams;
  final String draftFormat;
  final String scoringType;
  final int pickTimer;
  final int rounds;
  final bool tradePicksEnabled;
  final Map<String, int> roster;

  LeagueSettings({
    required this.maxTeams,
    required this.draftFormat,
    required this.scoringType,
    required this.pickTimer,
    required this.rounds,
    required this.tradePicksEnabled,
    required this.roster,
  });

  factory LeagueSettings.fromJson(Map<String, dynamic> json) => LeagueSettings(
    maxTeams: json['maxTeams'] ?? 12,
    draftFormat: json['draftFormat'] ?? 'serpentine',
    scoringType: json['scoringType'] ?? 'head_to_head',
    pickTimer: json['pickTimer'] ?? 90,
    rounds: json['rounds'] ?? 23,
    tradePicksEnabled: json['tradePicksEnabled'] ?? true,
    roster: Map<String, int>.from(json['roster'] ?? {}),
  );

  Map<String, dynamic> toJson() => {
    'maxTeams': maxTeams,
    'draftFormat': draftFormat,
    'scoringType': scoringType,
    'pickTimer': pickTimer,
    'rounds': rounds,
    'tradePicksEnabled': tradePicksEnabled,
    'roster': roster,
  };
}

class LeagueTeam {
  final String teamId;
  final String name;
  final String ownerId;
  final int? draftPosition;

  LeagueTeam({
    required this.teamId,
    required this.name,
    required this.ownerId,
    this.draftPosition,
  });

  factory LeagueTeam.fromJson(Map<String, dynamic> json) => LeagueTeam(
    teamId: json['teamId'] ?? '',
    name: json['name'] ?? '',
    ownerId: json['ownerId'] ?? '',
    draftPosition: json['draftPosition'],
  );
}
