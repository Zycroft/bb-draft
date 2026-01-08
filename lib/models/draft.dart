// Draft modes
enum DraftMode {
  live('live'),
  untimed('untimed'),
  scheduled('scheduled'),
  timed('timed');

  final String value;
  const DraftMode(this.value);

  static DraftMode fromString(String? value) {
    switch (value) {
      case 'live':
        return DraftMode.live;
      case 'untimed':
        return DraftMode.untimed;
      case 'scheduled':
        return DraftMode.scheduled;
      case 'timed':
        return DraftMode.timed;
      default:
        return DraftMode.live;
    }
  }

  String get displayName {
    switch (this) {
      case DraftMode.live:
        return 'Live';
      case DraftMode.untimed:
        return 'Untimed';
      case DraftMode.scheduled:
        return 'Scheduled';
      case DraftMode.timed:
        return 'Timed';
    }
  }
}

class Draft {
  final String draftId;
  final String leagueId;
  final int seasonYear;
  final DraftMode mode;
  final DraftStatus status;
  final String format;
  final String? scheduledStart;
  final String? actualStart;
  final String? completedAt;
  final int currentRound;
  final int currentPick;
  final int currentOverallPick;
  final int totalRounds;
  final int teamCount;
  final int pickTimer;
  final List<String> draftOrder;
  final OnTheClock? onTheClock;
  final List<DraftPick>? picks;
  final DraftConfiguration configuration;
  final List<SkippedPick> skipQueue;
  final Map<String, int> timeBank;
  final DraftStatistics statistics;

  Draft({
    required this.draftId,
    required this.leagueId,
    this.seasonYear = 2026,
    this.mode = DraftMode.live,
    required this.status,
    required this.format,
    this.scheduledStart,
    this.actualStart,
    this.completedAt,
    required this.currentRound,
    required this.currentPick,
    required this.currentOverallPick,
    required this.totalRounds,
    required this.teamCount,
    required this.pickTimer,
    required this.draftOrder,
    this.onTheClock,
    this.picks,
    DraftConfiguration? configuration,
    List<SkippedPick>? skipQueue,
    Map<String, int>? timeBank,
    DraftStatistics? statistics,
  })  : configuration = configuration ?? DraftConfiguration(),
        skipQueue = skipQueue ?? [],
        timeBank = timeBank ?? {},
        statistics = statistics ?? DraftStatistics();

  factory Draft.fromJson(Map<String, dynamic> json) {
    OnTheClock? onTheClock;
    if (json['onTheClock'] != null) {
      onTheClock = OnTheClock.fromJson(json['onTheClock']);
    }

    List<DraftPick>? picks;
    if (json['picks'] != null && json['picks'] is List) {
      picks = (json['picks'] as List).map((p) => DraftPick.fromJson(p)).toList();
    }

    List<SkippedPick> skipQueue = [];
    if (json['skipQueue'] != null && json['skipQueue'] is List) {
      skipQueue = (json['skipQueue'] as List).map((s) => SkippedPick.fromJson(s)).toList();
    }

    Map<String, int> timeBank = {};
    if (json['timeBank'] != null && json['timeBank'] is Map) {
      (json['timeBank'] as Map).forEach((key, value) {
        timeBank[key] = value is int ? value : int.tryParse(value.toString()) ?? 0;
      });
    }

    return Draft(
      draftId: json['draftId'] ?? '',
      leagueId: json['leagueId'] ?? '',
      seasonYear: json['seasonYear'] ?? 2026,
      mode: DraftMode.fromString(json['mode']),
      status: DraftStatus.fromString(json['status']),
      format: json['format'] ?? 'serpentine',
      scheduledStart: json['scheduledStart'],
      actualStart: json['actualStart'],
      completedAt: json['completedAt'],
      currentRound: json['currentRound'] ?? 1,
      currentPick: json['currentPick'] ?? 1,
      currentOverallPick: json['currentOverallPick'] ?? 1,
      totalRounds: json['totalRounds'] ?? 23,
      teamCount: json['teamCount'] ?? 0,
      pickTimer: json['pickTimer'] ?? 90,
      draftOrder: List<String>.from(json['draftOrder'] ?? []),
      onTheClock: onTheClock,
      picks: picks,
      configuration: json['configuration'] != null
          ? DraftConfiguration.fromJson(json['configuration'])
          : null,
      skipQueue: skipQueue,
      timeBank: timeBank,
      statistics: json['statistics'] != null
          ? DraftStatistics.fromJson(json['statistics'])
          : null,
    );
  }

  int get totalPicks => teamCount * totalRounds;
  bool get isComplete => currentOverallPick > totalPicks;

  List<SkippedPick> get availableCatchUps =>
      skipQueue.where((s) => s.catchUpStatus == 'available').toList();

  int getTeamTimeBank(String teamId) => timeBank[teamId] ?? 0;
}

class DraftConfiguration {
  // Live mode
  final int pickTimer;
  final bool autoPickOnTimeout;
  final String autoPickStrategy;
  final bool pauseEnabled;
  final int maxPauseDuration;
  final int breakBetweenRounds;

  // Untimed mode
  final bool notifyOnTurn;
  final List<int> notifyReminders;
  final bool allowQueuePicks;
  final int maxQueueDepth;

  // Scheduled mode
  final int windowDuration;
  final bool skipOnWindowClose;
  final bool catchUpEnabled;
  final int catchUpWindow;
  final String timezone;

  // Timed mode
  final String clockBehavior;
  final int skipThreshold;
  final String catchUpPolicy;
  final int catchUpTimeLimit;
  final int bonusTime;

  DraftConfiguration({
    this.pickTimer = 90,
    this.autoPickOnTimeout = true,
    this.autoPickStrategy = 'queue',
    this.pauseEnabled = true,
    this.maxPauseDuration = 300,
    this.breakBetweenRounds = 0,
    this.notifyOnTurn = true,
    this.notifyReminders = const [3600, 21600, 86400],
    this.allowQueuePicks = true,
    this.maxQueueDepth = 20,
    this.windowDuration = 120,
    this.skipOnWindowClose = true,
    this.catchUpEnabled = true,
    this.catchUpWindow = 30,
    this.timezone = 'America/New_York',
    this.clockBehavior = 'reset',
    this.skipThreshold = 3,
    this.catchUpPolicy = 'immediate',
    this.catchUpTimeLimit = 60,
    this.bonusTime = 30,
  });

  factory DraftConfiguration.fromJson(Map<String, dynamic> json) {
    return DraftConfiguration(
      pickTimer: json['pickTimer'] ?? 90,
      autoPickOnTimeout: json['autoPickOnTimeout'] ?? true,
      autoPickStrategy: json['autoPickStrategy'] ?? 'queue',
      pauseEnabled: json['pauseEnabled'] ?? true,
      maxPauseDuration: json['maxPauseDuration'] ?? 300,
      breakBetweenRounds: json['breakBetweenRounds'] ?? 0,
      notifyOnTurn: json['notifyOnTurn'] ?? true,
      notifyReminders: List<int>.from(json['notifyReminders'] ?? [3600, 21600, 86400]),
      allowQueuePicks: json['allowQueuePicks'] ?? true,
      maxQueueDepth: json['maxQueueDepth'] ?? 20,
      windowDuration: json['windowDuration'] ?? 120,
      skipOnWindowClose: json['skipOnWindowClose'] ?? true,
      catchUpEnabled: json['catchUpEnabled'] ?? true,
      catchUpWindow: json['catchUpWindow'] ?? 30,
      timezone: json['timezone'] ?? 'America/New_York',
      clockBehavior: json['clockBehavior'] ?? 'reset',
      skipThreshold: json['skipThreshold'] ?? 3,
      catchUpPolicy: json['catchUpPolicy'] ?? 'immediate',
      catchUpTimeLimit: json['catchUpTimeLimit'] ?? 60,
      bonusTime: json['bonusTime'] ?? 30,
    );
  }

  Map<String, dynamic> toJson() => {
    'pickTimer': pickTimer,
    'autoPickOnTimeout': autoPickOnTimeout,
    'autoPickStrategy': autoPickStrategy,
    'pauseEnabled': pauseEnabled,
    'maxPauseDuration': maxPauseDuration,
    'breakBetweenRounds': breakBetweenRounds,
    'notifyOnTurn': notifyOnTurn,
    'notifyReminders': notifyReminders,
    'allowQueuePicks': allowQueuePicks,
    'maxQueueDepth': maxQueueDepth,
    'windowDuration': windowDuration,
    'skipOnWindowClose': skipOnWindowClose,
    'catchUpEnabled': catchUpEnabled,
    'catchUpWindow': catchUpWindow,
    'timezone': timezone,
    'clockBehavior': clockBehavior,
    'skipThreshold': skipThreshold,
    'catchUpPolicy': catchUpPolicy,
    'catchUpTimeLimit': catchUpTimeLimit,
    'bonusTime': bonusTime,
  };
}

class SkippedPick {
  final String skipId;
  final String draftId;
  final String teamId;
  final int round;
  final int pickInRound;
  final int overallPick;
  final String skippedAt;
  final String reason;
  final String originalDeadline;
  final bool catchUpEligible;
  final String? catchUpDeadline;
  final String catchUpStatus;
  final String? catchUpCompletedAt;
  final String? playerId;

  SkippedPick({
    required this.skipId,
    required this.draftId,
    required this.teamId,
    required this.round,
    required this.pickInRound,
    required this.overallPick,
    required this.skippedAt,
    required this.reason,
    required this.originalDeadline,
    required this.catchUpEligible,
    this.catchUpDeadline,
    required this.catchUpStatus,
    this.catchUpCompletedAt,
    this.playerId,
  });

  factory SkippedPick.fromJson(Map<String, dynamic> json) => SkippedPick(
    skipId: json['skipId'] ?? '',
    draftId: json['draftId'] ?? '',
    teamId: json['teamId'] ?? '',
    round: json['round'] ?? 0,
    pickInRound: json['pickInRound'] ?? 0,
    overallPick: json['overallPick'] ?? 0,
    skippedAt: json['skippedAt'] ?? '',
    reason: json['reason'] ?? 'timer_expired',
    originalDeadline: json['originalDeadline'] ?? '',
    catchUpEligible: json['catchUpEligible'] ?? true,
    catchUpDeadline: json['catchUpDeadline'],
    catchUpStatus: json['catchUpStatus'] ?? 'pending',
    catchUpCompletedAt: json['catchUpCompletedAt'],
    playerId: json['playerId'],
  );

  bool get isAvailable => catchUpStatus == 'available';
  bool get isCompleted => catchUpStatus == 'completed';
  bool get isForfeited => catchUpStatus == 'forfeited';
}

class DraftStatistics {
  final int fastestPick;
  final int slowestPick;
  final int averagePick;
  final int autoPickCount;
  final int skipCount;
  final int catchUpCount;

  DraftStatistics({
    this.fastestPick = 0,
    this.slowestPick = 0,
    this.averagePick = 0,
    this.autoPickCount = 0,
    this.skipCount = 0,
    this.catchUpCount = 0,
  });

  factory DraftStatistics.fromJson(Map<String, dynamic> json) => DraftStatistics(
    fastestPick: json['fastestPick'] ?? 0,
    slowestPick: json['slowestPick'] ?? 0,
    averagePick: json['averagePick'] ?? 0,
    autoPickCount: json['autoPickCount'] ?? 0,
    skipCount: json['skipCount'] ?? 0,
    catchUpCount: json['catchUpCount'] ?? 0,
  );
}

enum DraftStatus {
  scheduled('scheduled'),
  inProgress('in_progress'),
  paused('paused'),
  completed('completed');

  final String value;
  const DraftStatus(this.value);

  static DraftStatus fromString(String? value) {
    switch (value) {
      case 'scheduled':
        return DraftStatus.scheduled;
      case 'in_progress':
        return DraftStatus.inProgress;
      case 'paused':
        return DraftStatus.paused;
      case 'completed':
        return DraftStatus.completed;
      default:
        return DraftStatus.scheduled;
    }
  }

  String get displayName {
    switch (this) {
      case DraftStatus.scheduled:
        return 'Scheduled';
      case DraftStatus.inProgress:
        return 'In Progress';
      case DraftStatus.paused:
        return 'Paused';
      case DraftStatus.completed:
        return 'Completed';
    }
  }
}

class OnTheClock {
  final String teamId;
  final String clockStarted;
  final String clockExpires;

  OnTheClock({
    required this.teamId,
    required this.clockStarted,
    required this.clockExpires,
  });

  factory OnTheClock.fromJson(Map<String, dynamic> json) => OnTheClock(
    teamId: json['teamId'] ?? '',
    clockStarted: json['clockStarted'] ?? '',
    clockExpires: json['clockExpires'] ?? '',
  );

  int get timeRemaining {
    final expires = DateTime.parse(clockExpires);
    final remaining = expires.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }
}

class DraftPick {
  final String draftId;
  final int overallPick;
  final int round;
  final int pickInRound;
  final String teamId;
  final String? originalTeamId;
  final String playerId;
  final String playerName;
  final String position;
  final String mlbTeam;
  final String timestamp;
  final int pickDuration;
  final bool wasAutoPick;
  final bool wasCatchUp;
  final bool wasFromQueue;
  final int? queuePosition;

  DraftPick({
    required this.draftId,
    required this.overallPick,
    required this.round,
    required this.pickInRound,
    required this.teamId,
    this.originalTeamId,
    required this.playerId,
    required this.playerName,
    required this.position,
    required this.mlbTeam,
    required this.timestamp,
    required this.pickDuration,
    required this.wasAutoPick,
    this.wasCatchUp = false,
    this.wasFromQueue = false,
    this.queuePosition,
  });

  factory DraftPick.fromJson(Map<String, dynamic> json) => DraftPick(
    draftId: json['draftId'] ?? '',
    overallPick: json['overallPick'] ?? 0,
    round: json['round'] ?? 0,
    pickInRound: json['pickInRound'] ?? 0,
    teamId: json['teamId'] ?? '',
    originalTeamId: json['originalTeamId'],
    playerId: json['playerId'] ?? '',
    playerName: json['playerName'] ?? '',
    position: json['position'] ?? '',
    mlbTeam: json['mlbTeam'] ?? '',
    timestamp: json['timestamp'] ?? '',
    pickDuration: json['pickDuration'] ?? 0,
    wasAutoPick: json['wasAutoPick'] ?? false,
    wasCatchUp: json['wasCatchUp'] ?? false,
    wasFromQueue: json['wasFromQueue'] ?? false,
    queuePosition: json['queuePosition'],
  );

  bool get isTraded => originalTeamId != null && originalTeamId != teamId;
}
