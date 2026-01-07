# Flutter MLB Player Draft Eligibility Web App

## Overview
Create a Flutter web application that displays MLB baseball players with their complete statistics, organized into separate tabs for batters and pitchers, with draft eligibility status controls.

## Requirements

### Tab Structure
- **Batters Tab**: Display all position players (non-pitchers)
- **Pitchers Tab**: Display all pitchers

### Data Sources

#### MLB Lookup Service API (Basic Stats)
- Base URL: `http://lookup-service-prod.mlb.com`
- Relevant endpoints:
  - `/json/named.search_player_all.bam?sport_code='mlb'&name_part='%25'` - Search all players
  - `/json/named.player_info.bam?sport_code='mlb'&player_id={id}` - Individual player info
  - `/json/named.sport_hitting_tm.bam?league_list_id='mlb'&game_type='R'&season={year}&player_id={id}` - Batter stats
  - `/json/named.sport_pitching_tm.bam?league_list_id='mlb'&game_type='R'&season={year}&player_id={id}` - Pitcher stats

#### FanGraphs (Scouting Grades & fWAR)
- Base URL: `https://www.fangraphs.com`
- Data available:
  - 20-80 scouting scale ratings (Hit, Game Power, Raw Power, Speed, Field, Arm)
  - fWAR (Wins Above Replacement using FIP-based methodology)
  - Prospect rankings and scouting reports

#### Baseball-Reference (bWAR)
- Base URL: `https://www.baseball-reference.com`
- Data available:
  - bWAR (Wins Above Replacement using RA9-based methodology)
  - Historical player statistics
  - Career and season WAR breakdowns

#### Baseball Savant / Statcast (Advanced Metrics)
- Base URL: `https://baseballsavant.mlb.com`
- API endpoints:
  - `/statcast_search` - Search Statcast data
  - `/leaderboard/expected_statistics` - xBA, xSLG, xwOBA leaderboards
  - `/leaderboard/sprint_speed` - Sprint speed data
  - `/leaderboard/outs_above_average` - Fielding OAA data
  - `/leaderboard/poptime` - Catcher pop time data
  - `/leaderboard/arm-strength` - Arm strength data
  - `/leaderboard/catcher-blocking` - Catcher blocking metrics
  - `/leaderboard/catcher-framing` - Catcher framing metrics
- Data available:
  - **Hitting**: Exit Velocity, Launch Angle, Barrels, Hard Hit %, xBA, xSLG, xwOBA, EV50, Sprint Speed
  - **Pitching**: Velocity, Spin Rate, Movement, Extension, xERA, Whiff %, Chase %
  - **Fielding**: OAA, Fielding Run Value, Jump, Burst, Arm Strength, Catch Probability
  - **Catching**: Pop Time, Blocks Above Average, Framing Run Value, CS%

### Batter Statistics to Display
| Stat | Description |
|------|-------------|
| G | Games Played |
| AB | At Bats |
| R | Runs |
| H | Hits |
| 2B | Doubles |
| 3B | Triples |
| HR | Home Runs |
| RBI | Runs Batted In |
| SB | Stolen Bases |
| CS | Caught Stealing |
| BB | Walks |
| SO | Strikeouts |
| AVG | Batting Average |
| OBP | On-Base Percentage |
| SLG | Slugging Percentage |
| OPS | On-Base Plus Slugging |
| TB | Total Bases |
| GDP | Ground into Double Play |
| HBP | Hit By Pitch |
| SH | Sacrifice Hits |
| SF | Sacrifice Flies |
| IBB | Intentional Walks |

### Pitcher Statistics to Display
| Stat | Description |
|------|-------------|
| W | Wins |
| L | Losses |
| ERA | Earned Run Average |
| G | Games |
| GS | Games Started |
| CG | Complete Games |
| SHO | Shutouts |
| SV | Saves |
| SVO | Save Opportunities |
| IP | Innings Pitched |
| H | Hits Allowed |
| R | Runs Allowed |
| ER | Earned Runs |
| HR | Home Runs Allowed |
| BB | Walks |
| IBB | Intentional Walks |
| SO | Strikeouts |
| HBP | Hit Batters |
| BK | Balks |
| WP | Wild Pitches |
| WHIP | Walks + Hits per Inning Pitched |
| AVG | Opponent Batting Average |
| K/9 | Strikeouts per 9 Innings |
| BB/9 | Walks per 9 Innings |

### Player Scouting Scale Ratings (20-80 Scale)
Sources: FanGraphs.com, MLB.com

| Tool | Description |
|------|-------------|
| Hit | Ability to make consistent contact and hit for average |
| Game Power | In-game power production during at-bats |
| Raw Power | Maximum power potential measured in batting practice |
| Speed | Running speed and baserunning ability |
| Field | Defensive ability and fielding skills |
| Arm | Arm strength for throwing |

**20-80 Scale Reference:**
| Grade | Description |
|-------|-------------|
| 80 | Elite (Top 1-2% of MLB) |
| 70 | Plus-Plus |
| 60 | Plus (Above Average) |
| 55 | Above Average |
| 50 | Average |
| 45 | Below Average |
| 40 | Fringe Average |
| 30 | Well Below Average |
| 20 | Poor |

### WAR (Wins Above Replacement)
Sources: FanGraphs.com, Baseball-Reference.com

| Stat | Source | Description |
|------|--------|-------------|
| fWAR | FanGraphs | Wins Above Replacement using FIP for pitchers |
| bWAR | Baseball-Reference | Wins Above Replacement using RA9 for pitchers |
| WAR Components | Both | Position, batting, baserunning, fielding contributions |

### Statcast Hitting Metrics
Source: BaseballSavant.mlb.com

| Stat | Description |
|------|-------------|
| Exit Velocity (EV) | Speed of ball off bat (mph) |
| Max Exit Velocity | Maximum exit velocity recorded |
| Launch Angle (LA) | Vertical angle ball leaves bat (degrees) |
| Barrels | Batted balls with optimal EV and LA combination |
| Barrel % | Percentage of batted ball events that are barrels |
| Hard Hit | Batted balls with exit velocity ≥95 mph |
| Hard Hit % | Percentage of batted balls hit 95+ mph |
| LA Sweet Spot % | Percentage of batted balls with LA between 8-32 degrees |
| xBA | Expected Batting Average based on quality of contact |
| xSLG | Expected Slugging based on quality of contact |
| xwOBA | Expected Weighted On-Base Average |
| wOBA | Actual Weighted On-Base Average |
| EV50 | Average exit velocity on top 50% hardest-hit balls |
| Adjusted EV | Exit velocity adjusted for ballpark and environment |
| Sprint Speed | Feet per second in fastest 1-second window |
| Sweet Spot % | Percentage of batted balls with ideal launch angle |

### Statcast Pitching Metrics
Source: BaseballSavant.mlb.com

| Stat | Description |
|------|-------------|
| Pitch Velocity | Average fastball velocity (mph) |
| Max Pitch Velocity | Maximum velocity recorded (mph) |
| Pitch Movement (IVB) | Induced vertical break (inches) |
| Pitch Movement (HB) | Horizontal break (inches) |
| Active Spin | Percentage of spin contributing to movement |
| Spin Rate | Revolutions per minute (RPM) |
| Extension | Distance from rubber at release (feet) |
| Release Height | Height of pitch release point |
| xERA | Expected Earned Run Average |
| xBA | Expected Batting Average against |
| xSLG | Expected Slugging against |
| xwOBA | Expected wOBA against |
| Whiff % | Percentage of swings that miss |
| K% | Strikeout percentage |
| BB% | Walk percentage |
| Chase % | Percentage of pitches outside zone that are swung at |
| CSW% | Called strikes plus whiffs percentage |

### Fielding Metrics
Source: BaseballSavant.mlb.com

| Stat | Description |
|------|-------------|
| OAA | Outs Above Average - overall fielding value |
| Fielding Run Value | Runs saved/cost compared to average fielder |
| Success Rate Added | Plays made above expected based on difficulty |
| Lead Distance | Average distance from bag on steal attempts (for IF) |
| Jump | Reaction time and first step efficiency |
| Burst | Acceleration after initial jump |
| Route Efficiency | Directness of path to ball (for OF) |
| Catch Probability | Likelihood of making catch based on difficulty |
| Arm Strength | Average throw velocity (mph) |
| Arm Run Value | Runs saved by arm on throws |
| Range Run Value | Runs saved by range |
| Exchange Time | Time from catch to throw release |

### Catcher Metrics
Source: BaseballSavant.mlb.com

| Stat | Description |
|------|-------------|
| Pop Time | Time from catch to throw reaching 2B (seconds) |
| Pop Time (2B) | Pop time on throws to second base |
| Pop Time (3B) | Pop time on throws to third base |
| Exchange Time | Time from catch to release |
| Arm Strength | Velocity of throws to bases (mph) |
| CS% | Caught stealing percentage |
| Blocks Above Average | Blocks compared to average catcher |
| Framing Run Value | Runs saved by pitch framing |
| Strike Rate | Percentage of borderline pitches called strikes |
| Catcher Defense | Overall defensive value behind plate |
| Lead Distance Given | Average lead allowed to runners |

### Player Information to Display
- Player Name (first, last)
- Jersey Number
- Position
- Team
- Bats/Throws
- Height/Weight
- Birth Date
- MLB Debut Date
- Player Photo (if available)

### Draft Eligibility Multi-State Control
Implement a segmented control or toggle group for each player with three states:

1. **Eligible** (Green indicator)
   - Player is available for draft selection
   - Default state for new players

2. **On a Team** (Blue indicator)
   - Player has been drafted/assigned to a team
   - Should display which team owns them (if tracking)

3. **Not Eligible** (Red/Gray indicator)
   - Player is ineligible for draft (injured, retired, etc.)
   - Can include optional reason field

### UI/UX Requirements

#### Layout
- Responsive design for web browsers
- Data table with sortable columns
- Fixed header row while scrolling
- Player row with expandable details view
- Search/filter functionality by player name
- Filter by team, position

#### Eligibility Control
- Inline toggle on each player row
- Bulk selection capability for multiple players
- Visual distinction between eligibility states
- Persist eligibility status (local storage or backend)

#### Performance
- Pagination or virtual scrolling for large datasets
- Lazy loading of player details/photos
- Cache API responses
- Loading states and error handling

### Technical Implementation

#### State Management
- Use Provider, Riverpod, or Bloc for state management
- Separate state for:
  - Player data (batters/pitchers)
  - Eligibility status map
  - Filter/sort preferences
  - Loading/error states

#### Models
```dart
class Player {
  final String id;
  final String firstName;
  final String lastName;
  final String position;
  final String team;
  final String jerseyNumber;
  final String bats;
  final String throws;
  final DraftEligibility eligibility;
  final ScoutingGrades? scoutingGrades;
  final WARMetrics? warMetrics;
  // ... additional fields
}

enum DraftEligibility {
  eligible,
  onTeam,
  notEligible
}

class ScoutingGrades {
  final int hit;        // 20-80 scale
  final int gamePower;  // 20-80 scale
  final int rawPower;   // 20-80 scale
  final int speed;      // 20-80 scale
  final int field;      // 20-80 scale
  final int arm;        // 20-80 scale
}

class WARMetrics {
  final double fWAR;    // FanGraphs WAR
  final double bWAR;    // Baseball-Reference WAR
  final int season;
}

class BatterStats {
  final int games;
  final int atBats;
  final int hits;
  final double avg;
  // ... all batting stats
}

class StatcastHittingMetrics {
  final double exitVelocity;      // mph
  final double maxExitVelocity;   // mph
  final double launchAngle;       // degrees
  final int barrels;
  final double barrelPercent;
  final int hardHit;
  final double hardHitPercent;
  final double launchAngleSweetSpotPercent;
  final double xBA;               // Expected Batting Average
  final double xSLG;              // Expected Slugging
  final double xwOBA;             // Expected wOBA
  final double wOBA;              // Actual wOBA
  final double ev50;              // Top 50% EV average
  final double adjustedEV;        // Park-adjusted EV
  final double sprintSpeed;       // ft/sec
  final double sweetSpotPercent;
}

class PitcherStats {
  final int wins;
  final int losses;
  final double era;
  // ... all pitching stats
}

class StatcastPitchingMetrics {
  final double pitchVelocity;     // avg mph
  final double maxPitchVelocity;  // max mph
  final double inducedVertBreak;  // inches
  final double horizBreak;        // inches
  final double activeSpin;        // percentage
  final int spinRate;             // RPM
  final double extension;         // feet
  final double releaseHeight;     // feet
  final double xERA;              // Expected ERA
  final double xBA;               // Expected BA against
  final double xSLG;              // Expected SLG against
  final double xwOBA;             // Expected wOBA against
  final double whiffPercent;
  final double kPercent;
  final double bbPercent;
  final double chasePercent;
  final double cswPercent;        // Called Strikes + Whiffs %
}

class FieldingMetrics {
  final int oaa;                  // Outs Above Average
  final double fieldingRunValue;
  final double successRateAdded;
  final double leadDistance;      // feet
  final double jump;              // reaction time
  final double burst;             // acceleration
  final double routeEfficiency;   // percentage (OF)
  final double catchProbability;
  final double armStrength;       // mph
  final double armRunValue;
  final double rangeRunValue;
  final double exchangeTime;      // seconds
}

class CatcherMetrics {
  final double popTime;           // seconds
  final double popTime2B;         // to 2nd base
  final double popTime3B;         // to 3rd base
  final double exchangeTime;      // seconds
  final double armStrength;       // mph
  final double caughtStealingPercent;
  final double blocksAboveAverage;
  final double framingRunValue;
  final double strikeRate;
  final double catcherDefense;
  final double leadDistanceGiven; // feet
}
```

#### API Service
- Create a dedicated MLB API service class
- Handle CORS issues (may need proxy for web)
- Implement retry logic and error handling
- Parse JSON responses into typed models

### Additional Features (Optional Enhancements)
- Export eligibility list to CSV/JSON
- Import previous eligibility settings
- Dark/light theme toggle
- Print-friendly view
- Season year selector
- Comparison view for selected players
- Notes field for each player
- Draft order tracking

### File Structure
```
lib/
├── main.dart
├── models/
│   ├── player.dart
│   ├── batter_stats.dart
│   ├── pitcher_stats.dart
│   ├── draft_eligibility.dart
│   ├── scouting_grades.dart
│   ├── war_metrics.dart
│   ├── statcast_hitting_metrics.dart
│   ├── statcast_pitching_metrics.dart
│   ├── fielding_metrics.dart
│   └── catcher_metrics.dart
├── services/
│   ├── mlb_api_service.dart
│   ├── fangraphs_service.dart
│   ├── baseball_reference_service.dart
│   └── baseball_savant_service.dart
├── providers/
│   ├── players_provider.dart
│   ├── eligibility_provider.dart
│   └── advanced_stats_provider.dart
├── screens/
│   └── player_draft_screen.dart
├── widgets/
│   ├── player_table.dart
│   ├── batter_stats_row.dart
│   ├── pitcher_stats_row.dart
│   ├── eligibility_toggle.dart
│   ├── player_detail_card.dart
│   ├── scouting_grades_widget.dart
│   ├── statcast_metrics_widget.dart
│   ├── fielding_metrics_widget.dart
│   └── catcher_metrics_widget.dart
└── utils/
    └── constants.dart
```

## Acceptance Criteria

### Core Functionality
- [ ] Two functional tabs: Batters and Pitchers
- [ ] All listed statistics displayed for each player type
- [ ] Three-state eligibility control functioning on each player
- [ ] Eligibility state persists across sessions
- [ ] Sortable columns in data tables
- [ ] Search functionality works
- [ ] Responsive layout for different screen sizes
- [ ] Loading and error states handled gracefully
- [ ] API data successfully fetched and displayed

### Scouting & Advanced Metrics
- [ ] 20-80 scouting scale ratings displayed for Hit, Game Power, Raw Power, Speed, Field, Arm
- [ ] WAR displayed from both FanGraphs (fWAR) and Baseball-Reference (bWAR)
- [ ] Statcast hitting metrics displayed (EV, LA, Barrels, Hard Hit, xBA, xwOBA, EV50, Sprint Speed)
- [ ] Statcast pitching metrics displayed (Velocity, Movement, Spin Rate, Extension, xERA)
- [ ] Fielding metrics displayed (OAA, Fielding Run Value, Jump, Catch Probability, Arm Strength)
- [ ] Catcher-specific metrics displayed (Pop Time, Blocks Above Average, Framing Run Value)

### Data Sources Integration
- [ ] FanGraphs.com data integration for scouting grades and fWAR
- [ ] Baseball-Reference.com data integration for bWAR
- [ ] BaseballSavant.mlb.com data integration for all Statcast metrics
