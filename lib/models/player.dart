// Draft Eligibility Status
enum DraftEligibility {
  eligible('eligible'),
  onTeam('onTeam'),
  notEligible('notEligible');

  final String value;
  const DraftEligibility(this.value);

  static DraftEligibility fromString(String? value) {
    switch (value) {
      case 'onTeam':
        return DraftEligibility.onTeam;
      case 'notEligible':
        return DraftEligibility.notEligible;
      default:
        return DraftEligibility.eligible;
    }
  }

  String get displayName {
    switch (this) {
      case DraftEligibility.eligible:
        return 'Eligible';
      case DraftEligibility.onTeam:
        return 'On Team';
      case DraftEligibility.notEligible:
        return 'Not Eligible';
    }
  }
}

class Player {
  final String playerId;
  final int mlbId;
  final String fullName;
  final String firstName;
  final String lastName;
  final String primaryPosition;
  final String mlbTeam;
  final int mlbTeamId;
  final String? jerseyNumber;
  final String batSide;
  final String pitchHand;
  final String? birthDate;
  final String? height;
  final int? weight;
  final bool active;
  final String? mlbDebutDate;
  final String? photoUrl;
  final DraftEligibility eligibility;
  final String? eligibilityNote;
  final String? ownerTeamId;
  final BatterStats? battingStats;
  final PitcherStats? pitchingStats;
  final ScoutingGrades? scoutingGrades;
  final WARMetrics? warMetrics;
  final StatcastHittingMetrics? statcastHitting;
  final StatcastPitchingMetrics? statcastPitching;
  final FieldingMetrics? fieldingMetrics;
  final CatcherMetrics? catcherMetrics;
  final String lastUpdated;

  Player({
    required this.playerId,
    required this.mlbId,
    required this.fullName,
    required this.firstName,
    required this.lastName,
    required this.primaryPosition,
    required this.mlbTeam,
    required this.mlbTeamId,
    this.jerseyNumber,
    required this.batSide,
    required this.pitchHand,
    this.birthDate,
    this.height,
    this.weight,
    required this.active,
    this.mlbDebutDate,
    this.photoUrl,
    this.eligibility = DraftEligibility.eligible,
    this.eligibilityNote,
    this.ownerTeamId,
    this.battingStats,
    this.pitchingStats,
    this.scoutingGrades,
    this.warMetrics,
    this.statcastHitting,
    this.statcastPitching,
    this.fieldingMetrics,
    this.catcherMetrics,
    required this.lastUpdated,
  });

  bool get isBatter => !['SP', 'RP', 'P', 'CL'].contains(primaryPosition);
  bool get isPitcher => ['SP', 'RP', 'P', 'CL'].contains(primaryPosition);
  bool get isCatcher => primaryPosition == 'C';

  factory Player.fromJson(Map<String, dynamic> json) {
    BatterStats? batting;
    PitcherStats? pitching;
    ScoutingGrades? scouting;
    WARMetrics? war;
    StatcastHittingMetrics? statcastHit;
    StatcastPitchingMetrics? statcastPitch;
    FieldingMetrics? fielding;
    CatcherMetrics? catcher;

    if (json['stats'] != null) {
      if (json['stats']['batting'] != null) {
        batting = BatterStats.fromJson(json['stats']['batting']);
      }
      if (json['stats']['pitching'] != null) {
        pitching = PitcherStats.fromJson(json['stats']['pitching']);
      }
    }

    if (json['scoutingGrades'] != null) {
      scouting = ScoutingGrades.fromJson(json['scoutingGrades']);
    }
    if (json['warMetrics'] != null) {
      war = WARMetrics.fromJson(json['warMetrics']);
    }
    if (json['statcastHitting'] != null) {
      statcastHit = StatcastHittingMetrics.fromJson(json['statcastHitting']);
    }
    if (json['statcastPitching'] != null) {
      statcastPitch = StatcastPitchingMetrics.fromJson(json['statcastPitching']);
    }
    if (json['fieldingMetrics'] != null) {
      fielding = FieldingMetrics.fromJson(json['fieldingMetrics']);
    }
    if (json['catcherMetrics'] != null) {
      catcher = CatcherMetrics.fromJson(json['catcherMetrics']);
    }

    return Player(
      playerId: json['playerId'] ?? '',
      mlbId: json['mlbId'] ?? 0,
      fullName: json['fullName'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      primaryPosition: json['primaryPosition'] ?? '',
      mlbTeam: json['mlbTeam'] ?? 'FA',
      mlbTeamId: json['mlbTeamId'] ?? 0,
      jerseyNumber: json['jerseyNumber'],
      batSide: json['batSide'] ?? 'R',
      pitchHand: json['pitchHand'] ?? 'R',
      birthDate: json['birthDate'],
      height: json['height'],
      weight: json['weight'],
      active: json['active'] ?? true,
      mlbDebutDate: json['mlbDebutDate'],
      photoUrl: json['photoUrl'],
      eligibility: DraftEligibility.fromString(json['eligibility']),
      eligibilityNote: json['eligibilityNote'],
      ownerTeamId: json['ownerTeamId'],
      battingStats: batting,
      pitchingStats: pitching,
      scoutingGrades: scouting,
      warMetrics: war,
      statcastHitting: statcastHit,
      statcastPitching: statcastPitch,
      fieldingMetrics: fielding,
      catcherMetrics: catcher,
      lastUpdated: json['lastUpdated'] ?? '',
    );
  }

  Player copyWith({
    DraftEligibility? eligibility,
    String? eligibilityNote,
    String? ownerTeamId,
  }) {
    return Player(
      playerId: playerId,
      mlbId: mlbId,
      fullName: fullName,
      firstName: firstName,
      lastName: lastName,
      primaryPosition: primaryPosition,
      mlbTeam: mlbTeam,
      mlbTeamId: mlbTeamId,
      jerseyNumber: jerseyNumber,
      batSide: batSide,
      pitchHand: pitchHand,
      birthDate: birthDate,
      height: height,
      weight: weight,
      active: active,
      mlbDebutDate: mlbDebutDate,
      photoUrl: photoUrl,
      eligibility: eligibility ?? this.eligibility,
      eligibilityNote: eligibilityNote ?? this.eligibilityNote,
      ownerTeamId: ownerTeamId ?? this.ownerTeamId,
      battingStats: battingStats,
      pitchingStats: pitchingStats,
      scoutingGrades: scoutingGrades,
      warMetrics: warMetrics,
      statcastHitting: statcastHitting,
      statcastPitching: statcastPitching,
      fieldingMetrics: fieldingMetrics,
      catcherMetrics: catcherMetrics,
      lastUpdated: lastUpdated,
    );
  }

  Map<String, dynamic> toJson() => {
    'playerId': playerId,
    'mlbId': mlbId,
    'fullName': fullName,
    'firstName': firstName,
    'lastName': lastName,
    'primaryPosition': primaryPosition,
    'mlbTeam': mlbTeam,
    'mlbTeamId': mlbTeamId,
    'jerseyNumber': jerseyNumber,
    'batSide': batSide,
    'pitchHand': pitchHand,
    'birthDate': birthDate,
    'height': height,
    'weight': weight,
    'active': active,
    'mlbDebutDate': mlbDebutDate,
    'photoUrl': photoUrl,
    'eligibility': eligibility.value,
    'eligibilityNote': eligibilityNote,
    'ownerTeamId': ownerTeamId,
    'lastUpdated': lastUpdated,
  };
}

// 20-80 Scouting Scale Grades
class ScoutingGrades {
  final int? hit;        // 20-80 scale
  final int? gamePower;  // 20-80 scale
  final int? rawPower;   // 20-80 scale
  final int? speed;      // 20-80 scale
  final int? field;      // 20-80 scale
  final int? arm;        // 20-80 scale
  // Pitcher-specific grades
  final int? fastball;
  final int? slider;
  final int? curveball;
  final int? changeup;
  final int? control;
  final int? overall;

  ScoutingGrades({
    this.hit,
    this.gamePower,
    this.rawPower,
    this.speed,
    this.field,
    this.arm,
    this.fastball,
    this.slider,
    this.curveball,
    this.changeup,
    this.control,
    this.overall,
  });

  factory ScoutingGrades.fromJson(Map<String, dynamic> json) => ScoutingGrades(
    hit: json['hit'],
    gamePower: json['gamePower'],
    rawPower: json['rawPower'],
    speed: json['speed'],
    field: json['field'],
    arm: json['arm'],
    fastball: json['fastball'],
    slider: json['slider'],
    curveball: json['curveball'],
    changeup: json['changeup'],
    control: json['control'],
    overall: json['overall'],
  );

  static String gradeDescription(int grade) {
    if (grade >= 80) return 'Elite';
    if (grade >= 70) return 'Plus-Plus';
    if (grade >= 60) return 'Plus';
    if (grade >= 55) return 'Above Avg';
    if (grade >= 50) return 'Average';
    if (grade >= 45) return 'Below Avg';
    if (grade >= 40) return 'Fringe';
    if (grade >= 30) return 'Poor';
    return 'Very Poor';
  }
}

// WAR Metrics from FanGraphs and Baseball Reference
class WARMetrics {
  final double? fWAR;    // FanGraphs WAR
  final double? bWAR;    // Baseball-Reference WAR
  final int season;

  WARMetrics({
    this.fWAR,
    this.bWAR,
    required this.season,
  });

  factory WARMetrics.fromJson(Map<String, dynamic> json) => WARMetrics(
    fWAR: json['fWAR']?.toDouble(),
    bWAR: json['bWAR']?.toDouble(),
    season: json['season'] ?? DateTime.now().year,
  );
}

// Complete Batter Stats
class BatterStats {
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
  final String avg;
  final String obp;
  final String slg;
  final String ops;
  // Additional stats from spec
  final int? totalBases;
  final int? groundIntoDP;
  final int? hitByPitch;
  final int? sacrificeHits;
  final int? sacrificeFlies;
  final int? intentionalWalks;

  BatterStats({
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
    required this.avg,
    required this.obp,
    required this.slg,
    required this.ops,
    this.totalBases,
    this.groundIntoDP,
    this.hitByPitch,
    this.sacrificeHits,
    this.sacrificeFlies,
    this.intentionalWalks,
  });

  factory BatterStats.fromJson(Map<String, dynamic> json) => BatterStats(
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
    avg: json['avg'] ?? '.000',
    obp: json['obp'] ?? '.000',
    slg: json['slg'] ?? '.000',
    ops: json['ops'] ?? '.000',
    totalBases: json['totalBases'],
    groundIntoDP: json['groundIntoDP'],
    hitByPitch: json['hitByPitch'],
    sacrificeHits: json['sacrificeHits'],
    sacrificeFlies: json['sacrificeFlies'],
    intentionalWalks: json['intentionalWalks'],
  );
}

// Complete Pitcher Stats
class PitcherStats {
  final int wins;
  final int losses;
  final String era;
  final int games;
  final int gamesStarted;
  final int saves;
  final String inningsPitched;
  final int hits;
  final int runs;
  final int earnedRuns;
  final int homeRuns;
  final int walks;
  final int strikeouts;
  final String whip;
  final String avg;
  // Additional stats from spec
  final int? completeGames;
  final int? shutouts;
  final int? saveOpportunities;
  final int? intentionalWalks;
  final int? hitBatters;
  final int? balks;
  final int? wildPitches;
  final String? kPer9;
  final String? bbPer9;

  PitcherStats({
    required this.wins,
    required this.losses,
    required this.era,
    required this.games,
    required this.gamesStarted,
    required this.saves,
    required this.inningsPitched,
    required this.hits,
    required this.runs,
    required this.earnedRuns,
    required this.homeRuns,
    required this.walks,
    required this.strikeouts,
    required this.whip,
    required this.avg,
    this.completeGames,
    this.shutouts,
    this.saveOpportunities,
    this.intentionalWalks,
    this.hitBatters,
    this.balks,
    this.wildPitches,
    this.kPer9,
    this.bbPer9,
  });

  factory PitcherStats.fromJson(Map<String, dynamic> json) => PitcherStats(
    wins: json['wins'] ?? 0,
    losses: json['losses'] ?? 0,
    era: json['era'] ?? '0.00',
    games: json['games'] ?? 0,
    gamesStarted: json['gamesStarted'] ?? 0,
    saves: json['saves'] ?? 0,
    inningsPitched: json['inningsPitched'] ?? '0.0',
    hits: json['hits'] ?? 0,
    runs: json['runs'] ?? 0,
    earnedRuns: json['earnedRuns'] ?? 0,
    homeRuns: json['homeRuns'] ?? 0,
    walks: json['walks'] ?? 0,
    strikeouts: json['strikeouts'] ?? 0,
    whip: json['whip'] ?? '0.00',
    avg: json['avg'] ?? '.000',
    completeGames: json['completeGames'],
    shutouts: json['shutouts'],
    saveOpportunities: json['saveOpportunities'],
    intentionalWalks: json['intentionalWalks'],
    hitBatters: json['hitBatters'],
    balks: json['balks'],
    wildPitches: json['wildPitches'],
    kPer9: json['kPer9'],
    bbPer9: json['bbPer9'],
  );
}

// Statcast Hitting Metrics
class StatcastHittingMetrics {
  final double? exitVelocity;      // mph
  final double? maxExitVelocity;   // mph
  final double? launchAngle;       // degrees
  final int? barrels;
  final double? barrelPercent;
  final int? hardHit;
  final double? hardHitPercent;
  final double? launchAngleSweetSpotPercent;
  final double? xBA;               // Expected Batting Average
  final double? xSLG;              // Expected Slugging
  final double? xwOBA;             // Expected wOBA
  final double? wOBA;              // Actual wOBA
  final double? ev50;              // Top 50% EV average
  final double? adjustedEV;        // Park-adjusted EV
  final double? sprintSpeed;       // ft/sec
  final double? sweetSpotPercent;

  StatcastHittingMetrics({
    this.exitVelocity,
    this.maxExitVelocity,
    this.launchAngle,
    this.barrels,
    this.barrelPercent,
    this.hardHit,
    this.hardHitPercent,
    this.launchAngleSweetSpotPercent,
    this.xBA,
    this.xSLG,
    this.xwOBA,
    this.wOBA,
    this.ev50,
    this.adjustedEV,
    this.sprintSpeed,
    this.sweetSpotPercent,
  });

  factory StatcastHittingMetrics.fromJson(Map<String, dynamic> json) =>
      StatcastHittingMetrics(
        exitVelocity: json['exitVelocity']?.toDouble(),
        maxExitVelocity: json['maxExitVelocity']?.toDouble(),
        launchAngle: json['launchAngle']?.toDouble(),
        barrels: json['barrels'],
        barrelPercent: json['barrelPercent']?.toDouble(),
        hardHit: json['hardHit'],
        hardHitPercent: json['hardHitPercent']?.toDouble(),
        launchAngleSweetSpotPercent: json['launchAngleSweetSpotPercent']?.toDouble(),
        xBA: json['xBA']?.toDouble(),
        xSLG: json['xSLG']?.toDouble(),
        xwOBA: json['xwOBA']?.toDouble(),
        wOBA: json['wOBA']?.toDouble(),
        ev50: json['ev50']?.toDouble(),
        adjustedEV: json['adjustedEV']?.toDouble(),
        sprintSpeed: json['sprintSpeed']?.toDouble(),
        sweetSpotPercent: json['sweetSpotPercent']?.toDouble(),
      );
}

// Statcast Pitching Metrics
class StatcastPitchingMetrics {
  final double? pitchVelocity;     // avg mph
  final double? maxPitchVelocity;  // max mph
  final double? inducedVertBreak;  // inches
  final double? horizBreak;        // inches
  final double? activeSpin;        // percentage
  final int? spinRate;             // RPM
  final double? extension;         // feet
  final double? releaseHeight;     // feet
  final double? xERA;              // Expected ERA
  final double? xBA;               // Expected BA against
  final double? xSLG;              // Expected SLG against
  final double? xwOBA;             // Expected wOBA against
  final double? whiffPercent;
  final double? kPercent;
  final double? bbPercent;
  final double? chasePercent;
  final double? cswPercent;        // Called Strikes + Whiffs %

  StatcastPitchingMetrics({
    this.pitchVelocity,
    this.maxPitchVelocity,
    this.inducedVertBreak,
    this.horizBreak,
    this.activeSpin,
    this.spinRate,
    this.extension,
    this.releaseHeight,
    this.xERA,
    this.xBA,
    this.xSLG,
    this.xwOBA,
    this.whiffPercent,
    this.kPercent,
    this.bbPercent,
    this.chasePercent,
    this.cswPercent,
  });

  factory StatcastPitchingMetrics.fromJson(Map<String, dynamic> json) =>
      StatcastPitchingMetrics(
        pitchVelocity: json['pitchVelocity']?.toDouble(),
        maxPitchVelocity: json['maxPitchVelocity']?.toDouble(),
        inducedVertBreak: json['inducedVertBreak']?.toDouble(),
        horizBreak: json['horizBreak']?.toDouble(),
        activeSpin: json['activeSpin']?.toDouble(),
        spinRate: json['spinRate'],
        extension: json['extension']?.toDouble(),
        releaseHeight: json['releaseHeight']?.toDouble(),
        xERA: json['xERA']?.toDouble(),
        xBA: json['xBA']?.toDouble(),
        xSLG: json['xSLG']?.toDouble(),
        xwOBA: json['xwOBA']?.toDouble(),
        whiffPercent: json['whiffPercent']?.toDouble(),
        kPercent: json['kPercent']?.toDouble(),
        bbPercent: json['bbPercent']?.toDouble(),
        chasePercent: json['chasePercent']?.toDouble(),
        cswPercent: json['cswPercent']?.toDouble(),
      );
}

// Fielding Metrics
class FieldingMetrics {
  final int? oaa;                  // Outs Above Average
  final double? fieldingRunValue;
  final double? successRateAdded;
  final double? leadDistance;      // feet
  final double? jump;              // reaction time
  final double? burst;             // acceleration
  final double? routeEfficiency;   // percentage (OF)
  final double? catchProbability;
  final double? armStrength;       // mph
  final double? armRunValue;
  final double? rangeRunValue;
  final double? exchangeTime;      // seconds

  FieldingMetrics({
    this.oaa,
    this.fieldingRunValue,
    this.successRateAdded,
    this.leadDistance,
    this.jump,
    this.burst,
    this.routeEfficiency,
    this.catchProbability,
    this.armStrength,
    this.armRunValue,
    this.rangeRunValue,
    this.exchangeTime,
  });

  factory FieldingMetrics.fromJson(Map<String, dynamic> json) => FieldingMetrics(
    oaa: json['oaa'],
    fieldingRunValue: json['fieldingRunValue']?.toDouble(),
    successRateAdded: json['successRateAdded']?.toDouble(),
    leadDistance: json['leadDistance']?.toDouble(),
    jump: json['jump']?.toDouble(),
    burst: json['burst']?.toDouble(),
    routeEfficiency: json['routeEfficiency']?.toDouble(),
    catchProbability: json['catchProbability']?.toDouble(),
    armStrength: json['armStrength']?.toDouble(),
    armRunValue: json['armRunValue']?.toDouble(),
    rangeRunValue: json['rangeRunValue']?.toDouble(),
    exchangeTime: json['exchangeTime']?.toDouble(),
  );
}

// Catcher-Specific Metrics
class CatcherMetrics {
  final double? popTime;           // seconds
  final double? popTime2B;         // to 2nd base
  final double? popTime3B;         // to 3rd base
  final double? exchangeTime;      // seconds
  final double? armStrength;       // mph
  final double? caughtStealingPercent;
  final double? blocksAboveAverage;
  final double? framingRunValue;
  final double? strikeRate;
  final double? catcherDefense;
  final double? leadDistanceGiven; // feet

  CatcherMetrics({
    this.popTime,
    this.popTime2B,
    this.popTime3B,
    this.exchangeTime,
    this.armStrength,
    this.caughtStealingPercent,
    this.blocksAboveAverage,
    this.framingRunValue,
    this.strikeRate,
    this.catcherDefense,
    this.leadDistanceGiven,
  });

  factory CatcherMetrics.fromJson(Map<String, dynamic> json) => CatcherMetrics(
    popTime: json['popTime']?.toDouble(),
    popTime2B: json['popTime2B']?.toDouble(),
    popTime3B: json['popTime3B']?.toDouble(),
    exchangeTime: json['exchangeTime']?.toDouble(),
    armStrength: json['armStrength']?.toDouble(),
    caughtStealingPercent: json['caughtStealingPercent']?.toDouble(),
    blocksAboveAverage: json['blocksAboveAverage']?.toDouble(),
    framingRunValue: json['framingRunValue']?.toDouble(),
    strikeRate: json['strikeRate']?.toDouble(),
    catcherDefense: json['catcherDefense']?.toDouble(),
    leadDistanceGiven: json['leadDistanceGiven']?.toDouble(),
  );
}
