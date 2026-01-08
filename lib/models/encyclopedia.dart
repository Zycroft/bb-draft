// Encyclopedia & Historical Statistics Models

// Season Import Status
enum SeasonImportStatus { complete, partial, pending }

// Data Source
enum DataSource { manual, api, file }

// Leaderboard Type
enum LeaderboardType { seasonal, career, customRange }

// Sort Direction
enum SortDirection { asc, desc }

/// Imported Season
class ImportedSeason {
  final String seasonId;
  final String leagueId;
  final int year;
  final String importDate;
  final DataSource dataSource;
  final SeasonImportStatus status;
  final SeasonMetadata metadata;
  final String importedBy;

  ImportedSeason({
    required this.seasonId,
    required this.leagueId,
    required this.year,
    required this.importDate,
    required this.dataSource,
    required this.status,
    required this.metadata,
    required this.importedBy,
  });

  factory ImportedSeason.fromJson(Map<String, dynamic> json) => ImportedSeason(
        seasonId: json['seasonId'] ?? '',
        leagueId: json['leagueId'] ?? '',
        year: json['year'] ?? 0,
        importDate: json['importDate'] ?? '',
        dataSource: DataSource.values.firstWhere(
          (e) => e.name == json['dataSource'],
          orElse: () => DataSource.manual,
        ),
        status: SeasonImportStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => SeasonImportStatus.pending,
        ),
        metadata: SeasonMetadata.fromJson(json['metadata'] ?? {}),
        importedBy: json['importedBy'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'seasonId': seasonId,
        'leagueId': leagueId,
        'year': year,
        'importDate': importDate,
        'dataSource': dataSource.name,
        'status': status.name,
        'metadata': metadata.toJson(),
        'importedBy': importedBy,
      };
}

class SeasonMetadata {
  final int playerCount;
  final int teamCount;
  final int gamesPlayed;
  final int weeksPlayed;

  SeasonMetadata({
    required this.playerCount,
    required this.teamCount,
    required this.gamesPlayed,
    required this.weeksPlayed,
  });

  factory SeasonMetadata.fromJson(Map<String, dynamic> json) => SeasonMetadata(
        playerCount: json['playerCount'] ?? 0,
        teamCount: json['teamCount'] ?? 0,
        gamesPlayed: json['gamesPlayed'] ?? 0,
        weeksPlayed: json['weeksPlayed'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'playerCount': playerCount,
        'teamCount': teamCount,
        'gamesPlayed': gamesPlayed,
        'weeksPlayed': weeksPlayed,
      };
}

/// Minimum Qualifier
class MinimumQualifier {
  final String statType;
  final double minValue;
  final bool perGame;

  MinimumQualifier({
    required this.statType,
    required this.minValue,
    this.perGame = false,
  });

  factory MinimumQualifier.fromJson(Map<String, dynamic> json) =>
      MinimumQualifier(
        statType: json['statType'] ?? '',
        minValue: (json['minValue'] ?? 0).toDouble(),
        perGame: json['perGame'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'statType': statType,
        'minValue': minValue,
        'perGame': perGame,
      };
}

/// Stat Category Definition
class StatCategory {
  final String code;
  final String name;
  final String description;
  final String playerType;
  final SortDirection sortDirection;
  final MinimumQualifier? minimumQualifier;
  final int decimalPlaces;
  final bool isRate;

  StatCategory({
    required this.code,
    required this.name,
    required this.description,
    required this.playerType,
    required this.sortDirection,
    this.minimumQualifier,
    required this.decimalPlaces,
    required this.isRate,
  });

  factory StatCategory.fromJson(Map<String, dynamic> json) => StatCategory(
        code: json['code'] ?? '',
        name: json['name'] ?? '',
        description: json['description'] ?? '',
        playerType: json['playerType'] ?? 'batter',
        sortDirection: json['sortDirection'] == 'asc'
            ? SortDirection.asc
            : SortDirection.desc,
        minimumQualifier: json['minimumQualifier'] != null
            ? MinimumQualifier.fromJson(json['minimumQualifier'])
            : null,
        decimalPlaces: json['decimalPlaces'] ?? 0,
        isRate: json['isRate'] ?? false,
      );
}

/// Leaderboard Entry
class LeaderboardEntry {
  final int rank;
  final String playerId;
  final String playerName;
  final String? teamId;
  final String? teamName;
  final List<String>? teams;
  final int? seasons;
  final double value;
  final int? previousRank;
  final String? trend;

  LeaderboardEntry({
    required this.rank,
    required this.playerId,
    required this.playerName,
    this.teamId,
    this.teamName,
    this.teams,
    this.seasons,
    required this.value,
    this.previousRank,
    this.trend,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      LeaderboardEntry(
        rank: json['rank'] ?? 0,
        playerId: json['playerId'] ?? '',
        playerName: json['playerName'] ?? '',
        teamId: json['teamId'],
        teamName: json['teamName'],
        teams: json['teams'] != null ? List<String>.from(json['teams']) : null,
        seasons: json['seasons'],
        value: (json['value'] ?? 0).toDouble(),
        previousRank: json['previousRank'],
        trend: json['trend'],
      );
}

/// Leaderboard
class Leaderboard {
  final String leaderboardId;
  final String leagueId;
  final String statCategory;
  final String statCode;
  final String playerType;
  final LeaderboardType leaderboardType;
  final int? seasonYear;
  final List<LeaderboardEntry> entries;
  final int totalEntries;
  final MinimumQualifier? minimumQualifier;
  final String generatedAt;

  Leaderboard({
    required this.leaderboardId,
    required this.leagueId,
    required this.statCategory,
    required this.statCode,
    required this.playerType,
    required this.leaderboardType,
    this.seasonYear,
    required this.entries,
    required this.totalEntries,
    this.minimumQualifier,
    required this.generatedAt,
  });

  factory Leaderboard.fromJson(Map<String, dynamic> json) => Leaderboard(
        leaderboardId: json['leaderboardId'] ?? '',
        leagueId: json['leagueId'] ?? '',
        statCategory: json['statCategory'] ?? '',
        statCode: json['statCode'] ?? '',
        playerType: json['playerType'] ?? 'batter',
        leaderboardType: LeaderboardType.values.firstWhere(
          (e) => e.name == json['leaderboardType'],
          orElse: () => LeaderboardType.seasonal,
        ),
        seasonYear: json['seasonYear'],
        entries: (json['entries'] as List? ?? [])
            .map((e) => LeaderboardEntry.fromJson(e))
            .toList(),
        totalEntries: json['totalEntries'] ?? 0,
        minimumQualifier: json['minimumQualifier'] != null
            ? MinimumQualifier.fromJson(json['minimumQualifier'])
            : null,
        generatedAt: json['generatedAt'] ?? '',
      );
}

/// Batting Season Stats
class BattingSeasonStats {
  final int gamesPlayed;
  final int atBats;
  final int runs;
  final int hits;
  final int doubles;
  final int triples;
  final int homeRuns;
  final int rbi;
  final int stolenBases;
  final int caughtStealing;
  final int walks;
  final int strikeouts;
  final int totalBases;
  final double avg;
  final double obp;
  final double slg;
  final double ops;

  BattingSeasonStats({
    required this.gamesPlayed,
    required this.atBats,
    required this.runs,
    required this.hits,
    required this.doubles,
    required this.triples,
    required this.homeRuns,
    required this.rbi,
    required this.stolenBases,
    required this.caughtStealing,
    required this.walks,
    required this.strikeouts,
    required this.totalBases,
    required this.avg,
    required this.obp,
    required this.slg,
    required this.ops,
  });

  factory BattingSeasonStats.fromJson(Map<String, dynamic> json) =>
      BattingSeasonStats(
        gamesPlayed: json['gamesPlayed'] ?? 0,
        atBats: json['atBats'] ?? 0,
        runs: json['runs'] ?? 0,
        hits: json['hits'] ?? 0,
        doubles: json['doubles'] ?? 0,
        triples: json['triples'] ?? 0,
        homeRuns: json['homeRuns'] ?? 0,
        rbi: json['rbi'] ?? 0,
        stolenBases: json['stolenBases'] ?? 0,
        caughtStealing: json['caughtStealing'] ?? 0,
        walks: json['walks'] ?? 0,
        strikeouts: json['strikeouts'] ?? 0,
        totalBases: json['totalBases'] ?? 0,
        avg: (json['avg'] ?? 0).toDouble(),
        obp: (json['obp'] ?? 0).toDouble(),
        slg: (json['slg'] ?? 0).toDouble(),
        ops: (json['ops'] ?? 0).toDouble(),
      );
}

/// Pitching Season Stats
class PitchingSeasonStats {
  final int wins;
  final int losses;
  final double era;
  final int games;
  final int gamesStarted;
  final int completeGames;
  final int shutouts;
  final int saves;
  final int holds;
  final double inningsPitched;
  final int hits;
  final int runs;
  final int earnedRuns;
  final int homeRuns;
  final int walks;
  final int strikeouts;
  final double whip;
  final double k9;
  final double bb9;
  final double kbb;
  final double winPct;

  PitchingSeasonStats({
    required this.wins,
    required this.losses,
    required this.era,
    required this.games,
    required this.gamesStarted,
    required this.completeGames,
    required this.shutouts,
    required this.saves,
    required this.holds,
    required this.inningsPitched,
    required this.hits,
    required this.runs,
    required this.earnedRuns,
    required this.homeRuns,
    required this.walks,
    required this.strikeouts,
    required this.whip,
    required this.k9,
    required this.bb9,
    required this.kbb,
    required this.winPct,
  });

  factory PitchingSeasonStats.fromJson(Map<String, dynamic> json) =>
      PitchingSeasonStats(
        wins: json['wins'] ?? 0,
        losses: json['losses'] ?? 0,
        era: (json['era'] ?? 0).toDouble(),
        games: json['games'] ?? 0,
        gamesStarted: json['gamesStarted'] ?? 0,
        completeGames: json['completeGames'] ?? 0,
        shutouts: json['shutouts'] ?? 0,
        saves: json['saves'] ?? 0,
        holds: json['holds'] ?? 0,
        inningsPitched: (json['inningsPitched'] ?? 0).toDouble(),
        hits: json['hits'] ?? 0,
        runs: json['runs'] ?? 0,
        earnedRuns: json['earnedRuns'] ?? 0,
        homeRuns: json['homeRuns'] ?? 0,
        walks: json['walks'] ?? 0,
        strikeouts: json['strikeouts'] ?? 0,
        whip: (json['whip'] ?? 0).toDouble(),
        k9: (json['k9'] ?? 0).toDouble(),
        bb9: (json['bb9'] ?? 0).toDouble(),
        kbb: (json['kbb'] ?? 0).toDouble(),
        winPct: (json['winPct'] ?? 0).toDouble(),
      );
}

/// Player Season Stats
class PlayerSeasonStats {
  final String playerId;
  final String playerName;
  final String leagueId;
  final int seasonYear;
  final String teamId;
  final String teamName;
  final BattingSeasonStats? batting;
  final PitchingSeasonStats? pitching;

  PlayerSeasonStats({
    required this.playerId,
    required this.playerName,
    required this.leagueId,
    required this.seasonYear,
    required this.teamId,
    required this.teamName,
    this.batting,
    this.pitching,
  });

  factory PlayerSeasonStats.fromJson(Map<String, dynamic> json) =>
      PlayerSeasonStats(
        playerId: json['playerId'] ?? '',
        playerName: json['playerName'] ?? '',
        leagueId: json['leagueId'] ?? '',
        seasonYear: json['seasonYear'] ?? 0,
        teamId: json['teamId'] ?? '',
        teamName: json['teamName'] ?? '',
        batting: json['batting'] != null
            ? BattingSeasonStats.fromJson(json['batting'])
            : null,
        pitching: json['pitching'] != null
            ? PitchingSeasonStats.fromJson(json['pitching'])
            : null,
      );
}

/// Season Best
class SeasonBest {
  final double value;
  final int year;

  SeasonBest({required this.value, required this.year});

  factory SeasonBest.fromJson(Map<String, dynamic> json) => SeasonBest(
        value: (json['value'] ?? 0).toDouble(),
        year: json['year'] ?? 0,
      );
}

/// Player Career Stats
class PlayerCareerStats {
  final String playerId;
  final String playerName;
  final String leagueId;
  final int seasonsPlayed;
  final List<String> teams;
  final bool isActive;
  final BattingSeasonStats? batting;
  final PitchingSeasonStats? pitching;
  final Map<String, SeasonBest> seasonBests;
  final Map<String, int> rankings;

  PlayerCareerStats({
    required this.playerId,
    required this.playerName,
    required this.leagueId,
    required this.seasonsPlayed,
    required this.teams,
    required this.isActive,
    this.batting,
    this.pitching,
    required this.seasonBests,
    required this.rankings,
  });

  factory PlayerCareerStats.fromJson(Map<String, dynamic> json) {
    final seasonBestsMap = <String, SeasonBest>{};
    if (json['seasonBests'] != null) {
      (json['seasonBests'] as Map<String, dynamic>).forEach((key, value) {
        seasonBestsMap[key] = SeasonBest.fromJson(value);
      });
    }

    final rankingsMap = <String, int>{};
    if (json['rankings'] != null) {
      (json['rankings'] as Map<String, dynamic>).forEach((key, value) {
        rankingsMap[key] = value as int;
      });
    }

    return PlayerCareerStats(
      playerId: json['playerId'] ?? '',
      playerName: json['playerName'] ?? '',
      leagueId: json['leagueId'] ?? '',
      seasonsPlayed: json['seasonsPlayed'] ?? 0,
      teams: List<String>.from(json['teams'] ?? []),
      isActive: json['isActive'] ?? true,
      batting: json['batting'] != null
          ? BattingSeasonStats.fromJson(json['batting'])
          : null,
      pitching: json['pitching'] != null
          ? PitchingSeasonStats.fromJson(json['pitching'])
          : null,
      seasonBests: seasonBestsMap,
      rankings: rankingsMap,
    );
  }
}

/// Stat Comparison
class StatComparison {
  final double mlb;
  final double league;
  final double difference;
  final double percentVariance;

  StatComparison({
    required this.mlb,
    required this.league,
    required this.difference,
    required this.percentVariance,
  });

  factory StatComparison.fromJson(Map<String, dynamic> json) => StatComparison(
        mlb: (json['mlb'] ?? 0).toDouble(),
        league: (json['league'] ?? 0).toDouble(),
        difference: (json['difference'] ?? 0).toDouble(),
        percentVariance: (json['percentVariance'] ?? 0).toDouble(),
      );
}

/// Batting Comparison
class BattingComparison {
  final StatComparison? avg;
  final StatComparison? hr;
  final StatComparison? rbi;
  final StatComparison? runs;
  final StatComparison? sb;
  final StatComparison? hits;
  final StatComparison? walks;
  final StatComparison? ops;

  BattingComparison({
    this.avg,
    this.hr,
    this.rbi,
    this.runs,
    this.sb,
    this.hits,
    this.walks,
    this.ops,
  });

  factory BattingComparison.fromJson(Map<String, dynamic> json) =>
      BattingComparison(
        avg: json['avg'] != null ? StatComparison.fromJson(json['avg']) : null,
        hr: json['hr'] != null ? StatComparison.fromJson(json['hr']) : null,
        rbi: json['rbi'] != null ? StatComparison.fromJson(json['rbi']) : null,
        runs:
            json['runs'] != null ? StatComparison.fromJson(json['runs']) : null,
        sb: json['sb'] != null ? StatComparison.fromJson(json['sb']) : null,
        hits:
            json['hits'] != null ? StatComparison.fromJson(json['hits']) : null,
        walks: json['walks'] != null
            ? StatComparison.fromJson(json['walks'])
            : null,
        ops: json['ops'] != null ? StatComparison.fromJson(json['ops']) : null,
      );
}

/// Pitching Comparison
class PitchingComparison {
  final StatComparison? era;
  final StatComparison? wins;
  final StatComparison? strikeouts;
  final StatComparison? saves;
  final StatComparison? whip;
  final StatComparison? ip;

  PitchingComparison({
    this.era,
    this.wins,
    this.strikeouts,
    this.saves,
    this.whip,
    this.ip,
  });

  factory PitchingComparison.fromJson(Map<String, dynamic> json) =>
      PitchingComparison(
        era: json['era'] != null ? StatComparison.fromJson(json['era']) : null,
        wins:
            json['wins'] != null ? StatComparison.fromJson(json['wins']) : null,
        strikeouts: json['strikeouts'] != null
            ? StatComparison.fromJson(json['strikeouts'])
            : null,
        saves: json['saves'] != null
            ? StatComparison.fromJson(json['saves'])
            : null,
        whip:
            json['whip'] != null ? StatComparison.fromJson(json['whip']) : null,
        ip: json['ip'] != null ? StatComparison.fromJson(json['ip']) : null,
      );
}

/// Player Comparison
class PlayerComparison {
  final String comparisonId;
  final String playerId;
  final String playerName;
  final String leagueId;
  final int? seasonYear;
  final String comparisonType;
  final BattingComparison? batting;
  final PitchingComparison? pitching;
  final double matchScore;
  final String consistencyRating;
  final String generatedAt;

  PlayerComparison({
    required this.comparisonId,
    required this.playerId,
    required this.playerName,
    required this.leagueId,
    this.seasonYear,
    required this.comparisonType,
    this.batting,
    this.pitching,
    required this.matchScore,
    required this.consistencyRating,
    required this.generatedAt,
  });

  factory PlayerComparison.fromJson(Map<String, dynamic> json) =>
      PlayerComparison(
        comparisonId: json['comparisonId'] ?? '',
        playerId: json['playerId'] ?? '',
        playerName: json['playerName'] ?? '',
        leagueId: json['leagueId'] ?? '',
        seasonYear: json['seasonYear'],
        comparisonType: json['comparisonType'] ?? 'single_season',
        batting: json['batting'] != null
            ? BattingComparison.fromJson(json['batting'])
            : null,
        pitching: json['pitching'] != null
            ? PitchingComparison.fromJson(json['pitching'])
            : null,
        matchScore: (json['matchScore'] ?? 0).toDouble(),
        consistencyRating: json['consistencyRating'] ?? 'C',
        generatedAt: json['generatedAt'] ?? '',
      );
}

/// Team Regular Season Record
class TeamRegularSeasonRecord {
  final int wins;
  final int losses;
  final double winningPercentage;
  final int gamesPlayed;
  final double pointsFor;
  final double pointsAgainst;
  final double pointDifferential;

  TeamRegularSeasonRecord({
    required this.wins,
    required this.losses,
    required this.winningPercentage,
    required this.gamesPlayed,
    required this.pointsFor,
    required this.pointsAgainst,
    required this.pointDifferential,
  });

  factory TeamRegularSeasonRecord.fromJson(Map<String, dynamic> json) =>
      TeamRegularSeasonRecord(
        wins: json['wins'] ?? 0,
        losses: json['losses'] ?? 0,
        winningPercentage: (json['winningPercentage'] ?? 0).toDouble(),
        gamesPlayed: json['gamesPlayed'] ?? 0,
        pointsFor: (json['pointsFor'] ?? 0).toDouble(),
        pointsAgainst: (json['pointsAgainst'] ?? 0).toDouble(),
        pointDifferential: (json['pointDifferential'] ?? 0).toDouble(),
      );
}

/// Team Postseason Record
class TeamPostseasonRecord {
  final int appearances;
  final int wins;
  final int losses;
  final double winningPercentage;

  TeamPostseasonRecord({
    required this.appearances,
    required this.wins,
    required this.losses,
    required this.winningPercentage,
  });

  factory TeamPostseasonRecord.fromJson(Map<String, dynamic> json) =>
      TeamPostseasonRecord(
        appearances: json['appearances'] ?? 0,
        wins: json['wins'] ?? 0,
        losses: json['losses'] ?? 0,
        winningPercentage: (json['winningPercentage'] ?? 0).toDouble(),
      );
}

/// Team Championship Record
class TeamChampionshipRecord {
  final int appearances;
  final int wins;
  final int losses;
  final double winningPercentage;
  final List<int> years;

  TeamChampionshipRecord({
    required this.appearances,
    required this.wins,
    required this.losses,
    required this.winningPercentage,
    required this.years,
  });

  factory TeamChampionshipRecord.fromJson(Map<String, dynamic> json) =>
      TeamChampionshipRecord(
        appearances: json['appearances'] ?? 0,
        wins: json['wins'] ?? 0,
        losses: json['losses'] ?? 0,
        winningPercentage: (json['winningPercentage'] ?? 0).toDouble(),
        years: List<int>.from(json['years'] ?? []),
      );
}

/// Team Season Record
class TeamSeasonRecord {
  final int year;
  final int wins;
  final int losses;
  final double winningPercentage;
  final int standingsPosition;
  final String? playoffResult;
  final bool champion;
  final double pointsFor;
  final double pointsAgainst;

  TeamSeasonRecord({
    required this.year,
    required this.wins,
    required this.losses,
    required this.winningPercentage,
    required this.standingsPosition,
    this.playoffResult,
    required this.champion,
    required this.pointsFor,
    required this.pointsAgainst,
  });

  factory TeamSeasonRecord.fromJson(Map<String, dynamic> json) =>
      TeamSeasonRecord(
        year: json['year'] ?? 0,
        wins: json['wins'] ?? 0,
        losses: json['losses'] ?? 0,
        winningPercentage: (json['winningPercentage'] ?? 0).toDouble(),
        standingsPosition: json['standingsPosition'] ?? 0,
        playoffResult: json['playoffResult'],
        champion: json['champion'] ?? false,
        pointsFor: (json['pointsFor'] ?? 0).toDouble(),
        pointsAgainst: (json['pointsAgainst'] ?? 0).toDouble(),
      );
}

/// Team Historical Stats
class TeamHistoricalStats {
  final String teamId;
  final String teamName;
  final String leagueId;
  final TeamAllTimeRecord allTime;
  final List<TeamSeasonRecord> seasons;
  final double dynastyScore;

  TeamHistoricalStats({
    required this.teamId,
    required this.teamName,
    required this.leagueId,
    required this.allTime,
    required this.seasons,
    required this.dynastyScore,
  });

  factory TeamHistoricalStats.fromJson(Map<String, dynamic> json) =>
      TeamHistoricalStats(
        teamId: json['teamId'] ?? '',
        teamName: json['teamName'] ?? '',
        leagueId: json['leagueId'] ?? '',
        allTime: TeamAllTimeRecord.fromJson(json['allTime'] ?? {}),
        seasons: (json['seasons'] as List? ?? [])
            .map((s) => TeamSeasonRecord.fromJson(s))
            .toList(),
        dynastyScore: (json['dynastyScore'] ?? 0).toDouble(),
      );
}

class TeamAllTimeRecord {
  final TeamRegularSeasonRecord regularSeason;
  final TeamPostseasonRecord postseason;
  final TeamChampionshipRecord championships;

  TeamAllTimeRecord({
    required this.regularSeason,
    required this.postseason,
    required this.championships,
  });

  factory TeamAllTimeRecord.fromJson(Map<String, dynamic> json) =>
      TeamAllTimeRecord(
        regularSeason:
            TeamRegularSeasonRecord.fromJson(json['regularSeason'] ?? {}),
        postseason: TeamPostseasonRecord.fromJson(json['postseason'] ?? {}),
        championships:
            TeamChampionshipRecord.fromJson(json['championships'] ?? {}),
      );
}

/// Team Leaderboard Entry
class TeamLeaderboardEntry {
  final int rank;
  final String teamId;
  final String teamName;
  final double value;
  final double? secondaryValue;
  final int? championships;
  final int? playoffAppearances;

  TeamLeaderboardEntry({
    required this.rank,
    required this.teamId,
    required this.teamName,
    required this.value,
    this.secondaryValue,
    this.championships,
    this.playoffAppearances,
  });

  factory TeamLeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      TeamLeaderboardEntry(
        rank: json['rank'] ?? 0,
        teamId: json['teamId'] ?? '',
        teamName: json['teamName'] ?? '',
        value: (json['value'] ?? 0).toDouble(),
        secondaryValue: json['secondaryValue']?.toDouble(),
        championships: json['championships'],
        playoffAppearances: json['playoffAppearances'],
      );
}

/// Encyclopedia Summary
class EncyclopediaSummary {
  final String leagueId;
  final int totalSeasons;
  final int totalPlayers;
  final int totalTeams;
  final int currentSeasonYear;
  final List<int> importedSeasons;
  final TopBattingLeaders topBattingLeaders;
  final TopPitchingLeaders topPitchingLeaders;
  final List<TeamLeaderboardEntry> teamStandings;
  final String lastUpdated;

  EncyclopediaSummary({
    required this.leagueId,
    required this.totalSeasons,
    required this.totalPlayers,
    required this.totalTeams,
    required this.currentSeasonYear,
    required this.importedSeasons,
    required this.topBattingLeaders,
    required this.topPitchingLeaders,
    required this.teamStandings,
    required this.lastUpdated,
  });

  factory EncyclopediaSummary.fromJson(Map<String, dynamic> json) =>
      EncyclopediaSummary(
        leagueId: json['leagueId'] ?? '',
        totalSeasons: json['totalSeasons'] ?? 0,
        totalPlayers: json['totalPlayers'] ?? 0,
        totalTeams: json['totalTeams'] ?? 0,
        currentSeasonYear: json['currentSeasonYear'] ?? 0,
        importedSeasons: List<int>.from(json['importedSeasons'] ?? []),
        topBattingLeaders:
            TopBattingLeaders.fromJson(json['topBattingLeaders'] ?? {}),
        topPitchingLeaders:
            TopPitchingLeaders.fromJson(json['topPitchingLeaders'] ?? {}),
        teamStandings: (json['teamStandings'] as List? ?? [])
            .map((t) => TeamLeaderboardEntry.fromJson(t))
            .toList(),
        lastUpdated: json['lastUpdated'] ?? '',
      );
}

class TopBattingLeaders {
  final List<LeaderboardEntry> avg;
  final List<LeaderboardEntry> hr;
  final List<LeaderboardEntry> rbi;

  TopBattingLeaders({
    required this.avg,
    required this.hr,
    required this.rbi,
  });

  factory TopBattingLeaders.fromJson(Map<String, dynamic> json) =>
      TopBattingLeaders(
        avg: (json['avg'] as List? ?? [])
            .map((e) => LeaderboardEntry.fromJson(e))
            .toList(),
        hr: (json['hr'] as List? ?? [])
            .map((e) => LeaderboardEntry.fromJson(e))
            .toList(),
        rbi: (json['rbi'] as List? ?? [])
            .map((e) => LeaderboardEntry.fromJson(e))
            .toList(),
      );
}

class TopPitchingLeaders {
  final List<LeaderboardEntry> era;
  final List<LeaderboardEntry> wins;
  final List<LeaderboardEntry> so;

  TopPitchingLeaders({
    required this.era,
    required this.wins,
    required this.so,
  });

  factory TopPitchingLeaders.fromJson(Map<String, dynamic> json) =>
      TopPitchingLeaders(
        era: (json['era'] as List? ?? [])
            .map((e) => LeaderboardEntry.fromJson(e))
            .toList(),
        wins: (json['wins'] as List? ?? [])
            .map((e) => LeaderboardEntry.fromJson(e))
            .toList(),
        so: (json['so'] as List? ?? [])
            .map((e) => LeaderboardEntry.fromJson(e))
            .toList(),
      );
}

/// Leaderboard Categories (for displaying available stat categories)
class LeaderboardCategories {
  final List<StatCategory> batting;
  final List<StatCategory> pitching;

  LeaderboardCategories({
    required this.batting,
    required this.pitching,
  });

  factory LeaderboardCategories.fromJson(Map<String, dynamic> json) =>
      LeaderboardCategories(
        batting: (json['batting'] as List? ?? [])
            .map((c) => StatCategory.fromJson(c))
            .toList(),
        pitching: (json['pitching'] as List? ?? [])
            .map((c) => StatCategory.fromJson(c))
            .toList(),
      );
}
