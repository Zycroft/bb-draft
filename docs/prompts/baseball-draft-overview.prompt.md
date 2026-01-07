# Baseball Draft Overview Prompt

| Field | Value |
|-------|-------|
| **Prompt Name** | Fantasy Baseball Draft Platform |
| **Version** | 1.1.0 |
| **Template Reference** | game-specification-v1 |
| **Created** | 2026-01-02 |
| **Status** | Draft |

---

## Overview

This document defines the specification for a fantasy baseball draft and team management web application. The platform enables users to create and manage multiple leagues, conduct live drafts using serpentine or straight draft formats, and manage their fantasy teams throughout the season. The application features a fully responsive design optimized for mobile phones, tablets, and desktop computers.

---

## Nomenclature

| Term | Definition |
|------|------------|
| **League** | A fantasy baseball competition consisting of multiple teams managed by different users |
| **Team** | A collection of MLB players managed by a single user within a league |
| **Draft** | The player selection process where team managers take turns picking MLB players |
| **Serpentine Draft** | Draft format where pick order reverses each round (1-10, 10-1, 1-10...) |
| **Straight Draft** | Draft format where pick order remains constant each round (1-10, 1-10, 1-10...) |
| **Roster** | The collection of players currently on a team |
| **Draft Pick** | A single selection of a player during the draft |
| **Draft Order** | The sequence in which teams make their selections |
| **Commissioner** | The league administrator with elevated permissions |
| **Free Agent** | A player not currently on any team's roster within a league |
| **Waiver Wire** | The system for claiming free agent players |
| **Draft Lottery** | Randomized system for determining draft order positions |
| **Weighted Lottery** | Lottery where teams have unequal odds based on standings or other factors |
| **Unweighted Lottery** | Lottery where all participating teams have equal odds |
| **Lottery Pool** | The group of teams or pick positions included in lottery drawing |
| **Lottery Odds** | The percentage chance each team has of receiving each pick position |

---

## Platform Architecture

### Technology Stack

| Layer | Technology | Purpose |
|-------|------------|---------|
| Frontend | React/Next.js | Responsive UI with SSR capabilities |
| Styling | Tailwind CSS | Mobile-first responsive design system |
| State Management | Redux/Zustand | Real-time draft state synchronization |
| Backend | Node.js/Express or Next.js API | RESTful API and WebSocket server |
| Database | PostgreSQL | Relational data storage |
| Real-time | Socket.io/WebSockets | Live draft updates |
| Authentication | OAuth 2.0 / JWT | User authentication and authorization |
| Hosting | Cloud Platform (AWS/Vercel) | Scalable deployment |

---

## Responsive Design Specifications

### Breakpoints

| Device | Breakpoint | Target Width |
|--------|------------|--------------|
| Mobile | `sm` | 320px - 639px |
| Tablet | `md` | 640px - 1023px |
| Desktop | `lg` | 1024px - 1279px |
| Large Desktop | `xl` | 1280px+ |

### Mobile Design Principles

1. **Touch-First Interaction**: All interactive elements minimum 44x44px touch targets
2. **Single Column Layout**: Stack content vertically for easy scrolling
3. **Collapsible Navigation**: Hamburger menu for primary navigation
4. **Swipe Gestures**: Support swipe actions for common operations
5. **Bottom Navigation**: Key actions accessible via thumb-friendly bottom bar
6. **Offline Support**: PWA capabilities for draft participation

### Tablet Design Principles

1. **Two-Column Layouts**: Side-by-side content where appropriate
2. **Split View Draft**: Player list and team roster visible simultaneously
3. **Touch and Cursor Support**: Hybrid interaction model
4. **Landscape Optimization**: Enhanced layouts for horizontal orientation

### Desktop Design Principles

1. **Multi-Panel Interface**: Dashboard with multiple information panels
2. **Keyboard Shortcuts**: Power user features for quick navigation
3. **Hover States**: Rich tooltip and preview functionality
4. **Drag and Drop**: Intuitive player ranking and roster management

---

## Core Features

### User Management

| Feature | Description |
|---------|-------------|
| **Registration** | Email/password or OAuth (Google, Yahoo, ESPN) signup |
| **Profile Management** | Avatar, display name, notification preferences |
| **Team History** | Historical performance across leagues and seasons |
| **Notification Settings** | Email, push, and in-app notification controls |

### League Management

| Feature | Description |
|---------|-------------|
| **League Creation** | Configure league name, size, scoring, and rules |
| **Team Count** | Support for 2-30 teams per league |
| **Invite System** | Email invites and shareable join links |
| **Commissioner Tools** | League settings, dispute resolution, manual adjustments |
| **League Types** | Public (open join), Private (invite only) |
| **Scoring Systems** | Head-to-head, Rotisserie, Points-based |

### Draft System

| Feature | Description |
|---------|-------------|
| **Draft Formats** | Serpentine and Straight draft support |
| **Live Draft Room** | Real-time draft with timer and chat |
| **Auto-Draft** | AI-assisted drafting for absent managers |
| **Draft Queue** | Pre-ranked player queue for quick picks |
| **Mock Drafts** | Practice drafts for strategy testing |
| **Draft Results** | Exportable draft recap and analysis |

### Team Management

| Feature | Description |
|---------|-------------|
| **Roster Management** | Set lineups, bench players, IR slots |
| **Trade System** | Propose, negotiate, and execute trades |
| **Waiver Wire** | Claim free agents with priority system |
| **Add/Drop** | Direct free agent acquisitions |
| **Lineup Optimization** | Suggested optimal lineup based on projections |

---

## Draft Configuration

### Draft Format Options

| Format | Behavior | Best For |
|--------|----------|----------|
| **Serpentine** | Order reverses each round | Balanced competitive leagues |
| **Straight** | Same order every round | Keeper/dynasty leagues |

### Draft Settings

| Setting | Type | Options | Description |
|---------|------|---------|-------------|
| `draftType` | enum | `serpentine`, `straight` | Draft order format |
| `pickTimer` | integer | 30-300 seconds | Time allowed per pick |
| `rounds` | integer | 10-30 | Number of draft rounds |
| `scheduledDate` | datetime | Future date/time | Draft start time |
| `autoPickEnabled` | boolean | true/false | Enable auto-draft for expired timers |
| `tradePicksEnabled` | boolean | true/false | Allow draft pick trading |
| `pauseEnabled` | boolean | true/false | Allow commissioner to pause draft |

### Draft Order Determination

| Method | Description |
|--------|-------------|
| **Random** | System-generated random order |
| **Manual** | Commissioner sets order |
| **Previous Standings** | Based on prior season finish (inverse) |
| **Lottery** | Randomized selection for some or all draft positions |

### Draft Lottery Configuration

Leagues can implement a lottery system to add excitement and reduce tanking incentives. The lottery system is highly configurable to match various league preferences.

#### Lottery Scope Settings

| Setting | Type | Options | Description |
|---------|------|---------|-------------|
| `lotteryEnabled` | boolean | true/false | Enable/disable lottery system |
| `lotteryPickCount` | integer | 1 to teamCount | Number of picks determined by lottery |
| `lotteryTeamCount` | integer | 1 to teamCount | Number of teams participating in lottery |
| `lotteryRounds` | enum | `first_only`, `all_rounds`, `custom` | Which rounds use lottery order |
| `lotteryCustomRounds` | array | [1, 2, 3...] | Specific rounds for lottery (if custom) |
| `lotteryType` | enum | `weighted`, `unweighted` | Lottery odds distribution method |
| `nonLotteryOrder` | enum | `standings`, `manual`, `random` | Order for picks outside lottery pool |

#### Lottery Pool Options

| Option | Description | Example |
|--------|-------------|---------|
| **All Teams** | Every team in the league participates | 12-team league, all 12 in lottery |
| **Bottom Half** | Only lower-standing teams participate | Bottom 6 of 12 teams in lottery |
| **Bottom Third** | Only bottom third of standings participate | Bottom 4 of 12 teams in lottery |
| **Non-Playoff Teams** | Teams that missed playoffs participate | 6 non-playoff teams in lottery |
| **Custom Count** | Commissioner specifies exact number | Bottom 5 teams in lottery |

#### Lottery Pick Positions

| Option | Description | Example |
|--------|-------------|---------|
| **All Picks** | Lottery determines all positions for participating teams | All 12 picks randomized |
| **Top Picks Only** | Lottery for first N picks, rest by standings | Top 4 picks by lottery |
| **Custom Picks** | Specific pick positions determined by lottery | Picks 1, 2, 3, 5 by lottery |

#### Lottery Round Application

| Option | Description | Best For |
|--------|-------------|----------|
| **First Round Only** | Lottery order applies to round 1; subsequent rounds use draft format (serpentine/straight) | Most fantasy leagues |
| **All Rounds** | Lottery determines base order used throughout entire draft | Maximum randomization |
| **Custom Rounds** | Lottery for specific rounds (e.g., odd rounds only) | Unique league formats |

#### Weighted Lottery Configuration

For weighted lotteries, odds are distributed based on configurable factors:

| Weighting Method | Description | Example Distribution (4 teams) |
|------------------|-------------|-------------------------------|
| **Inverse Standings** | Worse record = better odds | 1st: 10%, 2nd: 20%, 3rd: 30%, 4th: 40% |
| **Linear** | Equal step between each position | 1st: 10%, 2nd: 20%, 3rd: 30%, 4th: 40% |
| **Exponential** | Dramatically favors worst teams | 1st: 5%, 2nd: 15%, 3rd: 30%, 4th: 50% |
| **Flat Weighted** | Slight advantage to worse teams | 1st: 20%, 2nd: 23%, 3rd: 27%, 4th: 30% |
| **Custom** | Commissioner defines exact percentages | User-defined per position |

#### Weighted Lottery Odds Table Example (6 Lottery Teams)

| Team Standing | Pick 1 | Pick 2 | Pick 3 | Pick 4 | Pick 5 | Pick 6 |
|---------------|--------|--------|--------|--------|--------|--------|
| Worst (6th)   | 25.0%  | 21.5%  | 17.8%  | 14.2%  | 11.2%  | 10.3%  |
| 5th           | 20.0%  | 19.2%  | 17.5%  | 15.3%  | 14.1%  | 13.9%  |
| 4th           | 17.5%  | 17.8%  | 17.5%  | 16.6%  | 15.6%  | 15.0%  |
| 3rd           | 15.0%  | 16.0%  | 16.7%  | 17.0%  | 17.1%  | 18.2%  |
| 2nd           | 12.5%  | 14.0%  | 15.5%  | 17.2%  | 19.0%  | 21.8%  |
| Best (1st)    | 10.0%  | 11.5%  | 15.0%  | 19.7%  | 23.0%  | 20.8%  |

#### Unweighted Lottery Configuration

For unweighted lotteries, all participating teams have equal odds:

| Setting | Description |
|---------|-------------|
| **Equal Odds** | Each team has identical chance at each position |
| **Single Draw** | One drawing determines all positions simultaneously |
| **Sequential Draw** | Positions drawn one at a time (1st pick, then 2nd, etc.) |

#### Lottery Settings Object

| Setting | Type | Options | Description |
|---------|------|---------|-------------|
| `lotteryEnabled` | boolean | true/false | Master toggle for lottery system |
| `lotteryTeamScope` | enum | `all`, `bottom_half`, `bottom_third`, `non_playoff`, `custom` | Which teams participate |
| `lotteryTeamCount` | integer | 1-teamCount | Exact number of teams (if custom scope) |
| `lotteryPickScope` | enum | `all`, `top_picks`, `custom` | Which picks are lottery-determined |
| `lotteryPickCount` | integer | 1-teamCount | Number of picks (if top_picks scope) |
| `lotteryPickPositions` | array | [1,2,3...] | Specific positions (if custom scope) |
| `lotteryRoundScope` | enum | `first_only`, `all_rounds`, `custom` | Which rounds use lottery |
| `lotteryRoundList` | array | [1,2,3...] | Specific rounds (if custom scope) |
| `lotteryWeighted` | boolean | true/false | Use weighted vs unweighted odds |
| `lotteryWeightMethod` | enum | `inverse_standings`, `linear`, `exponential`, `flat`, `custom` | Weighting algorithm |
| `lotteryCustomOdds` | object | {teamId: percentage} | Custom odds per team (if custom method) |
| `lotteryRevealMode` | enum | `instant`, `live_event`, `scheduled` | How lottery results are announced |
| `lotteryRevealDate` | datetime | Future date/time | Scheduled reveal time (if scheduled) |

---

## League Configuration

### Team Settings

| Setting | Type | Range | Description |
|---------|------|-------|-------------|
| `teamCount` | integer | 4-24 | Number of teams in league |
| `rosterSize` | integer | 20-50 | Total roster spots |
| `startingLineup` | integer | 9-15 | Active lineup positions |
| `benchSpots` | integer | 3-35 | Bench/reserve spots |
| `irSpots` | integer | 0-10 | Injured reserve slots |

### Roster Position Requirements

| Position | Code | Typical Count | Description |
|----------|------|---------------|-------------|
| Catcher | `C` | 1-2 | Catcher position |
| First Base | `1B` | 1 | First baseman |
| Second Base | `2B` | 1 | Second baseman |
| Third Base | `3B` | 1 | Third baseman |
| Shortstop | `SS` | 1 | Shortstop |
| Outfield | `OF` | 3-5 | Outfielders (LF, CF, RF) |
| Utility | `UTIL` | 1-2 | Any position player |
| Starting Pitcher | `SP` | 2-5 | Starting pitchers |
| Relief Pitcher | `RP` | 2-4 | Relief pitchers |
| Pitcher | `P` | 2-4 | Any pitcher |
| Bench | `BN` | 3-35 | Reserve players |
| Injured Reserve | `IR` | 0-5 | Injured players |

---

## Data Structure Examples

### League Object

```json
{
  "id": "league-uuid-001",
  "name": "The Mighty Sluggers League",
  "commissioner": "user-uuid-001",
  "status": "drafting",
  "settings": {
    "teamCount": 12,
    "draftType": "serpentine",
    "scoringType": "head-to-head",
    "rosterSize": 25,
    "isPublic": false
  },
  "teams": ["team-uuid-001", "team-uuid-002"],
  "draft": {
    "scheduledDate": "2026-03-15T19:00:00Z",
    "pickTimer": 90,
    "rounds": 23,
    "status": "scheduled",
    "lottery": {
      "enabled": true,
      "teamScope": "bottom_half",
      "teamCount": 6,
      "pickScope": "top_picks",
      "pickCount": 4,
      "roundScope": "first_only",
      "weighted": true,
      "weightMethod": "inverse_standings",
      "revealMode": "live_event",
      "revealDate": "2026-03-10T20:00:00Z",
      "results": [
        {"position": 1, "teamId": "team-uuid-008", "originalStanding": 10},
        {"position": 2, "teamId": "team-uuid-012", "originalStanding": 12},
        {"position": 3, "teamId": "team-uuid-009", "originalStanding": 9},
        {"position": 4, "teamId": "team-uuid-011", "originalStanding": 11}
      ]
    }
  },
  "createdAt": "2026-01-02T10:00:00Z",
  "season": 2026
}
```

### Team Object

```json
{
  "id": "team-uuid-001",
  "name": "Grand Slam Giants",
  "owner": "user-uuid-001",
  "league": "league-uuid-001",
  "roster": [
    {
      "playerId": "player-mlb-001",
      "position": "C",
      "acquisitionType": "draft",
      "acquisitionDate": "2026-03-15T19:45:00Z"
    }
  ],
  "draftPosition": 5,
  "record": {
    "wins": 0,
    "losses": 0,
    "ties": 0
  }
}
```

### Draft Pick Object

```json
{
  "id": "pick-uuid-001",
  "league": "league-uuid-001",
  "round": 1,
  "pickNumber": 5,
  "overallPick": 5,
  "team": "team-uuid-001",
  "player": {
    "id": "player-mlb-001",
    "name": "Mike Trout",
    "position": "OF",
    "mlbTeam": "LAA"
  },
  "timestamp": "2026-03-15T19:05:32Z",
  "pickDuration": 45
}
```

---

## User Interface Components

### Draft Room Layout

**Mobile (Single Column)**
```
+---------------------------+
|  [Timer] Round 3 Pick 7   |
+---------------------------+
|  Now Picking: Team Name   |
+---------------------------+
|  [Search Players_______]  |
+---------------------------+
|  Available Players (List) |
|  - Player 1    [Draft]    |
|  - Player 2    [Draft]    |
|  - Player 3    [Draft]    |
+---------------------------+
|  [My Team] [Queue] [Chat] |
+---------------------------+
```

**Tablet (Two Column)**
```
+------------------+------------------+
|  Draft Status    |  My Team Roster  |
|  Timer: 1:23     |  C: [Empty]      |
|  Round 3, Pick 7 |  1B: Player X    |
+------------------+------------------+
|  Available Players                  |
|  [Search_________________________]  |
|  Name       Pos  Team  ADP  [Act]   |
|  Player 1   OF   NYY   12   [+]     |
|  Player 2   SP   LAD   15   [+]     |
+-------------------------------------+
|  [Draft Queue]  |  [Live Chat]      |
+------------------+------------------+
```

**Desktop (Multi-Panel)**
```
+-------------+---------------------------+-------------+
|  League     |  Available Players        |  My Team    |
|  Standings  |  [Search] [Filters]       |  ---------- |
|  ---------  |  Name    Pos Team  ADP    |  C: Empty   |
|  Team 1: 5  |  Player1 OF  NYY   1.2    |  1B: Smith  |
|  Team 2: 4  |  Player2 SP  LAD   2.1    |  2B: Jones  |
|  Team 3: 3  |  Player3 C   BOS   2.5    |  SS: Empty  |
+-------------+---------------------------+-------------+
|  Draft Log  |  Pick Timer: 1:23         |  Queue      |
|  R1P1: ...  |  [==========>    ]        |  1. Player  |
|  R1P2: ...  |  Now: Team Alpha          |  2. Player  |
|  R1P3: ...  |  Next: Your Pick!         |  3. Player  |
+-------------+---------------------------+-------------+
|  Chat                                                 |
|  User1: Nice pick!                                    |
|  User2: Who's going next?                             |
|  [Type message...                          ] [Send]   |
+-------------------------------------------------------+
```

### Key UI Components

| Component | Mobile | Tablet | Desktop |
|-----------|--------|--------|---------|
| Navigation | Bottom tabs + hamburger | Side rail + top bar | Full sidebar |
| Player List | Vertical scroll list | Scrollable table | Full data table |
| Draft Timer | Fixed top banner | Floating card | Integrated panel |
| Team Roster | Modal/sheet | Side panel | Persistent sidebar |
| Chat | Bottom sheet | Collapsible panel | Persistent panel |
| Filters | Full-screen modal | Dropdown menus | Inline filters |

---

## Business Rules

### General Draft Rules

1. **Draft Eligibility**: All team owners must confirm participation 24 hours before scheduled draft
2. **Pick Timer**: If timer expires, system auto-picks highest-ranked available player from user's queue or by ADP
3. **Draft Order Lock**: Draft order cannot be modified once draft begins
4. **Player Uniqueness**: Each player can only be rostered by one team per league
5. **Roster Compliance**: Teams must meet minimum position requirements before draft completion
6. **Commissioner Override**: Commissioners can pause draft, adjust picks (with audit log), and resolve disputes
7. **Connection Handling**: If user disconnects, auto-pick engages after one full pick cycle
8. **Trade Deadline**: Draft pick trades must be completed before draft start
9. **League Minimum**: Drafts cannot start with fewer than 4 confirmed teams
10. **Pick Validation**: System validates each pick against roster limits and position eligibility

### Draft Lottery Rules

11. **Lottery Timing**: Lottery must be conducted and revealed before draft pick trading deadline
12. **Lottery Finality**: Once lottery results are revealed, they cannot be modified except by commissioner with audit log
13. **Odds Validation**: For weighted lotteries, total odds for each pick position must equal 100%
14. **Lottery Eligibility**: Only teams meeting lottery pool criteria (standings-based) can participate
15. **Result Transparency**: All lottery odds and results must be visible to all league members
16. **Lottery Lock**: Lottery settings cannot be modified once the season determining standings has begun
17. **Non-Lottery Picks**: Teams/picks outside the lottery pool follow the designated non-lottery order method
18. **Weighted Odds Minimum**: In weighted lotteries, every participating team must have at least 1% odds for each position
19. **Lottery Audit Trail**: System records random seed, algorithm used, and timestamp for lottery integrity verification
20. **Re-draw Prohibition**: Lottery cannot be re-drawn; if issues arise, commissioner must manually resolve with audit log

---

## Real-Time Requirements

| Feature | Latency Target | Protocol |
|---------|----------------|----------|
| Draft Pick Broadcast | < 500ms | WebSocket |
| Timer Sync | < 100ms | WebSocket |
| Chat Messages | < 300ms | WebSocket |
| Roster Updates | < 1s | WebSocket + REST fallback |
| Connection Recovery | < 5s | WebSocket reconnect |

---

## Security Requirements

1. **Authentication**: JWT tokens with refresh token rotation
2. **Authorization**: Role-based access (Owner, Commissioner, Admin)
3. **Rate Limiting**: API rate limits to prevent abuse
4. **Input Validation**: Server-side validation for all inputs
5. **Audit Logging**: All draft actions logged with timestamps
6. **Data Encryption**: TLS 1.3 for transit, AES-256 for sensitive data at rest

---

## Accessibility Requirements

| Requirement | Standard | Implementation |
|-------------|----------|----------------|
| Screen Reader Support | WCAG 2.1 AA | Semantic HTML, ARIA labels |
| Keyboard Navigation | WCAG 2.1 AA | Focus management, shortcuts |
| Color Contrast | WCAG 2.1 AA | 4.5:1 minimum ratio |
| Motion Reduction | WCAG 2.1 AA | Respect prefers-reduced-motion |
| Touch Targets | Mobile Best Practice | Minimum 44x44px |

---

## Performance Targets

| Metric | Target | Measurement |
|--------|--------|-------------|
| First Contentful Paint | < 1.5s | Lighthouse |
| Time to Interactive | < 3.5s | Lighthouse |
| Largest Contentful Paint | < 2.5s | Core Web Vitals |
| Cumulative Layout Shift | < 0.1 | Core Web Vitals |
| First Input Delay | < 100ms | Core Web Vitals |
| Draft Room Load | < 2s | Custom metric |
| Bundle Size (initial) | < 200KB gzipped | Build analysis |

---

## Integration Points

| Component | Integration Description |
|-----------|------------------------|
| **MLB Data Provider** | Player statistics, rosters, and injury updates |
| **Authentication Provider** | OAuth providers for social login |
| **Email Service** | Transactional emails for invites, notifications |
| **Push Notification Service** | Real-time mobile/web push notifications |
| **Analytics Platform** | User behavior and draft analytics |
| **CDN** | Static asset delivery and caching |

---

## Future Considerations

- **Keeper/Dynasty Leagues**: Multi-year player retention and rookie drafts
- **Auction Drafts**: Budget-based player bidding system
- **Live Scoring**: Real-time score updates during MLB games
- **Mobile Native Apps**: iOS and Android native applications
- **Voice Commands**: Alexa/Google Assistant integration for draft picks
- **AI Draft Assistant**: ML-powered draft recommendations
- **League History**: Multi-season league statistics and records
- **Custom Scoring**: User-defined scoring category creation
- **Playoff Brackets**: Customizable playoff formats
- **Social Features**: League message boards, trash talk, achievements

---

## Related Documents

| Document | Relationship | Description |
|----------|--------------|-------------|
| prompt-template.prompt.md | Template | Template used for this document |
| player-database.prompt.md | Child | MLB player data specifications |
| scoring-system.prompt.md | Child | Fantasy scoring rules and calculations |
| draft-engine.prompt.md | Child | Draft logic and algorithms |
| api-specification.prompt.md | Child | REST and WebSocket API definitions |

---

## Change Log

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2026-01-02 | Initial | Initial prompt creation with platform architecture, responsive design specs, draft system, league management, and UI components |
| 1.1.0 | 2026-01-07 | Update | Added comprehensive draft lottery system with configurable options for lottery pool (all teams, bottom half, custom), pick positions (all picks, top N picks, custom), round application (first round only, all rounds, custom), and weighting methods (weighted/unweighted with multiple algorithms) |
