# Draft Engine Prompt

| Field | Value |
|-------|-------|
| **Prompt Name** | Draft Engine System |
| **Version** | 1.0.0 |
| **Template Reference** | game-specification-v1 |
| **Created** | 2026-01-05 |
| **Status** | Draft |
| **Parent Document** | baseball-draft-overview.prompt.md |

---

## Overview

This document defines the draft engine system for the fantasy baseball platform. The draft grid serves as the primary interface, displaying all picks in a round-by-team matrix with real-time updates during active drafts. The system supports multiple draft modes including live real-time drafts, untimed asynchronous drafts, scheduled window-based drafts, and timed drafts with skip and catch-up mechanics. Commissioners configure eligible player pools before each season, typically including free agents, new MLB players, and optionally minor league prospects.

---

## Nomenclature

| Term | Definition |
|------|------------|
| **Draft Grid** | The primary visual matrix displaying picks organized by round (rows) and team (columns) |
| **Live Draft** | Real-time synchronous draft where all participants draft simultaneously |
| **Untimed Draft** | Asynchronous draft with no time limits; users pick when available |
| **Scheduled Draft** | Draft with configurable time windows for each pick |
| **Timed Draft** | Draft with revolving clock during scheduled windows; skips after timeout |
| **Pick Window** | The time frame during which a team may make their selection |
| **Skip** | When a team fails to pick within their allotted time |
| **Catch-Up Pick** | A make-up selection for a previously skipped pick |
| **Player Pool** | The collection of eligible players available for drafting |
| **On The Clock** | The team currently expected to make a selection |
| **Draft Queue** | User's pre-ranked list of preferred players for quick selection |
| **ADP** | Average Draft Position - typical selection position across drafts |
| **Pick Slot** | A specific cell in the draft grid (round + pick position) |

---

## Draft Grid System

### Grid Architecture

The draft grid is the central interface element, providing a comprehensive view of all draft activity. The grid updates in real-time via WebSocket connections during active drafts.

### Grid Structure

| Dimension | Description |
|-----------|-------------|
| **Rows** | Draft rounds (1 to N based on league configuration) |
| **Columns** | Teams in draft order (adjusted per round for serpentine) |
| **Cells** | Individual pick slots containing player selection or status |
| **Header Row** | Team names/logos with draft position indicators |
| **Header Column** | Round numbers with round status indicators |

### Grid Cell States

| State | Code | Display | Description |
|-------|------|---------|-------------|
| **Empty** | `empty` | Blank/Dashed | Pick not yet reached |
| **On Clock** | `on_clock` | Highlighted/Pulsing | Currently active pick |
| **Queued** | `queued` | Pending indicator | Next picks in sequence |
| **Selected** | `selected` | Player info | Pick has been made |
| **Skipped** | `skipped` | Skip indicator | Team failed to pick in time |
| **Catch-Up** | `catch_up` | Special highlight | Skipped team making catch-up pick |
| **Traded** | `traded` | Trade indicator | Pick owned by different team |
| **Removed** | `removed` | X/Strikethrough | Pick eliminated from draft |

### Grid Cell Object

```json
{
  "cellId": "cell-r3-p7",
  "round": 3,
  "pickInRound": 7,
  "overallPick": 31,
  "originalOwner": "team-uuid-001",
  "currentOwner": "team-uuid-002",
  "state": "selected",
  "player": {
    "playerId": "mlb-player-001",
    "name": "Mike Trout",
    "position": "OF",
    "mlbTeam": "LAA",
    "headshotUrl": "/images/players/trout.jpg"
  },
  "pickTimestamp": "2026-03-15T19:45:32Z",
  "pickDuration": 45,
  "isTraded": true,
  "tradeInfo": {
    "tradeId": "trade-uuid-001",
    "fromTeam": "team-uuid-001"
  }
}
```

### Grid Display Object

```json
{
  "gridId": "grid-uuid-001",
  "leagueId": "league-uuid-001",
  "seasonYear": 2026,
  "draftFormat": "serpentine",
  "totalRounds": 23,
  "teamCount": 12,
  "currentRound": 3,
  "currentPick": 7,
  "currentOverallPick": 31,
  "draftStatus": "in_progress",
  "onTheClock": {
    "teamId": "team-uuid-007",
    "teamName": "Diamond Kings",
    "timeRemaining": 67,
    "pickDeadline": "2026-03-15T19:46:30Z"
  },
  "teams": [
    {
      "teamId": "team-uuid-001",
      "teamName": "Grand Slam Giants",
      "abbreviation": "GSG",
      "draftPosition": 1,
      "logo": "/images/teams/gsg.png",
      "isConnected": true
    }
  ],
  "rounds": [
    {
      "roundNumber": 1,
      "status": "completed",
      "picks": []
    }
  ],
  "lastUpdated": "2026-03-15T19:45:32Z"
}
```

---

## Real-Time Update System

### WebSocket Events

| Event | Direction | Description |
|-------|-----------|-------------|
| `draft:connect` | Client → Server | User joins draft room |
| `draft:disconnect` | Client → Server | User leaves draft room |
| `draft:pick_made` | Server → Clients | Player selected, grid updates |
| `draft:clock_tick` | Server → Clients | Timer countdown update |
| `draft:clock_expired` | Server → Clients | Pick time ran out |
| `draft:skip` | Server → Clients | Team skipped |
| `draft:catch_up_available` | Server → Clients | Skipped team can now pick |
| `draft:catch_up_made` | Server → Clients | Catch-up pick completed |
| `draft:pause` | Server → Clients | Draft paused by commissioner |
| `draft:resume` | Server → Clients | Draft resumed |
| `draft:round_complete` | Server → Clients | Round finished |
| `draft:complete` | Server → Clients | Draft finished |
| `draft:user_status` | Server → Clients | User connection status change |
| `draft:queue_update` | Client → Server | User updated their queue |

### Real-Time Update Payload

```json
{
  "event": "draft:pick_made",
  "timestamp": "2026-03-15T19:45:32Z",
  "data": {
    "pick": {
      "round": 3,
      "pickInRound": 7,
      "overallPick": 31,
      "teamId": "team-uuid-007",
      "teamName": "Diamond Kings",
      "player": {
        "playerId": "mlb-player-042",
        "name": "Ronald Acuna Jr.",
        "position": "OF",
        "mlbTeam": "ATL"
      },
      "pickDuration": 45
    },
    "nextPick": {
      "round": 3,
      "pickInRound": 8,
      "overallPick": 32,
      "teamId": "team-uuid-008",
      "teamName": "Batting Champs",
      "deadline": "2026-03-15T19:47:02Z"
    },
    "gridDelta": {
      "cellId": "cell-r3-p7",
      "newState": "selected"
    }
  }
}
```

### Connection State Management

| State | Description | User Action |
|-------|-------------|-------------|
| **Connected** | Active WebSocket connection | Full participation |
| **Reconnecting** | Attempting to restore connection | Auto-retry in progress |
| **Disconnected** | Connection lost | Manual reconnect or auto-pick |
| **Spectating** | Read-only connection | View only, no picks |

### Sync Recovery Protocol

1. **Heartbeat**: Client sends ping every 30 seconds
2. **Reconnect**: On disconnect, attempt reconnect with exponential backoff
3. **State Sync**: On reconnect, request full grid state from server
4. **Delta Apply**: Apply any missed events from event log
5. **Conflict Resolution**: Server state is authoritative

---

## Draft Modes

### Mode Overview

| Mode | Timing | Skip Behavior | Best For |
|------|--------|---------------|----------|
| **Live** | Real-time, continuous | Auto-pick or skip | Synchronized group drafts |
| **Untimed** | No limits | N/A (no skipping) | Casual/busy leagues |
| **Scheduled** | Per-pick windows | Skips at window end | Distributed time zones |
| **Timed** | Revolving clock | Skips at clock expiry | Flexible with accountability |

### Live Draft Mode

Real-time synchronous drafting where all participants are online simultaneously.

#### Live Draft Configuration

| Setting | Type | Range | Description |
|---------|------|-------|-------------|
| `pickTimer` | integer | 30-300 | Seconds per pick |
| `autoPickOnTimeout` | boolean | - | Auto-select if timer expires |
| `autoPickStrategy` | enum | queue/adp/positional | Strategy for auto-picks |
| `pauseEnabled` | boolean | - | Allow commissioner pauses |
| `maxPauseDuration` | integer | 60-3600 | Maximum pause length in seconds |
| `breakBetweenRounds` | integer | 0-300 | Optional break after each round |

#### Live Draft Object

```json
{
  "draftId": "draft-uuid-001",
  "leagueId": "league-uuid-001",
  "mode": "live",
  "status": "in_progress",
  "scheduledStart": "2026-03-15T19:00:00Z",
  "actualStart": "2026-03-15T19:02:15Z",
  "configuration": {
    "pickTimer": 90,
    "autoPickOnTimeout": true,
    "autoPickStrategy": "queue",
    "pauseEnabled": true,
    "maxPauseDuration": 300,
    "breakBetweenRounds": 0
  },
  "currentState": {
    "round": 3,
    "pick": 7,
    "overallPick": 31,
    "onTheClock": "team-uuid-007",
    "clockStarted": "2026-03-15T19:45:00Z",
    "clockExpires": "2026-03-15T19:46:30Z",
    "isPaused": false
  }
}
```

### Untimed Draft Mode

Asynchronous drafting with no time pressure; users make picks when available.

#### Untimed Draft Configuration

| Setting | Type | Description |
|---------|------|-------------|
| `notifyOnTurn` | boolean | Send notification when it's user's turn |
| `notifyReminders` | array | Reminder intervals (e.g., [1h, 6h, 24h]) |
| `allowQueuePicks` | boolean | Pre-queue picks for auto-submission |
| `maxQueueDepth` | integer | Maximum queued picks allowed |
| `pickOrder` | enum | strict/flexible | Whether picks must be in order |

#### Untimed Draft Object

```json
{
  "draftId": "draft-uuid-002",
  "leagueId": "league-uuid-001",
  "mode": "untimed",
  "status": "in_progress",
  "startedAt": "2026-03-10T00:00:00Z",
  "configuration": {
    "notifyOnTurn": true,
    "notifyReminders": [3600, 21600, 86400],
    "allowQueuePicks": true,
    "maxQueueDepth": 10,
    "pickOrder": "strict"
  },
  "currentState": {
    "round": 5,
    "pick": 3,
    "overallPick": 51,
    "onTheClock": "team-uuid-003",
    "turnStarted": "2026-03-12T14:30:00Z",
    "pendingPicks": []
  },
  "progress": {
    "totalPicks": 276,
    "completedPicks": 50,
    "percentComplete": 18.1
  }
}
```

### Scheduled Draft Mode

Time-window-based drafting where each pick has a configurable deadline.

#### Scheduled Draft Configuration

| Setting | Type | Description |
|---------|------|-------------|
| `windowDuration` | integer | Default window length in minutes |
| `windowSchedule` | array | Custom windows per pick/round |
| `skipOnWindowClose` | boolean | Skip if no pick made by deadline |
| `catchUpEnabled` | boolean | Allow skipped teams to catch up |
| `catchUpWindow` | integer | Minutes to complete catch-up pick |
| `blackoutPeriods` | array | Times when windows don't apply (e.g., overnight) |
| `timezone` | string | Reference timezone for scheduling |

#### Window Schedule Object

```json
{
  "windowSchedule": [
    {
      "rounds": [1, 2, 3],
      "windowDuration": 240,
      "description": "4 hours for early rounds"
    },
    {
      "rounds": [4, 5, 6, 7, 8],
      "windowDuration": 180,
      "description": "3 hours for middle rounds"
    },
    {
      "rounds": [9, 10, 11, 12],
      "windowDuration": 120,
      "description": "2 hours for later rounds"
    },
    {
      "rounds": [13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23],
      "windowDuration": 60,
      "description": "1 hour for final rounds"
    }
  ],
  "blackoutPeriods": [
    {
      "start": "23:00",
      "end": "07:00",
      "timezone": "America/New_York",
      "description": "Overnight blackout"
    }
  ]
}
```

#### Scheduled Draft Object

```json
{
  "draftId": "draft-uuid-003",
  "leagueId": "league-uuid-001",
  "mode": "scheduled",
  "status": "in_progress",
  "startedAt": "2026-03-10T09:00:00Z",
  "configuration": {
    "defaultWindowDuration": 120,
    "skipOnWindowClose": true,
    "catchUpEnabled": true,
    "catchUpWindow": 30,
    "timezone": "America/New_York"
  },
  "currentState": {
    "round": 4,
    "pick": 5,
    "overallPick": 41,
    "onTheClock": "team-uuid-005",
    "windowOpened": "2026-03-11T14:00:00Z",
    "windowCloses": "2026-03-11T17:00:00Z",
    "isBlackout": false
  },
  "skippedPicks": [
    {
      "round": 3,
      "pick": 8,
      "teamId": "team-uuid-008",
      "skippedAt": "2026-03-11T11:00:00Z",
      "catchUpDeadline": "2026-03-11T17:30:00Z",
      "status": "pending_catchup"
    }
  ]
}
```

### Timed Draft Mode

Revolving clock during scheduled windows with skip and catch-up mechanics.

#### Timed Draft Configuration

| Setting | Type | Description |
|---------|------|-------------|
| `draftWindow` | object | Daily/weekly window when draft is active |
| `pickClock` | integer | Seconds on the revolving clock per pick |
| `clockBehavior` | enum | reset/accumulate/carryover | How clock handles unused time |
| `skipThreshold` | integer | Consecutive skips before penalty |
| `catchUpPolicy` | enum | immediate/end_of_round/end_of_draft | When catch-ups occur |
| `catchUpTimeLimit` | integer | Seconds allowed for catch-up picks |
| `bonusTime` | integer | Extra seconds for first pick of session |

#### Clock Behavior Options

| Behavior | Description |
|----------|-------------|
| **reset** | Clock resets to full time for each pick |
| **accumulate** | Unused time adds to next pick (up to max) |
| **carryover** | Time bank persists across session breaks |

#### Catch-Up Policy Options

| Policy | Description |
|--------|-------------|
| **immediate** | Skipped team can pick as soon as next pick completes |
| **end_of_round** | Catch-up picks happen after current round |
| **end_of_draft** | All catch-up picks happen after main draft |

#### Timed Draft Object

```json
{
  "draftId": "draft-uuid-004",
  "leagueId": "league-uuid-001",
  "mode": "timed",
  "status": "in_progress",
  "configuration": {
    "draftWindow": {
      "days": ["monday", "tuesday", "wednesday", "thursday", "friday"],
      "startTime": "18:00",
      "endTime": "23:00",
      "timezone": "America/New_York"
    },
    "pickClock": 120,
    "clockBehavior": "reset",
    "skipThreshold": 3,
    "catchUpPolicy": "immediate",
    "catchUpTimeLimit": 60,
    "bonusTime": 30
  },
  "currentState": {
    "round": 6,
    "pick": 4,
    "overallPick": 64,
    "onTheClock": "team-uuid-004",
    "clockRemaining": 87,
    "sessionStarted": "2026-03-12T18:00:00Z",
    "sessionEnds": "2026-03-12T23:00:00Z",
    "isWindowActive": true
  },
  "skipQueue": [
    {
      "teamId": "team-uuid-009",
      "skippedPicks": [
        { "round": 5, "pick": 9, "overallPick": 57 }
      ],
      "consecutiveSkips": 1,
      "canCatchUp": true
    }
  ],
  "timeBank": {
    "team-uuid-001": 45,
    "team-uuid-002": 120,
    "team-uuid-003": 0
  }
}
```

---

## Skip and Catch-Up System

### Skip Processing

When a team fails to pick within their allotted time:

1. **Timer Expiry**: Clock reaches zero
2. **Skip Recording**: Pick marked as skipped with timestamp
3. **Notification**: Team notified of skip
4. **Queue Check**: If catch-up policy allows, add to catch-up queue
5. **Draft Continues**: Next pick begins immediately
6. **Grid Update**: Cell shows skip indicator

### Skip Object

```json
{
  "skipId": "skip-uuid-001",
  "draftId": "draft-uuid-004",
  "teamId": "team-uuid-009",
  "round": 5,
  "pickInRound": 9,
  "overallPick": 57,
  "skippedAt": "2026-03-12T20:15:00Z",
  "reason": "timer_expired",
  "originalDeadline": "2026-03-12T20:15:00Z",
  "catchUpEligible": true,
  "catchUpDeadline": "2026-03-12T23:00:00Z",
  "catchUpStatus": "pending",
  "catchUpCompletedAt": null
}
```

### Catch-Up Processing

When a skipped team is eligible to make a catch-up pick:

1. **Eligibility Check**: Verify team has pending catch-ups
2. **Notification**: Alert team that catch-up is available
3. **Time Allocation**: Apply catch-up time limit
4. **Pick Execution**: Team selects from available players
5. **Grid Update**: Original cell updated with selection
6. **Queue Update**: Remove from catch-up queue

### Catch-Up Constraints

| Constraint | Description |
|------------|-------------|
| **Player Availability** | Can only pick players still available at catch-up time |
| **Time Limit** | Catch-up picks have separate (usually shorter) timer |
| **Order Preservation** | Multiple catch-ups for same team processed in original order |
| **Deadline Enforcement** | Catch-up must complete before deadline or becomes forfeit |
| **Concurrent Picks** | Catch-up can occur during regular draft flow |

### Catch-Up Queue Object

```json
{
  "draftId": "draft-uuid-004",
  "catchUpQueue": [
    {
      "teamId": "team-uuid-009",
      "pendingCatchUps": [
        {
          "round": 5,
          "pickInRound": 9,
          "overallPick": 57,
          "skippedAt": "2026-03-12T20:15:00Z",
          "catchUpAvailableSince": "2026-03-12T20:17:00Z",
          "deadline": "2026-03-12T23:00:00Z",
          "priority": 1
        }
      ],
      "isOnline": true,
      "lastNotified": "2026-03-12T20:17:00Z"
    }
  ],
  "activeCatchUp": {
    "teamId": "team-uuid-009",
    "round": 5,
    "pickInRound": 9,
    "clockStarted": "2026-03-12T20:20:00Z",
    "clockRemaining": 45
  }
}
```

---

## Player Pool Configuration

### Pool Composition

The commissioner configures the eligible player pool before each season's draft.

| Player Category | Description | Default Inclusion |
|-----------------|-------------|-------------------|
| **MLB Free Agents** | Players not under contract | Yes |
| **New MLB Players** | Rookies debuting in current season | Yes |
| **Existing MLB Players** | All current MLB roster players | Configurable |
| **MiLB Prospects** | Minor league players | Configurable |
| **International Signees** | Recently signed international players | Configurable |
| **Injured Players** | Players on IL at draft time | Configurable |

### Pool Configuration Object

```json
{
  "poolId": "pool-uuid-001",
  "leagueId": "league-uuid-001",
  "seasonYear": 2026,
  "configuredBy": "commissioner-uuid",
  "configuredAt": "2026-02-15T10:00:00Z",
  "lockedAt": "2026-03-15T18:00:00Z",
  "categories": {
    "mlbFreeAgents": {
      "included": true,
      "filter": null
    },
    "newMlbPlayers": {
      "included": true,
      "filter": {
        "minProjectedWar": 0.5
      }
    },
    "existingMlbPlayers": {
      "included": true,
      "filter": {
        "excludeTeams": [],
        "minGamesLastSeason": 0
      }
    },
    "milbProspects": {
      "included": true,
      "filter": {
        "minProspectRank": 100,
        "levels": ["AAA", "AA"]
      }
    },
    "internationalSignees": {
      "included": false
    },
    "injuredPlayers": {
      "included": true,
      "filter": {
        "maxExpectedReturn": "2026-06-01"
      }
    }
  },
  "customAdditions": [
    {
      "playerId": "custom-player-001",
      "name": "Notable Prospect",
      "reason": "Commissioner discretion"
    }
  ],
  "customExclusions": [
    {
      "playerId": "mlb-player-999",
      "name": "Retired Player",
      "reason": "Announced retirement"
    }
  ],
  "totalEligiblePlayers": 1847
}
```

### Player Pool Filters

| Filter | Type | Description |
|--------|------|-------------|
| `minProjectedWar` | float | Minimum projected WAR for inclusion |
| `minProspectRank` | integer | Include prospects ranked this or better |
| `levels` | array | MiLB levels to include (AAA, AA, A+, A, Rookie) |
| `excludeTeams` | array | MLB teams to exclude |
| `minGamesLastSeason` | integer | Minimum games played last season |
| `maxExpectedReturn` | date | Latest injury return date to include |
| `positions` | array | Limit to specific positions |

### Player Eligibility Object

```json
{
  "playerId": "mlb-player-042",
  "name": "Ronald Acuna Jr.",
  "positions": ["OF"],
  "mlbTeam": "ATL",
  "milbTeam": null,
  "eligibilityStatus": "eligible",
  "category": "existingMlbPlayers",
  "draftStatus": "available",
  "adp": 1.2,
  "projectedStats": {
    "war": 6.5,
    "battingAverage": 0.285,
    "homeRuns": 38,
    "stolenBases": 45
  },
  "injuryStatus": null,
  "notes": null
}
```

### Pool Management Actions

| Action | Commissioner | Deputy | Description |
|--------|--------------|--------|-------------|
| Configure Categories | Yes | Configurable | Set inclusion rules |
| Add Custom Player | Yes | Configurable | Add player outside normal rules |
| Exclude Player | Yes | Configurable | Remove player from pool |
| Lock Pool | Yes | No | Prevent further changes |
| Unlock Pool | Yes | No | Allow changes (before draft) |
| Preview Pool | Yes | Yes | View current eligible players |
| Export Pool | Yes | Yes | Download pool as CSV/JSON |

---

## Draft Grid User Interface

### Desktop Layout (Primary)

```
+------------------------------------------------------------------+
|  2026 Fantasy Draft - Round 5 of 23                    [Pause]   |
|  Pick 7 of 12 | Overall: 55/276                        [Settings]|
+------------------------------------------------------------------+
|  ON THE CLOCK: Diamond Kings          |  Timer: [====>    ] 1:23 |
|  Next: Batting Champs → Your Turn!    |  [Auto-Pick: ON]         |
+------------------------------------------------------------------+
|        | Team 1  | Team 2  | Team 3  | Team 4  | ... | Team 12  |
|--------|---------|---------|---------|---------|-----|----------|
| Rd 1   | Trout   | Ohtani  | Acuna   | Soto    | ... | Judge    |
|        | OF-LAA  | DH-LAD  | OF-ATL  | OF-NYY  | ... | OF-NYY   |
|--------|---------|---------|---------|---------|-----|----------|
| Rd 2   | Cole    | deGrom  | Burnes  | Wheeler | ... | Alcantara|
|        | SP-NYY  | SP-TEX  | SP-MIL  | SP-PHI  | ... | SP-MIA   |
|--------|---------|---------|---------|---------|-----|----------|
| Rd 3   | Betts   | Turner  | Ramirez | Bogaerts| ... | Freeman  |
|        | OF-LAD  | SS-PHI  | 3B-CLE  | SS-SDP  | ... | 1B-LAD   |
|--------|---------|---------|---------|---------|-----|----------|
| Rd 4   | Vlad Jr | Tatis   | Lindor  | Riley   | ... | Arenado  |
|        | 1B-TOR  | SS-SDP  | SS-NYM  | 3B-ATL  | ... | 3B-STL   |
|--------|---------|---------|---------|---------|-----|----------|
| Rd 5   | Tucker  | Realmuto| Harper  | [LIVE]  | ... | --       |
|        | OF-HOU  | C-PHI   | OF-PHI  | Diamond | ... | Pending  |
+------------------------------------------------------------------+
|  Available Players              |  My Queue           |  Chat    |
|  [Search_____] [Pos v] [Team v] |  1. Player A        |  ------  |
|  Name      Pos  Team  ADP  [+]  |  2. Player B        |  User1:  |
|  Player X  SS   NYY   56   [+]  |  3. Player C        |  Nice!   |
|  Player Y  OF   BOS   58   [+]  |  [Edit Queue]       |  User2:  |
|  Player Z  SP   LAD   59   [+]  |                     |  Wow     |
+------------------------------------------------------------------+
```

### Tablet Layout

```
+-----------------------------------------------+
|  Round 5/23 | Pick 55/276        [Menu]       |
|  ON THE CLOCK: Diamond Kings     Timer: 1:23  |
+-----------------------------------------------+
|  Draft Grid (Scrollable)                      |
|  +------+------+------+------+------+------+  |
|  |  T1  |  T2  |  T3  |  T4  |  T5  |  T6  |  |
|  +------+------+------+------+------+------+  |
|  |Trout |Ohtani|Acuna |Soto  |Judge |Mookie|  |
|  +------+------+------+------+------+------+  |
|  |Cole  |deGrom|Burnes|Wheele|Bieber|Alcant|  |
|  +------+------+------+------+------+------+  |
|  |Betts |Turner|Ramirz|Bogaer|Devers|Freeam|  |
|  +------+------+------+------+------+------+  |
|  |VladJr|Tatis |Lindor|Riley |Arenao|Machad|  |
|  +------+------+------+------+------+------+  |
|  |Tucker|Realm |Harper|[LIVE]| --   | --   |  |
|  +------+------+------+------+------+------+  |
+-----------------------------------------------+
|  [Grid] [Players] [Queue] [Chat]              |
+-----------------------------------------------+
```

### Mobile Layout

```
+---------------------------+
|  Round 5 | Pick 55        |
|  Timer: [=====>     ] 1:23|
+---------------------------+
|  ON THE CLOCK             |
|  Diamond Kings            |
|  Next: YOUR PICK!         |
+---------------------------+
|  Grid View (Horizontal    |
|  scroll)                  |
|  +-----+-----+-----+      |
|  | T1  | T2  | T3  | →    |
|  +-----+-----+-----+      |
|  |Trout|Ohtni|Acuna|      |
|  +-----+-----+-----+      |
|  |Cole |deGrm|Burne|      |
|  +-----+-----+-----+      |
|  |Betts|Turnr|Ramir|      |
|  +-----+-----+-----+      |
|  |Vlad |Tatis|Lindr|      |
|  +-----+-----+-----+      |
|  |Tuckr|Realm|[NOW]|      |
|  +-----+-----+-----+      |
+---------------------------+
|  [Grid][Pick][Queue][More]|
+---------------------------+
```

### Grid Interaction Features

| Feature | Desktop | Tablet | Mobile |
|---------|---------|--------|--------|
| Cell Click/Tap | View pick details | View pick details | View pick details |
| Cell Hover | Player preview tooltip | N/A | N/A |
| Row Header Click | Jump to round | Jump to round | Jump to round |
| Column Header Click | View team roster | View team roster | View team roster |
| Pinch/Zoom | N/A | Zoom grid | Zoom grid |
| Horizontal Scroll | If teams exceed width | Always | Always |
| Vertical Scroll | If rounds exceed height | Always | Always |
| Current Pick Highlight | Pulsing border + color | Pulsing border | Bold border |
| My Team Highlight | Column background | Column background | Column marker |

---

## Pick Execution Flow

### Standard Pick Flow

```
┌─────────────────┐
│  Clock Starts   │
└────────┬────────┘
         ▼
┌─────────────────┐
│  User Selects   │──────────────┐
│    Player       │              │ (Timer Expires)
└────────┬────────┘              ▼
         │               ┌───────────────┐
         │               │  Auto-Pick or │
         │               │     Skip      │
         │               └───────┬───────┘
         ▼                       │
┌─────────────────┐              │
│ Validate Pick   │◄─────────────┘
└────────┬────────┘
         ▼
┌─────────────────┐
│  Record Pick    │
└────────┬────────┘
         ▼
┌─────────────────┐
│ Broadcast Event │
└────────┬────────┘
         ▼
┌─────────────────┐
│  Update Grid    │
└────────┬────────┘
         ▼
┌─────────────────┐
│  Advance Clock  │
│  (Next Pick)    │
└─────────────────┘
```

### Pick Validation Rules

1. **Player Available**: Player not already drafted
2. **Team Ownership**: Pick belongs to submitting team
3. **Pick Order**: Pick matches current expected pick (unless catch-up)
4. **Draft Active**: Draft is in progress, not paused/completed
5. **Time Valid**: Pick submitted before clock expiry
6. **Position Eligible**: Player eligible for fantasy roster (if enforced)

---

## Data Structure Examples

### Complete Draft State Object

```json
{
  "draftId": "draft-uuid-001",
  "leagueId": "league-uuid-001",
  "seasonYear": 2026,
  "mode": "live",
  "format": "serpentine",
  "status": "in_progress",
  "configuration": {
    "rounds": 23,
    "teamCount": 12,
    "pickTimer": 90,
    "autoPickEnabled": true
  },
  "timing": {
    "scheduledStart": "2026-03-15T19:00:00Z",
    "actualStart": "2026-03-15T19:02:00Z",
    "estimatedEnd": "2026-03-15T23:30:00Z",
    "currentTime": "2026-03-15T20:15:00Z"
  },
  "progress": {
    "currentRound": 5,
    "currentPick": 7,
    "overallPick": 55,
    "totalPicks": 276,
    "percentComplete": 19.9
  },
  "clock": {
    "onTheClock": "team-uuid-007",
    "started": "2026-03-15T20:14:00Z",
    "expires": "2026-03-15T20:15:30Z",
    "remaining": 67,
    "isPaused": false
  },
  "participants": {
    "connected": 11,
    "total": 12,
    "disconnected": ["team-uuid-012"]
  },
  "statistics": {
    "fastestPick": 8,
    "slowestPick": 89,
    "averagePick": 42,
    "autoPickCount": 3,
    "skipCount": 1
  }
}
```

### Draft Pick Submission

```json
{
  "action": "submit_pick",
  "draftId": "draft-uuid-001",
  "teamId": "team-uuid-007",
  "userId": "user-uuid-007",
  "pick": {
    "round": 5,
    "pickInRound": 7,
    "overallPick": 55,
    "playerId": "mlb-player-089",
    "submittedAt": "2026-03-15T20:14:45Z"
  },
  "metadata": {
    "pickDuration": 45,
    "wasFromQueue": false,
    "queuePosition": null,
    "deviceType": "desktop"
  }
}
```

---

## Business Rules

1. **Grid Authority**: Server-side grid state is authoritative; client reconciles on conflict
2. **Pick Finality**: Once recorded, picks cannot be undone except by commissioner action
3. **Clock Precision**: Timer synchronized to server clock; client displays may vary slightly
4. **Skip Fairness**: Skipped teams maintain their catch-up rights until deadline
5. **Pool Immutability**: Player pool locked at draft start; no additions during draft
6. **Mode Consistency**: Draft mode cannot change once draft begins
7. **Order Integrity**: Draft order strictly enforced except for catch-up scenarios
8. **Connection Tolerance**: Brief disconnects (< 30s) do not trigger auto-pick
9. **Pause Limits**: Commissioner pauses count against total pause time budget
10. **Completion Requirement**: Draft cannot finalize until all picks (including catch-ups) resolved

---

## Performance Requirements

| Metric | Target | Description |
|--------|--------|-------------|
| Pick Broadcast Latency | < 200ms | Time from pick to all clients updated |
| Clock Sync Accuracy | < 50ms | Maximum drift between server and clients |
| Grid Render Time | < 100ms | Time to render full grid on update |
| Reconnection Time | < 3s | Time to restore connection and sync |
| Max Concurrent Drafts | 1000 | Simultaneous active drafts supported |
| Event Throughput | 10,000/s | WebSocket events per second capacity |

---

## Integration Points

| Component | Integration Description |
|-----------|------------------------|
| **League Management** | Receives draft configuration and team roster |
| **Player Database** | Queries eligible players and statistics |
| **Real-Time Engine** | WebSocket server for live updates |
| **Notification Service** | Sends pick alerts and turn notifications |
| **Archive System** | Stores completed draft for historical reference |
| **Auto-Pick Engine** | AI/algorithm for automatic selections |
| **Analytics Service** | Records draft metrics and patterns |

---

## Related Documents

| Document | Relationship | Description |
|----------|--------------|-------------|
| baseball-draft-overview.prompt.md | Parent | Main platform specification |
| league-management.prompt.md | Sibling | League administration and settings |
| player-database.prompt.md | Related | Player data and statistics |
| api-specification.prompt.md | Related | REST and WebSocket API definitions |
| auto-pick-engine.prompt.md | Child | Automatic pick algorithm specification |

---

## Future Considerations

- **Auction Draft Mode**: Budget-based bidding system for player acquisition
- **Slow Draft Mode**: Extended multi-day drafts with 24-48 hour windows
- **Draft Simulation**: AI-powered mock drafts for practice
- **Voice Pick Integration**: Voice assistant support for hands-free picking
- **Video Chat Integration**: Embedded video conferencing in draft room
- **Advanced Analytics**: Real-time draft grade and roster analysis
- **Trade During Draft**: Pick trading while draft is in progress
- **Commissioner Pick Override**: Real-time pick correction without pausing
- **Spectator Mode Enhancements**: Public viewing with commentary support
- **Draft Replay**: Playback completed drafts with timeline controls

---

## Change Log

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2026-01-05 | Initial | Initial prompt creation with draft grid system, real-time updates, four draft modes (live, untimed, scheduled, timed), skip/catch-up mechanics, and player pool configuration |
