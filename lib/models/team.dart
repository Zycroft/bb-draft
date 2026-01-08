class Team {
  final String teamId;
  final String leagueId;
  final String ownerId;
  final String name;
  final String? abbreviation;
  final int? draftPosition;
  final String createdAt;
  final String updatedAt;
  final List<RosterPlayer> roster;
  final List<String> draftQueue;

  Team({
    required this.teamId,
    required this.leagueId,
    required this.ownerId,
    required this.name,
    this.abbreviation,
    this.draftPosition,
    required this.createdAt,
    required this.updatedAt,
    required this.roster,
    required this.draftQueue,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    List<RosterPlayer> roster = [];
    if (json['roster'] != null && json['roster'] is List) {
      roster = (json['roster'] as List)
          .map((r) => RosterPlayer.fromJson(r))
          .toList();
    }

    List<String> queue = [];
    if (json['draftQueue'] != null && json['draftQueue'] is List) {
      queue = List<String>.from(json['draftQueue']);
    }

    return Team(
      teamId: json['teamId'] ?? '',
      leagueId: json['leagueId'] ?? '',
      ownerId: json['ownerId'] ?? '',
      name: json['name'] ?? '',
      abbreviation: json['abbreviation'],
      draftPosition: json['draftPosition'],
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      roster: roster,
      draftQueue: queue,
    );
  }

  Map<String, dynamic> toJson() => {
    'teamId': teamId,
    'leagueId': leagueId,
    'ownerId': ownerId,
    'name': name,
    'abbreviation': abbreviation,
    'draftPosition': draftPosition,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'roster': roster.map((r) => r.toJson()).toList(),
    'draftQueue': draftQueue,
  };
}

class RosterPlayer {
  final String playerId;
  final String position;
  final String acquisitionType;
  final String acquisitionDate;

  RosterPlayer({
    required this.playerId,
    required this.position,
    required this.acquisitionType,
    required this.acquisitionDate,
  });

  factory RosterPlayer.fromJson(Map<String, dynamic> json) => RosterPlayer(
    playerId: json['playerId'] ?? '',
    position: json['position'] ?? '',
    acquisitionType: json['acquisitionType'] ?? 'draft',
    acquisitionDate: json['acquisitionDate'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'playerId': playerId,
    'position': position,
    'acquisitionType': acquisitionType,
    'acquisitionDate': acquisitionDate,
  };
}
