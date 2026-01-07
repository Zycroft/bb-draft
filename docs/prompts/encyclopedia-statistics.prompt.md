# Encyclopedia Statistics Prompt

| Field | Value |
|-------|-------|
| **Prompt Name** | League Encyclopedia & Historical Statistics |
| **Version** | 1.0.0 |
| **Template Reference** | game-specification-v1 |
| **Created** | 2026-01-07 |
| **Status** | Draft |
| **Parent Document** | baseball-draft-overview.prompt.md |

---

## Overview

This document defines the specification for a comprehensive league encyclopedia and historical statistics system. The platform enables users to view all historical generated statistics for a league across one or more imported seasons, browse seasonal and career statistical leaders, compare player MLB statistics against league-generated statistics, and analyze team historical performance including postseason records.

---

## Nomenclature

| Term | Definition |
|------|------------|
| **League Statistics** | Fantasy statistics generated within the league based on player performance |
| **MLB Statistics** | Official Major League Baseball statistics from external data sources |
| **Seasonal Leaders** | Top performers in a specific statistical category for a single season |
| **Career Leaders** | All-time top performers in a statistical category across all imported seasons |
| **Imported Season** | A historical season's worth of data that has been loaded into the league |
| **Statistical Comparison** | Side-by-side view of MLB vs league-generated statistics |
| **Encyclopedia** | Comprehensive historical database of all league statistics and records |
| **Leaderboard** | Ranked list of players or teams by a specific statistical category |
| **Common Statistics** | Statistics that exist in both MLB and league scoring systems (AVG, HR, Wins, ERA, OPS) |

---

## Historical Statistics System

### Season Import Management

| Feature | Description |
|---------|-------------|
| **Multi-Season Import** | Import statistics from multiple historical seasons |
| **Season Selection** | Filter views by specific season(s) or view all-time |
| **Import Validation** | Verify data integrity during import process |
| **Incremental Updates** | Add new seasons without affecting existing data |
| **Season Metadata** | Track import date, source, and data completeness |

### Import Data Structure

| Field | Type | Description |
|-------|------|-------------|
| `seasonId` | string | Unique identifier for the imported season |
| `year` | integer | Season year (e.g., 2025) |
| `importDate` | datetime | When the season was imported |
| `dataSource` | string | Origin of the data (manual, API, file) |
| `status` | enum | `complete`, `partial`, `pending` |
| `playerCount` | integer | Number of players with statistics |
| `teamCount` | integer | Number of teams with statistics |
| `gamesPlayed` | integer | Total games in the season |

---

## Player Leaderboards

### Leaderboard Configuration

| Setting | Type | Default | Options | Description |
|---------|------|---------|---------|-------------|
| `displayCount` | integer | 10 | 5, 10, 25, 50, 100, All | Number of players to display |
| `leaderboardType` | enum | seasonal | `seasonal`, `career`, `custom_range` | Time scope for statistics |
| `sortDirection` | enum | desc | `asc`, `desc` | Sort order (desc for most stats, asc for ERA) |
| `minimumQualifier` | object | varies | Per-stat thresholds | Minimum thresholds to qualify |
| `playerSearch` | string | null | Player name/ID | Search for specific player ranking |

### Seasonal Leaders View

Display top performers for a single season with customizable list size.

| Feature | Description |
|---------|-------------|
| **Season Selector** | Dropdown to choose specific season |
| **Category Tabs** | Quick navigation between stat categories |
| **Rank Display** | Show player's position in leaderboard |
| **Stat Value** | Display the statistical value |
| **Team Affiliation** | Show player's team for that season |
| **Trend Indicator** | Compare to previous season ranking (if available) |

### Career Leaders View

Display all-time leaders across all imported seasons.

| Feature | Description |
|---------|-------------|
| **Cumulative Stats** | Sum of statistics across all seasons |
| **Seasons Played** | Number of seasons player appears in data |
| **Per-Season Average** | Average statistic per season |
| **Peak Season** | Best single-season performance |
| **Active Status** | Indicate if player is still active |

### Batting Statistics Categories

| Stat | Code | Description | Qualifier | Sort |
|------|------|-------------|-----------|------|
| Batting Average | `AVG` | Hits divided by at-bats | Min 3.1 PA/G | DESC |
| Home Runs | `HR` | Total home runs | None | DESC |
| Runs Batted In | `RBI` | Total RBIs | None | DESC |
| Runs Scored | `R` | Total runs | None | DESC |
| Hits | `H` | Total hits | None | DESC |
| Doubles | `2B` | Total doubles | None | DESC |
| Triples | `3B` | Total triples | None | DESC |
| Stolen Bases | `SB` | Total stolen bases | None | DESC |
| On-Base Percentage | `OBP` | On-base percentage | Min 3.1 PA/G | DESC |
| Slugging Percentage | `SLG` | Slugging percentage | Min 3.1 PA/G | DESC |
| OPS | `OPS` | On-base plus slugging | Min 3.1 PA/G | DESC |
| Walks | `BB` | Total walks | None | DESC |
| Total Bases | `TB` | Total bases | None | DESC |
| Games Played | `G` | Games played | None | DESC |
| At Bats | `AB` | Total at-bats | None | DESC |

### Pitching Statistics Categories

| Stat | Code | Description | Qualifier | Sort |
|------|------|-------------|-----------|------|
| Earned Run Average | `ERA` | Earned runs per 9 innings | Min 1 IP/G | ASC |
| Wins | `W` | Total wins | None | DESC |
| Strikeouts | `SO` | Total strikeouts | None | DESC |
| Saves | `SV` | Total saves | None | DESC |
| WHIP | `WHIP` | Walks + hits per inning | Min 1 IP/G | ASC |
| Innings Pitched | `IP` | Total innings | None | DESC |
| Winning Percentage | `WPCT` | Win percentage | Min 10 decisions | DESC |
| Complete Games | `CG` | Complete games | None | DESC |
| Shutouts | `SHO` | Shutouts | None | DESC |
| Games Started | `GS` | Games started | None | DESC |
| Holds | `HLD` | Total holds | None | DESC |
| K/9 | `K9` | Strikeouts per 9 innings | Min 1 IP/G | DESC |
| BB/9 | `BB9` | Walks per 9 innings | Min 1 IP/G | ASC |
| K/BB | `KBB` | Strikeout to walk ratio | Min 1 IP/G | DESC |

### Leaderboard Display Sizes

| Size | Display Count | Use Case |
|------|---------------|----------|
| **Compact** | 5 | Dashboard widgets, quick reference |
| **Standard** | 10 | Default view, most common use |
| **Extended** | 25 | Detailed analysis |
| **Full** | 50 | Comprehensive review |
| **Complete** | 100 | Deep dive analysis |
| **All** | Unlimited | Full historical record |

### Player Search Feature

| Feature | Description |
|---------|-------------|
| **Name Search** | Search by player first/last name |
| **Partial Match** | Support partial name matching |
| **Player ID Lookup** | Direct lookup by player ID |
| **Rank Highlight** | Highlight searched player in leaderboard |
| **Context Display** | Show players immediately above/below searched player |
| **Multi-Category** | Show searched player's rank across all categories |

---

## MLB vs League Statistics Comparison

### Comparison Overview

Enable side-by-side comparison of a player's official MLB statistics against their league-generated fantasy statistics for statistics that exist in both systems.

### Common Statistics for Comparison

#### Batting Comparison Statistics

| Statistic | MLB Source | League Source | Comparison Notes |
|-----------|------------|---------------|------------------|
| Batting Average (AVG) | Official MLB AVG | League-calculated AVG | Direct comparison |
| Home Runs (HR) | Official MLB HR | League HR total | Direct comparison |
| OPS | Official MLB OPS | League-calculated OPS | Direct comparison |
| Runs (R) | Official MLB Runs | League Runs scored | Direct comparison |
| RBI | Official MLB RBI | League RBI total | Direct comparison |
| Stolen Bases (SB) | Official MLB SB | League SB total | Direct comparison |
| Hits (H) | Official MLB Hits | League Hits total | Direct comparison |
| Walks (BB) | Official MLB BB | League BB total | Direct comparison |

#### Pitching Comparison Statistics

| Statistic | MLB Source | League Source | Comparison Notes |
|-----------|------------|---------------|------------------|
| ERA | Official MLB ERA | League-calculated ERA | Direct comparison |
| Wins (W) | Official MLB Wins | League Wins total | Direct comparison |
| Strikeouts (SO) | Official MLB SO | League SO total | Direct comparison |
| Saves (SV) | Official MLB Saves | League Saves total | Direct comparison |
| WHIP | Official MLB WHIP | League-calculated WHIP | Direct comparison |
| Innings Pitched (IP) | Official MLB IP | League IP total | Direct comparison |

### Comparison View Features

| Feature | Description |
|---------|-------------|
| **Side-by-Side Display** | Two-column layout showing MLB and League stats |
| **Difference Calculation** | Show numerical difference between values |
| **Percentage Variance** | Calculate percentage difference |
| **Visual Indicators** | Color coding for higher/lower values |
| **Season Filter** | Compare specific seasons or career totals |
| **Export Comparison** | Download comparison as CSV/PDF |

### Comparison Analysis Metrics

| Metric | Calculation | Description |
|--------|-------------|-------------|
| `difference` | League - MLB | Raw numerical difference |
| `percentVariance` | ((League - MLB) / MLB) * 100 | Percentage variance |
| `matchScore` | 100 - abs(percentVariance) | How closely stats match (0-100) |
| `consistencyRating` | Average matchScore across stats | Overall consistency measure |

### Comparison Display Modes

| Mode | Description | Best For |
|------|-------------|----------|
| **Single Season** | Compare one specific season | Year-over-year analysis |
| **Career Totals** | Compare cumulative career stats | Overall player evaluation |
| **Season Range** | Compare stats over multiple seasons | Trend analysis |
| **League Average** | Compare player to league average | Relative performance |

---

## Team Statistics

### Team Performance Metrics

| Statistic | Code | Type | Description |
|-----------|------|------|-------------|
| Wins | `W` | integer | Total regular season wins |
| Losses | `L` | integer | Total regular season losses |
| Winning Percentage | `WPCT` | decimal | Wins / (Wins + Losses) |
| Games Played | `G` | integer | Total games played |
| Points For | `PF` | decimal | Total fantasy points scored |
| Points Against | `PA` | decimal | Total fantasy points allowed |
| Point Differential | `DIFF` | decimal | Points For - Points Against |
| Standings Position | `POS` | integer | Final regular season standing |

### Postseason Statistics

| Statistic | Code | Type | Description |
|-----------|------|------|-------------|
| Playoff Appearances | `PLAYOFF_APP` | integer | Number of postseason appearances |
| Playoff Wins | `PLAYOFF_W` | integer | Total postseason wins |
| Playoff Losses | `PLAYOFF_L` | integer | Total postseason losses |
| Playoff Win Percentage | `PLAYOFF_WPCT` | decimal | Postseason winning percentage |
| Championship Appearances | `CHAMP_APP` | integer | World Series/Championship appearances |
| Championships Won | `CHAMP_W` | integer | Total championships won |
| Championship Losses | `CHAMP_L` | integer | Championship series losses |
| Championship Win Percentage | `CHAMP_WPCT` | decimal | Championship series winning percentage |

### Team Leaderboard Categories

| Category | Statistics Included | Sort Order |
|----------|---------------------|------------|
| **Regular Season** | Wins, WPCT, Points Scored | DESC |
| **Postseason Success** | Playoff Appearances, Playoff WPCT | DESC |
| **Championships** | Championships Won, Championship WPCT | DESC |
| **Offensive Power** | Points For, Avg Points/Game | DESC |
| **Consistency** | Point Differential, Standard Deviation | DESC |

### Team Historical View

| Feature | Description |
|---------|-------------|
| **Season-by-Season** | View team performance each season |
| **Cumulative Records** | All-time wins, losses, championships |
| **Franchise Timeline** | Visual history of team performance |
| **Roster History** | Players rostered each season |
| **Draft History** | Historical draft picks by team |
| **Head-to-Head Records** | Historical matchup records vs other teams |

### Team Statistics Formulas

| Statistic | Formula | Example |
|-----------|---------|---------|
| Winning Percentage | `W / (W + L)` | 85 / (85 + 62) = .578 |
| Playoff Win % | `PLAYOFF_W / (PLAYOFF_W + PLAYOFF_L)` | 15 / (15 + 8) = .652 |
| Championship Win % | `CHAMP_W / (CHAMP_W + CHAMP_L)` | 2 / (2 + 1) = .667 |
| Playoff App Rate | `PLAYOFF_APP / SEASONS` | 8 / 12 = .667 |
| Championship Rate | `CHAMP_APP / SEASONS` | 3 / 12 = .250 |
| Dynasty Score | `(CHAMP_W * 10) + (CHAMP_APP * 5) + (PLAYOFF_APP * 2)` | Weighted success metric |

---

## User Interface Components

### Encyclopedia Dashboard

```
+----------------------------------------------------------+
|  League Encyclopedia                    [Season: 2025 v]  |
+----------------------------------------------------------+
|  [Players] [Teams] [Records] [Compare] [Search]          |
+----------------------------------------------------------+
|                                                           |
|  BATTING LEADERS          |  PITCHING LEADERS            |
|  ----------------------   |  ------------------------    |
|  AVG                      |  ERA                         |
|  1. J. Smith    .342      |  1. M. Johnson   2.15        |
|  2. B. Jones    .328      |  2. R. Williams  2.43        |
|  3. T. Wilson   .315      |  3. D. Brown     2.67        |
|  [View Top 10...]         |  [View Top 10...]            |
|                           |                              |
|  HR                       |  WINS                        |
|  1. M. Garcia   47        |  1. S. Davis     18          |
|  2. C. Lee      42        |  2. J. Miller    16          |
|  3. A. Taylor   38        |  3. K. Thomas    15          |
|  [View Top 10...]         |  [View Top 10...]            |
|                                                           |
+----------------------------------------------------------+
|  TEAM STANDINGS                                          |
|  Team              W    L    WPCT   Playoffs   Champs    |
|  Dynasty Kings    892  567  .611      10         3       |
|  Power Sluggers   845  614  .579       8         2       |
|  [View All Teams...]                                     |
+----------------------------------------------------------+
```

### Leaderboard Detail View

```
+----------------------------------------------------------+
|  Career Batting Average Leaders    [Size: 10 v] [Search]  |
+----------------------------------------------------------+
|  Rank | Player          | Team(s)      | Seasons | AVG    |
|-------|-----------------|--------------|---------|--------|
|    1  | John Smith      | Kings, Stars |    8    | .328   |
|    2  | Bob Johnson     | Sluggers     |   12    | .315   |
|    3  | Mike Williams   | Dynasty      |    6    | .312   |
|    4  | Tom Brown       | Power, Kings |   10    | .308   |
|    5  | Chris Davis     | All-Stars    |    9    | .305   |
|    6  | James Wilson    | Legends      |    7    | .303   |
|    7  | David Lee       | Champions    |   11    | .301   |
|    8  | Steve Miller    | Titans       |    5    | .299   |
|    9  | Mark Taylor     | Warriors     |    8    | .297   |
|   10  | Paul Garcia     | Royals       |   14    | .295   |
+----------------------------------------------------------+
|  [< Prev]  Page 1 of 15  [Next >]     [Export CSV]       |
+----------------------------------------------------------+
```

### Player Comparison View

```
+----------------------------------------------------------+
|  Player Comparison: John Smith                            |
|  Season: 2025                     [Change Season v]       |
+----------------------------------------------------------+
|  Statistic      |  MLB Stats  |  League Stats |  Diff    |
|-----------------|-------------|---------------|----------|
|  AVG            |    .298     |     .312      |  +.014   |
|  HR             |      32     |       32      |     0    |
|  RBI            |      98     |      102      |    +4    |
|  OPS            |    .892     |     .915      |  +.023   |
|  Runs           |      87     |       91      |    +4    |
|  SB             |      12     |       12      |     0    |
+----------------------------------------------------------+
|  Match Score: 94.2%    Consistency Rating: A             |
+----------------------------------------------------------+
|  [View Career Comparison]  [Export]  [Add Another Player] |
+----------------------------------------------------------+
```

### Team History View

```
+----------------------------------------------------------+
|  Team History: Dynasty Kings                              |
+----------------------------------------------------------+
|  ALL-TIME RECORD                                         |
|  Regular Season: 892-567 (.611)                          |
|  Playoff Record: 45-28 (.616)                            |
|  Championships: 3 (2018, 2021, 2024)                     |
+----------------------------------------------------------+
|  SEASON-BY-SEASON                                        |
|  Year | W  | L  | WPCT | Finish | Playoffs | Champ      |
|-------|----|----|------|--------|----------|------------|
|  2025 | 89 | 58 | .605 | 2nd    | Lost SF  |   --       |
|  2024 | 95 | 52 | .646 | 1st    | Won WS   |   W        |
|  2023 | 82 | 65 | .558 | 4th    | Lost R1  |   --       |
|  2022 | 78 | 69 | .531 | 5th    |   --     |   --       |
|  2021 | 91 | 56 | .619 | 1st    | Won WS   |   W        |
+----------------------------------------------------------+
```

---

## Data Structure Examples

### Season Import Object

```json
{
  "id": "season-2025-001",
  "year": 2025,
  "leagueId": "league-uuid-001",
  "importDate": "2026-01-05T10:30:00Z",
  "dataSource": "api",
  "status": "complete",
  "metadata": {
    "playerCount": 892,
    "teamCount": 12,
    "gamesPlayed": 162,
    "weeksPlayed": 23
  },
  "importedBy": "user-uuid-001"
}
```

### Player Career Statistics Object

```json
{
  "playerId": "player-uuid-001",
  "playerName": "John Smith",
  "leagueId": "league-uuid-001",
  "careerStats": {
    "batting": {
      "seasons": 8,
      "games": 1156,
      "atBats": 4234,
      "hits": 1389,
      "avg": 0.328,
      "homeRuns": 287,
      "rbi": 892,
      "runs": 756,
      "stolenBases": 89,
      "obp": 0.405,
      "slg": 0.578,
      "ops": 0.983
    }
  },
  "seasonBests": {
    "avg": { "value": 0.352, "year": 2023 },
    "hr": { "value": 47, "year": 2024 },
    "rbi": { "value": 132, "year": 2024 }
  },
  "rankings": {
    "careerAvg": 1,
    "careerHr": 5,
    "careerRbi": 3
  }
}
```

### MLB Comparison Object

```json
{
  "playerId": "player-uuid-001",
  "playerName": "John Smith",
  "season": 2025,
  "comparison": {
    "batting": {
      "avg": {
        "mlb": 0.298,
        "league": 0.312,
        "difference": 0.014,
        "percentVariance": 4.7
      },
      "hr": {
        "mlb": 32,
        "league": 32,
        "difference": 0,
        "percentVariance": 0
      },
      "ops": {
        "mlb": 0.892,
        "league": 0.915,
        "difference": 0.023,
        "percentVariance": 2.6
      }
    },
    "matchScore": 94.2,
    "consistencyRating": "A"
  }
}
```

### Team Historical Statistics Object

```json
{
  "teamId": "team-uuid-001",
  "teamName": "Dynasty Kings",
  "leagueId": "league-uuid-001",
  "allTime": {
    "regularSeason": {
      "wins": 892,
      "losses": 567,
      "winningPercentage": 0.611,
      "gamesPlayed": 1459,
      "pointsFor": 125432.5,
      "pointsAgainst": 118234.2
    },
    "postseason": {
      "appearances": 10,
      "wins": 45,
      "losses": 28,
      "winningPercentage": 0.616
    },
    "championships": {
      "appearances": 5,
      "wins": 3,
      "losses": 2,
      "winningPercentage": 0.600,
      "years": [2018, 2021, 2024]
    }
  },
  "seasons": [
    {
      "year": 2025,
      "wins": 89,
      "losses": 58,
      "finish": 2,
      "playoffResult": "Lost Semifinal",
      "champion": false
    }
  ]
}
```

---

## Business Rules

1. **Minimum Qualifiers**: Players must meet minimum thresholds to appear on rate-based leaderboards (AVG, ERA, WHIP)
2. **Season Completeness**: Partial seasons are marked and can be filtered from career totals
3. **Tie-Breaking**: When statistics are tied, secondary sort uses games played (fewer is better for rate stats)
4. **Active Player Indication**: Currently active players are visually distinguished from historical players
5. **Data Integrity**: Imported statistics are validated against expected ranges and flagged if anomalous
6. **Career Continuity**: Player statistics are linked across seasons even if team changes occur
7. **Comparison Availability**: MLB comparison only available for statistics that exist in both systems
8. **Team Continuity**: Team historical records persist even if ownership changes
9. **Playoff Qualification**: Postseason statistics only count for teams that made playoffs
10. **Championship Definition**: League defines what constitutes championship series (finals, World Series equivalent)

---

## Integration Points

| Component | Integration Description |
|-----------|------------------------|
| **MLB API Service** | Fetch official MLB statistics for comparison feature |
| **League Management** | Access league configuration and team rosters |
| **Draft System** | Link historical draft picks to team records |
| **Player Database** | Reference player profiles and identifications |
| **Export Service** | Generate CSV/PDF exports of statistics and comparisons |
| **Search Service** | Enable player and team name search functionality |

---

## Related Documents

| Document | Relationship | Description |
|----------|--------------|-------------|
| baseball-draft-overview.prompt.md | Parent | Main platform specification |
| player-draft-eligible.md | Related | Player statistics and metrics definitions |
| league-management.prompt.md | Related | League configuration and settings |
| draft-engine.prompt.md | Related | Draft system and pick tracking |

---

## Future Considerations

- Advanced analytics and sabermetrics integration (wRC+, FIP, WAR calculations)
- Machine learning predictions for player performance trends
- Interactive visualization charts and graphs
- Fantasy point projections based on historical data
- Trade analyzer using historical statistics
- Custom statistic creation and tracking
- Multi-league comparison for users in multiple leagues
- Historical draft analysis and value over expectation metrics
- Achievement and milestone tracking (e.g., 3000 career hits)
- Export to fantasy sports analysis tools

---

## Change Log

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2026-01-07 | Initial | Initial prompt creation with historical statistics system, player leaderboards (seasonal/career), MLB vs league comparison, team statistics including postseason records, and UI component specifications |
