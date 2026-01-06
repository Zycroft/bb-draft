# Flutter MLB Player Draft Eligibility Web App

## Overview
Create a Flutter web application that displays MLB baseball players with their complete statistics, organized into separate tabs for batters and pitchers, with draft eligibility status controls.

## Requirements

### Tab Structure
- **Batters Tab**: Display all position players (non-pitchers)
- **Pitchers Tab**: Display all pitchers

### Data Source
Fetch player data from the MLB Lookup Service API:
- Base URL: `http://lookup-service-prod.mlb.com`
- Relevant endpoints:
  - `/json/named.search_player_all.bam?sport_code='mlb'&name_part='%25'` - Search all players
  - `/json/named.player_info.bam?sport_code='mlb'&player_id={id}` - Individual player info
  - `/json/named.sport_hitting_tm.bam?league_list_id='mlb'&game_type='R'&season={year}&player_id={id}` - Batter stats
  - `/json/named.sport_pitching_tm.bam?league_list_id='mlb'&game_type='R'&season={year}&player_id={id}` - Pitcher stats

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
   - Player has been drafted/assigned to a fantasy team
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
  // ... additional fields
}

enum DraftEligibility {
  eligible,
  onTeam,
  notEligible
}

class BatterStats {
  final int games;
  final int atBats;
  final int hits;
  final double avg;
  // ... all batting stats
}

class PitcherStats {
  final int wins;
  final int losses;
  final double era;
  // ... all pitching stats
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
│   └── draft_eligibility.dart
├── services/
│   └── mlb_api_service.dart
├── providers/
│   ├── players_provider.dart
│   └── eligibility_provider.dart
├── screens/
│   └── player_draft_screen.dart
├── widgets/
│   ├── player_table.dart
│   ├── batter_stats_row.dart
│   ├── pitcher_stats_row.dart
│   ├── eligibility_toggle.dart
│   └── player_detail_card.dart
└── utils/
    └── constants.dart
```

## Acceptance Criteria
- [ ] Two functional tabs: Batters and Pitchers
- [ ] All listed statistics displayed for each player type
- [ ] Three-state eligibility control functioning on each player
- [ ] Eligibility state persists across sessions
- [ ] Sortable columns in data tables
- [ ] Search functionality works
- [ ] Responsive layout for different screen sizes
- [ ] Loading and error states handled gracefully
- [ ] API data successfully fetched and displayed
