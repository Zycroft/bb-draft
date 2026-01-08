// User types
export interface User {
  userId: string;
  email: string;
  displayName: string;
  photoUrl?: string;
  createdAt: string;
  updatedAt: string;
  preferences?: UserPreferences;
}

export interface UserPreferences {
  notifications: {
    draftReminders: boolean;
    pickNotifications: boolean;
    emailDigest: 'daily' | 'weekly' | 'never';
  };
  timezone: string;
}

// League types
export interface League {
  leagueId: string;
  name: string;
  commissionerId: string;
  inviteCode: string;
  status: LeagueStatus;
  settings: LeagueSettings;
  season: number;
  createdAt: string;
  updatedAt: string;
}

export type LeagueStatus = 'pre_draft' | 'drafting' | 'in_season' | 'completed';

export interface LeagueSettings {
  maxTeams: number;
  draftFormat: DraftFormat;
  scoringType: ScoringType;
  pickTimer: number;
  rounds: number;
  tradePicksEnabled: boolean;
  roster: RosterPositions;
}

export type DraftFormat = 'serpentine' | 'straight';
export type ScoringType = 'head_to_head' | 'rotisserie' | 'points';

export interface RosterPositions {
  C: number;
  '1B': number;
  '2B': number;
  '3B': number;
  SS: number;
  OF: number;
  UTIL: number;
  SP: number;
  RP: number;
  P?: number;
  BN: number;
  IR?: number;
}

// Team types
export interface Team {
  teamId: string;
  leagueId: string;
  ownerId: string;
  name: string;
  abbreviation?: string;
  draftPosition?: number;
  createdAt: string;
  updatedAt: string;
  roster: RosterPlayer[];
  draftQueue: string[];
}

export interface RosterPlayer {
  playerId: string;
  position: string;
  acquisitionType: 'draft' | 'trade' | 'free_agent';
  acquisitionDate: string;
}

// Draft types
export type DraftMode = 'live' | 'untimed' | 'scheduled' | 'timed';
export type DraftStatus = 'scheduled' | 'in_progress' | 'paused' | 'completed';
export type AutoPickStrategy = 'queue' | 'adp' | 'positional';
export type ClockBehavior = 'reset' | 'accumulate' | 'carryover';
export type CatchUpPolicy = 'immediate' | 'end_of_round' | 'end_of_draft';

export interface Draft {
  draftId: string;
  leagueId: string;
  seasonYear: number;
  mode: DraftMode;
  status: DraftStatus;
  format: DraftFormat;
  scheduledStart?: string;
  actualStart?: string;
  completedAt?: string;
  currentRound: number;
  currentPick: number;
  currentOverallPick: number;
  totalRounds: number;
  teamCount: number;
  pickTimer: number;
  draftOrder: string[];
  onTheClock?: OnTheClock;
  configuration: DraftConfiguration;
  skipQueue: SkippedPick[];
  timeBank: Record<string, number>; // teamId -> seconds banked
  statistics: DraftStatistics;
  createdAt: string;
  updatedAt: string;
}

export interface DraftConfiguration {
  // Live mode settings
  pickTimer: number;
  autoPickOnTimeout: boolean;
  autoPickStrategy: AutoPickStrategy;
  pauseEnabled: boolean;
  maxPauseDuration: number;
  breakBetweenRounds: number;

  // Untimed mode settings
  notifyOnTurn: boolean;
  notifyReminders: number[]; // intervals in seconds
  allowQueuePicks: boolean;
  maxQueueDepth: number;

  // Scheduled mode settings
  windowDuration: number; // default minutes per pick
  windowSchedule?: WindowSchedule[];
  skipOnWindowClose: boolean;
  catchUpEnabled: boolean;
  catchUpWindow: number;
  blackoutPeriods?: BlackoutPeriod[];
  timezone: string;

  // Timed mode settings
  draftWindow?: DraftWindow;
  clockBehavior: ClockBehavior;
  skipThreshold: number;
  catchUpPolicy: CatchUpPolicy;
  catchUpTimeLimit: number;
  bonusTime: number;
}

export interface WindowSchedule {
  rounds: number[];
  windowDuration: number;
  description?: string;
}

export interface BlackoutPeriod {
  start: string; // HH:MM format
  end: string;
  timezone: string;
  description?: string;
}

export interface DraftWindow {
  days: string[]; // monday, tuesday, etc.
  startTime: string; // HH:MM
  endTime: string;
  timezone: string;
}

export interface OnTheClock {
  teamId: string;
  teamName?: string;
  clockStarted: string;
  clockExpires: string;
  timeRemaining?: number;
  isPaused?: boolean;
}

export interface DraftStatistics {
  fastestPick: number;
  slowestPick: number;
  averagePick: number;
  autoPickCount: number;
  skipCount: number;
  catchUpCount: number;
}

// Skip and Catch-Up types
export interface SkippedPick {
  skipId: string;
  draftId: string;
  teamId: string;
  round: number;
  pickInRound: number;
  overallPick: number;
  skippedAt: string;
  reason: 'timer_expired' | 'disconnected' | 'manual';
  originalDeadline: string;
  catchUpEligible: boolean;
  catchUpDeadline?: string;
  catchUpStatus: 'pending' | 'available' | 'completed' | 'forfeited';
  catchUpCompletedAt?: string;
  playerId?: string; // Set when catch-up pick is made
}

export interface CatchUpQueue {
  draftId: string;
  queue: CatchUpEntry[];
  activeCatchUp?: ActiveCatchUp;
}

export interface CatchUpEntry {
  teamId: string;
  pendingCatchUps: SkippedPick[];
  isOnline: boolean;
  lastNotified?: string;
  consecutiveSkips: number;
}

export interface ActiveCatchUp {
  teamId: string;
  round: number;
  pickInRound: number;
  overallPick: number;
  clockStarted: string;
  clockRemaining: number;
}

export interface DraftPick {
  draftId: string;
  overallPick: number;
  round: number;
  pickInRound: number;
  teamId: string;
  originalTeamId?: string; // For traded picks
  playerId: string;
  playerName: string;
  position: string;
  mlbTeam: string;
  timestamp: string;
  pickDuration: number;
  wasAutoPick: boolean;
  wasCatchUp: boolean;
  wasFromQueue: boolean;
  queuePosition?: number;
}

// Player Pool types
export interface PlayerPool {
  poolId: string;
  leagueId: string;
  seasonYear: number;
  configuredBy: string;
  configuredAt: string;
  lockedAt?: string;
  categories: PlayerPoolCategories;
  customAdditions: CustomPlayer[];
  customExclusions: CustomExclusion[];
  totalEligiblePlayers: number;
}

export interface PlayerPoolCategories {
  mlbFreeAgents: PlayerPoolCategory;
  newMlbPlayers: PlayerPoolCategory;
  existingMlbPlayers: PlayerPoolCategory;
  milbProspects: PlayerPoolCategory;
  internationalSignees: PlayerPoolCategory;
  injuredPlayers: PlayerPoolCategory;
}

export interface PlayerPoolCategory {
  included: boolean;
  filter?: Record<string, any>;
}

export interface CustomPlayer {
  playerId: string;
  name: string;
  reason: string;
  addedBy: string;
  addedAt: string;
}

export interface CustomExclusion {
  playerId: string;
  name: string;
  reason: string;
  excludedBy: string;
  excludedAt: string;
}

// Draft Grid Cell types
export type GridCellState = 'empty' | 'on_clock' | 'queued' | 'selected' | 'skipped' | 'catch_up' | 'traded' | 'removed';

export interface GridCell {
  cellId: string;
  round: number;
  pickInRound: number;
  overallPick: number;
  originalOwner: string;
  currentOwner: string;
  state: GridCellState;
  player?: {
    playerId: string;
    name: string;
    position: string;
    mlbTeam: string;
    headshotUrl?: string;
  };
  pickTimestamp?: string;
  pickDuration?: number;
  isTraded: boolean;
  tradeInfo?: {
    tradeId: string;
    fromTeam: string;
  };
}

export interface DraftGrid {
  gridId: string;
  leagueId: string;
  seasonYear: number;
  draftFormat: DraftFormat;
  totalRounds: number;
  teamCount: number;
  currentRound: number;
  currentPick: number;
  currentOverallPick: number;
  draftStatus: DraftStatus;
  onTheClock?: OnTheClock;
  teams: DraftGridTeam[];
  rounds: DraftGridRound[];
  lastUpdated: string;
}

export interface DraftGridTeam {
  teamId: string;
  teamName: string;
  abbreviation?: string;
  draftPosition: number;
  logo?: string;
  isConnected: boolean;
}

export interface DraftGridRound {
  roundNumber: number;
  status: 'pending' | 'in_progress' | 'completed';
  picks: GridCell[];
}

// Player types
export interface Player {
  playerId: string;
  mlbId: number;
  fullName: string;
  firstName: string;
  lastName: string;
  primaryPosition: string;
  mlbTeam: string;
  mlbTeamId: number;
  jerseyNumber?: string;
  batSide: string;
  pitchHand: string;
  birthDate?: string;
  height?: string;
  weight?: number;
  active: boolean;
  stats?: PlayerStats;
  lastUpdated: string;
  expiresAt?: number;
}

export interface PlayerStats {
  batting?: BatterStats;
  pitching?: PitcherStats;
}

export interface BatterStats {
  gamesPlayed: number;
  atBats: number;
  runs: number;
  hits: number;
  doubles: number;
  triples: number;
  homeRuns: number;
  rbi: number;
  stolenBases: number;
  caughtStealing: number;
  walks: number;
  strikeouts: number;
  avg: string;
  obp: string;
  slg: string;
  ops: string;
}

export interface PitcherStats {
  wins: number;
  losses: number;
  era: string;
  games: number;
  gamesStarted: number;
  saves: number;
  inningsPitched: string;
  hits: number;
  runs: number;
  earnedRuns: number;
  homeRuns: number;
  walks: number;
  strikeouts: number;
  whip: string;
  avg: string;
}

// API Response types
export interface PaginatedResponse<T> {
  items: T[];
  count: number;
  lastKey?: string;
}

export interface ApiError {
  error: string;
  message: string;
  details?: any;
}

// User Roles
export type UserRole = 'commissioner' | 'deputy_commissioner' | 'team_owner' | 'spectator';

export interface LeagueMembership {
  leagueId: string;
  userId: string;
  teamId?: string;
  role: UserRole;
  permissions?: string[];
  joinedAt: string;
}

// Draft Order
export interface DraftOrder {
  leagueId: string;
  seasonYear: number;
  orderMethod: 'manual' | 'random' | 'lottery' | 'standings';
  serpentine: boolean;
  order: DraftOrderEntry[];
  lockedAt?: string;
  lastModified: string;
  modifiedBy: string;
  status: 'unlocked' | 'locked';
}

export interface DraftOrderEntry {
  position: number;
  teamId: string;
  teamName: string;
}

// Pick Trading
export interface Trade {
  tradeId: string;
  leagueId: string;
  status: TradeStatus;
  proposedAt: string;
  proposingTeam: TradeParty;
  receivingTeam: TradeParty;
  commissionerApproval?: {
    approved: boolean;
    reviewedAt: string;
    reviewedBy: string;
    notes?: string;
  };
  executedAt?: string;
  cancelledAt?: string;
  expiresAt?: string;
}

export type TradeStatus = 'pending' | 'accepted' | 'rejected' | 'executed' | 'cancelled' | 'expired';

export interface TradeParty {
  teamId: string;
  teamName?: string;
  accepted: boolean;
  sending: TradeAsset[];
  receiving: TradeAsset[];
}

export interface TradeAsset {
  type: 'pick' | 'player';
  playerId?: string;
  playerName?: string;
  seasonYear?: number;
  round?: number;
  originalOwner?: string;
}

// Pick Status
export type PickStatus = 'available' | 'selected' | 'traded' | 'removed' | 'forfeited' | 'compensatory';

export interface PickSlot {
  pickId: string;
  leagueId: string;
  seasonYear: number;
  round: number;
  pickNumber: number;
  overallPick: number;
  originalOwner: string;
  currentOwner: string;
  status: PickStatus;
  statusHistory: PickStatusChange[];
  player?: {
    playerId: string;
    playerName: string;
    position: string;
    mlbTeam: string;
  };
  notes?: string;
}

export interface PickStatusChange {
  status: PickStatus;
  timestamp: string;
  modifiedBy: string;
  tradeId?: string;
  reason?: string;
}

// Team Settings (extended)
export interface TeamSettings {
  teamName: string;
  abbreviation?: string;
  logo?: string;
  colors?: {
    primary: string;
    secondary: string;
  };
  timezone?: string;
  isPublicProfile?: boolean;
}

export interface TeamPreferences {
  notifications: {
    draftReminders: boolean;
    pickNotifications: boolean;
    tradeProposals: boolean;
    leagueAnnouncements: boolean;
    emailDigest: 'none' | 'daily' | 'weekly';
    pushEnabled: boolean;
    soundEnabled: boolean;
  };
  draft: {
    autoPickEnabled: boolean;
    autoPickStrategy: 'queue' | 'adp' | 'positional_need';
    positionPriority: string[];
    excludedPlayers: string[];
  };
}

// Draft Finalization
export interface DraftFinalization {
  finalizationId: string;
  leagueId: string;
  seasonYear: number;
  status: 'pending_review' | 'finalized';
  draftCompletedAt: string;
  reviewPeriodEnd?: string;
  finalizedAt?: string;
  finalizedBy?: string;
  totalPicks: number;
  teamsParticipated: number;
  archiveId?: string;
}

// Archive
export interface DraftArchive {
  archiveId: string;
  leagueId: string;
  leagueName: string;
  seasonYear: number;
  createdAt: string;
  draftFormat: DraftFormat;
  teamCount: number;
  totalRounds: number;
  statistics: {
    fastestPick: number;
    slowestPick: number;
    averagePickTime: number;
    autoPickCount: number;
  };
  isLocked: boolean;
  accessLevel: 'public' | 'league_members' | 'participants_only' | 'commissioner_only';
}

// Commissioner Actions (for audit log)
export interface CommissionerAction {
  actionId: string;
  leagueId: string;
  actionType: string;
  performedBy: string;
  targetEntity?: string;
  details: Record<string, any>;
  timestamp: string;
}

// ============================================
// Encyclopedia & Historical Statistics Types
// ============================================

// Season Import
export type SeasonImportStatus = 'complete' | 'partial' | 'pending';
export type DataSource = 'manual' | 'api' | 'file';

export interface ImportedSeason {
  seasonId: string;
  leagueId: string;
  year: number;
  importDate: string;
  dataSource: DataSource;
  status: SeasonImportStatus;
  metadata: {
    playerCount: number;
    teamCount: number;
    gamesPlayed: number;
    weeksPlayed: number;
  };
  importedBy: string;
}

// Leaderboard Configuration
export type LeaderboardType = 'seasonal' | 'career' | 'custom_range';
export type SortDirection = 'asc' | 'desc';

export interface LeaderboardConfig {
  displayCount: number; // 5, 10, 25, 50, 100, or -1 for all
  leaderboardType: LeaderboardType;
  sortDirection: SortDirection;
  minimumQualifier?: MinimumQualifier;
  playerSearch?: string;
  seasonYear?: number;
  startYear?: number;
  endYear?: number;
}

export interface MinimumQualifier {
  statType: string;
  minValue: number;
  perGame?: boolean;
}

// Player Statistics for Encyclopedia
export interface PlayerSeasonStats {
  playerId: string;
  playerName: string;
  leagueId: string;
  seasonYear: number;
  teamId: string;
  teamName: string;
  batting?: BattingSeasonStats;
  pitching?: PitchingSeasonStats;
}

export interface BattingSeasonStats {
  gamesPlayed: number;
  atBats: number;
  runs: number;
  hits: number;
  doubles: number;
  triples: number;
  homeRuns: number;
  rbi: number;
  stolenBases: number;
  caughtStealing: number;
  walks: number;
  strikeouts: number;
  totalBases: number;
  avg: number;
  obp: number;
  slg: number;
  ops: number;
}

export interface PitchingSeasonStats {
  wins: number;
  losses: number;
  era: number;
  games: number;
  gamesStarted: number;
  completeGames: number;
  shutouts: number;
  saves: number;
  holds: number;
  inningsPitched: number;
  hits: number;
  runs: number;
  earnedRuns: number;
  homeRuns: number;
  walks: number;
  strikeouts: number;
  whip: number;
  k9: number;
  bb9: number;
  kbb: number;
  winPct: number;
}

// Career Statistics
export interface PlayerCareerStats {
  playerId: string;
  playerName: string;
  leagueId: string;
  seasonsPlayed: number;
  teams: string[];
  isActive: boolean;
  batting?: BattingCareerStats;
  pitching?: PitchingCareerStats;
  seasonBests: SeasonBests;
  rankings: CareerRankings;
}

export interface BattingCareerStats extends BattingSeasonStats {
  seasons: number;
  avgPerSeason: {
    gamesPlayed: number;
    homeRuns: number;
    rbi: number;
    runs: number;
    stolenBases: number;
  };
}

export interface PitchingCareerStats extends PitchingSeasonStats {
  seasons: number;
  avgPerSeason: {
    wins: number;
    strikeouts: number;
    saves: number;
    inningsPitched: number;
  };
}

export interface SeasonBests {
  [statCode: string]: {
    value: number;
    year: number;
  };
}

export interface CareerRankings {
  [statCode: string]: number;
}

// Leaderboard Entry
export interface LeaderboardEntry {
  rank: number;
  playerId: string;
  playerName: string;
  teamId?: string;
  teamName?: string;
  teams?: string[];
  seasons?: number;
  value: number;
  previousRank?: number;
  trend?: 'up' | 'down' | 'same' | 'new';
}

export interface Leaderboard {
  leaderboardId: string;
  leagueId: string;
  statCategory: string;
  statCode: string;
  playerType: 'batter' | 'pitcher';
  leaderboardType: LeaderboardType;
  seasonYear?: number;
  entries: LeaderboardEntry[];
  totalEntries: number;
  minimumQualifier?: MinimumQualifier;
  generatedAt: string;
}

// MLB vs League Comparison
export interface StatComparison {
  mlb: number;
  league: number;
  difference: number;
  percentVariance: number;
}

export interface BattingComparison {
  avg?: StatComparison;
  hr?: StatComparison;
  rbi?: StatComparison;
  runs?: StatComparison;
  sb?: StatComparison;
  hits?: StatComparison;
  walks?: StatComparison;
  ops?: StatComparison;
}

export interface PitchingComparison {
  era?: StatComparison;
  wins?: StatComparison;
  strikeouts?: StatComparison;
  saves?: StatComparison;
  whip?: StatComparison;
  ip?: StatComparison;
}

export interface PlayerComparison {
  comparisonId: string;
  playerId: string;
  playerName: string;
  leagueId: string;
  seasonYear?: number;
  comparisonType: 'single_season' | 'career' | 'season_range';
  batting?: BattingComparison;
  pitching?: PitchingComparison;
  matchScore: number;
  consistencyRating: 'A' | 'B' | 'C' | 'D' | 'F';
  generatedAt: string;
}

// Team Historical Statistics
export interface TeamHistoricalStats {
  teamId: string;
  teamName: string;
  leagueId: string;
  allTime: {
    regularSeason: TeamRegularSeasonRecord;
    postseason: TeamPostseasonRecord;
    championships: TeamChampionshipRecord;
  };
  seasons: TeamSeasonRecord[];
  dynastyScore: number;
}

export interface TeamRegularSeasonRecord {
  wins: number;
  losses: number;
  winningPercentage: number;
  gamesPlayed: number;
  pointsFor: number;
  pointsAgainst: number;
  pointDifferential: number;
}

export interface TeamPostseasonRecord {
  appearances: number;
  wins: number;
  losses: number;
  winningPercentage: number;
}

export interface TeamChampionshipRecord {
  appearances: number;
  wins: number;
  losses: number;
  winningPercentage: number;
  years: number[];
}

export interface TeamSeasonRecord {
  year: number;
  wins: number;
  losses: number;
  winningPercentage: number;
  standingsPosition: number;
  playoffResult?: string;
  champion: boolean;
  pointsFor: number;
  pointsAgainst: number;
}

// Team Leaderboard
export interface TeamLeaderboardEntry {
  rank: number;
  teamId: string;
  teamName: string;
  value: number;
  secondaryValue?: number;
  championships?: number;
  playoffAppearances?: number;
}

export interface TeamLeaderboard {
  leaderboardId: string;
  leagueId: string;
  category: 'regular_season' | 'postseason' | 'championships' | 'offensive' | 'consistency';
  statCode: string;
  entries: TeamLeaderboardEntry[];
  generatedAt: string;
}

// Encyclopedia Dashboard Summary
export interface EncyclopediaSummary {
  leagueId: string;
  totalSeasons: number;
  totalPlayers: number;
  totalTeams: number;
  currentSeasonYear: number;
  importedSeasons: number[];
  topBattingLeaders: {
    avg: LeaderboardEntry[];
    hr: LeaderboardEntry[];
    rbi: LeaderboardEntry[];
  };
  topPitchingLeaders: {
    era: LeaderboardEntry[];
    wins: LeaderboardEntry[];
    so: LeaderboardEntry[];
  };
  teamStandings: TeamLeaderboardEntry[];
  lastUpdated: string;
}

// Stat Category Definition
export interface StatCategory {
  code: string;
  name: string;
  description: string;
  playerType: 'batter' | 'pitcher';
  sortDirection: SortDirection;
  minimumQualifier?: MinimumQualifier;
  decimalPlaces: number;
  isRate: boolean;
}

// Predefined stat categories
export const BATTING_STAT_CATEGORIES: StatCategory[] = [
  { code: 'AVG', name: 'Batting Average', description: 'Hits divided by at-bats', playerType: 'batter', sortDirection: 'desc', minimumQualifier: { statType: 'PA', minValue: 3.1, perGame: true }, decimalPlaces: 3, isRate: true },
  { code: 'HR', name: 'Home Runs', description: 'Total home runs', playerType: 'batter', sortDirection: 'desc', decimalPlaces: 0, isRate: false },
  { code: 'RBI', name: 'Runs Batted In', description: 'Total RBIs', playerType: 'batter', sortDirection: 'desc', decimalPlaces: 0, isRate: false },
  { code: 'R', name: 'Runs Scored', description: 'Total runs', playerType: 'batter', sortDirection: 'desc', decimalPlaces: 0, isRate: false },
  { code: 'H', name: 'Hits', description: 'Total hits', playerType: 'batter', sortDirection: 'desc', decimalPlaces: 0, isRate: false },
  { code: '2B', name: 'Doubles', description: 'Total doubles', playerType: 'batter', sortDirection: 'desc', decimalPlaces: 0, isRate: false },
  { code: '3B', name: 'Triples', description: 'Total triples', playerType: 'batter', sortDirection: 'desc', decimalPlaces: 0, isRate: false },
  { code: 'SB', name: 'Stolen Bases', description: 'Total stolen bases', playerType: 'batter', sortDirection: 'desc', decimalPlaces: 0, isRate: false },
  { code: 'OBP', name: 'On-Base Percentage', description: 'On-base percentage', playerType: 'batter', sortDirection: 'desc', minimumQualifier: { statType: 'PA', minValue: 3.1, perGame: true }, decimalPlaces: 3, isRate: true },
  { code: 'SLG', name: 'Slugging Percentage', description: 'Slugging percentage', playerType: 'batter', sortDirection: 'desc', minimumQualifier: { statType: 'PA', minValue: 3.1, perGame: true }, decimalPlaces: 3, isRate: true },
  { code: 'OPS', name: 'OPS', description: 'On-base plus slugging', playerType: 'batter', sortDirection: 'desc', minimumQualifier: { statType: 'PA', minValue: 3.1, perGame: true }, decimalPlaces: 3, isRate: true },
  { code: 'BB', name: 'Walks', description: 'Total walks', playerType: 'batter', sortDirection: 'desc', decimalPlaces: 0, isRate: false },
  { code: 'TB', name: 'Total Bases', description: 'Total bases', playerType: 'batter', sortDirection: 'desc', decimalPlaces: 0, isRate: false },
  { code: 'G', name: 'Games Played', description: 'Games played', playerType: 'batter', sortDirection: 'desc', decimalPlaces: 0, isRate: false },
  { code: 'AB', name: 'At Bats', description: 'Total at-bats', playerType: 'batter', sortDirection: 'desc', decimalPlaces: 0, isRate: false },
];

export const PITCHING_STAT_CATEGORIES: StatCategory[] = [
  { code: 'ERA', name: 'Earned Run Average', description: 'Earned runs per 9 innings', playerType: 'pitcher', sortDirection: 'asc', minimumQualifier: { statType: 'IP', minValue: 1, perGame: true }, decimalPlaces: 2, isRate: true },
  { code: 'W', name: 'Wins', description: 'Total wins', playerType: 'pitcher', sortDirection: 'desc', decimalPlaces: 0, isRate: false },
  { code: 'SO', name: 'Strikeouts', description: 'Total strikeouts', playerType: 'pitcher', sortDirection: 'desc', decimalPlaces: 0, isRate: false },
  { code: 'SV', name: 'Saves', description: 'Total saves', playerType: 'pitcher', sortDirection: 'desc', decimalPlaces: 0, isRate: false },
  { code: 'WHIP', name: 'WHIP', description: 'Walks + hits per inning', playerType: 'pitcher', sortDirection: 'asc', minimumQualifier: { statType: 'IP', minValue: 1, perGame: true }, decimalPlaces: 2, isRate: true },
  { code: 'IP', name: 'Innings Pitched', description: 'Total innings', playerType: 'pitcher', sortDirection: 'desc', decimalPlaces: 1, isRate: false },
  { code: 'WPCT', name: 'Winning Percentage', description: 'Win percentage', playerType: 'pitcher', sortDirection: 'desc', minimumQualifier: { statType: 'decisions', minValue: 10, perGame: false }, decimalPlaces: 3, isRate: true },
  { code: 'CG', name: 'Complete Games', description: 'Complete games', playerType: 'pitcher', sortDirection: 'desc', decimalPlaces: 0, isRate: false },
  { code: 'SHO', name: 'Shutouts', description: 'Shutouts', playerType: 'pitcher', sortDirection: 'desc', decimalPlaces: 0, isRate: false },
  { code: 'GS', name: 'Games Started', description: 'Games started', playerType: 'pitcher', sortDirection: 'desc', decimalPlaces: 0, isRate: false },
  { code: 'HLD', name: 'Holds', description: 'Total holds', playerType: 'pitcher', sortDirection: 'desc', decimalPlaces: 0, isRate: false },
  { code: 'K9', name: 'K/9', description: 'Strikeouts per 9 innings', playerType: 'pitcher', sortDirection: 'desc', minimumQualifier: { statType: 'IP', minValue: 1, perGame: true }, decimalPlaces: 2, isRate: true },
  { code: 'BB9', name: 'BB/9', description: 'Walks per 9 innings', playerType: 'pitcher', sortDirection: 'asc', minimumQualifier: { statType: 'IP', minValue: 1, perGame: true }, decimalPlaces: 2, isRate: true },
  { code: 'KBB', name: 'K/BB', description: 'Strikeout to walk ratio', playerType: 'pitcher', sortDirection: 'desc', minimumQualifier: { statType: 'IP', minValue: 1, perGame: true }, decimalPlaces: 2, isRate: true },
];
