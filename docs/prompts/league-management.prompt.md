# League Management Prompt

| Field | Value |
|-------|-------|
| **Prompt Name** | League Management System |
| **Version** | 1.0.0 |
| **Template Reference** | game-specification-v1 |
| **Created** | 2026-01-05 |
| **Status** | Draft |
| **Parent Document** | baseball-draft-overview.prompt.md |

---

## Overview

This document defines the league management system for the fantasy baseball draft platform. It covers team owner settings and preferences, commissioner administration tools, draft order management, pick trading, draft finalization, historical archiving, multi-season grid management, and statistical import functionality. The system supports hierarchical permissions allowing commissioners to delegate administrative duties to deputy commissioners.

---

## Nomenclature

| Term | Definition |
|------|------------|
| **Commissioner** | The primary league administrator with full management privileges |
| **Deputy Commissioner** | A user granted commissioner privileges by the primary commissioner |
| **Draft Grid** | The visual matrix displaying all draft picks organized by round and team |
| **Pick Status** | The state of a draft pick (available, on the clock, traded, skipped) |
| **Season Grid** | A draft grid associated with a specific season year |
| **Future Pick** | A draft pick belonging to a future season that can be traded |
| **Trade** | The exchange of draft picks and/or players between teams |
| **Draft Finalization** | The process of locking a completed draft for historical preservation |
| **Historical Archive** | Permanent storage of finalized draft grids for reference |
| **Team Preferences** | User-configurable settings for team management and notifications |
| **Import Profile** | Configuration for importing external statistical data |

---

## User Roles and Permissions

### Role Hierarchy

| Role | Level | Description |
|------|-------|-------------|
| **System Admin** | 0 | Platform-wide administration (outside league scope) |
| **Commissioner** | 1 | Full league control, can create deputy commissioners |
| **Deputy Commissioner** | 2 | Delegated commissioner powers, limited by assignment |
| **Team Owner** | 3 | Standard user managing their own team |
| **Spectator** | 4 | Read-only access to public league information |

### Permission Matrix

| Permission | Commissioner | Deputy Commissioner | Team Owner | Spectator |
|------------|--------------|---------------------|------------|-----------|
| Manage League Settings | Yes | Configurable | No | No |
| Add/Remove Users | Yes | Configurable | No | No |
| Set Draft Order | Yes | Configurable | No | No |
| Execute Pick Trades | Yes | Configurable | No | No |
| Modify Pick Status | Yes | Configurable | No | No |
| Finalize Draft | Yes | No | No | No |
| Create Season Grids | Yes | Configurable | No | No |
| Import Statistics | Yes | Configurable | No | No |
| Deputize Users | Yes | No | No | No |
| Manage Own Team | Yes | Yes | Yes | No |
| View Draft Grid | Yes | Yes | Yes | Yes |

---

## Team Owner Features

### Team Settings

| Setting | Type | Description |
|---------|------|-------------|
| `teamName` | string | Display name for the team (3-50 characters) |
| `teamAbbreviation` | string | Short code for compact displays (2-5 characters) |
| `teamLogo` | url | Custom team logo image (optional) |
| `teamColors` | object | Primary and secondary color hex codes |
| `timezone` | string | User's local timezone for scheduling |
| `isPublicProfile` | boolean | Whether team profile is visible to non-league members |

### Notification Preferences

| Preference | Type | Default | Description |
|------------|------|---------|-------------|
| `draftReminders` | boolean | true | Receive draft start reminders |
| `pickNotifications` | boolean | true | Alert when it's your turn to pick |
| `tradeProposals` | boolean | true | Notify on incoming trade offers |
| `leagueAnnouncements` | boolean | true | Commissioner broadcast messages |
| `emailDigest` | enum | `daily` | Email summary frequency (none, daily, weekly) |
| `pushEnabled` | boolean | true | Enable mobile push notifications |
| `soundEnabled` | boolean | true | Audio alerts during draft |

### Draft Preferences

| Preference | Type | Description |
|------------|------|-------------|
| `autoPickEnabled` | boolean | Enable automatic picking if timer expires |
| `autoPickStrategy` | enum | Strategy for auto-picks (queue, adp, positional_need) |
| `draftQueue` | array | Ordered list of preferred players |
| `positionPriority` | array | Ranked position preferences for auto-pick |
| `excludedPlayers` | array | Players to never auto-draft |

---

## Commissioner Administration

### User Management

#### Adding Users

| Method | Description |
|--------|-------------|
| **Email Invite** | Send invitation email with unique join link |
| **Direct Link** | Generate shareable league join URL |
| **Manual Add** | Add existing platform user by username/email |
| **Bulk Import** | Import multiple users via CSV file |

#### User Management Actions

| Action | Description | Reversible |
|--------|-------------|------------|
| `invite` | Send league invitation | Yes (cancel) |
| `approve` | Accept pending join request | No |
| `reject` | Decline pending join request | No |
| `remove` | Remove user from league | Yes (re-invite) |
| `suspend` | Temporarily disable user access | Yes |
| `transfer` | Transfer team ownership to another user | No |
| `assignTeam` | Assign user to specific team slot | Yes |

### Deputy Commissioner System

#### Deputization Settings

| Setting | Type | Description |
|---------|------|-------------|
| `deputyUserId` | string | User ID of the deputy |
| `permissions` | array | List of granted permissions |
| `effectiveDate` | datetime | When deputy powers begin |
| `expirationDate` | datetime | Optional expiration of deputy powers |
| `canBeRevoked` | boolean | Whether primary commissioner can revoke (always true) |
| `notes` | string | Commissioner notes about delegation |

#### Delegatable Permissions

```json
{
  "delegatablePermissions": [
    "manage_users",
    "manage_draft_order",
    "execute_trades",
    "modify_pick_status",
    "create_season_grids",
    "import_statistics",
    "manage_league_settings",
    "pause_resume_draft",
    "send_announcements"
  ]
}
```

---

## Draft Order Management

### Draft Order Configuration

| Setting | Type | Description |
|---------|------|-------------|
| `orderMethod` | enum | How order is determined (manual, random, lottery, standings) |
| `serpentine` | boolean | Whether order reverses each round |
| `lockedAt` | datetime | When order becomes immutable |
| `lastModified` | datetime | Last modification timestamp |
| `modifiedBy` | string | User ID of last modifier |

### Draft Order Actions

| Action | Pre-Draft | During Draft | Post-Draft |
|--------|-----------|--------------|------------|
| Set Order | Yes | No | No |
| Randomize | Yes | No | No |
| Swap Positions | Yes | No | No |
| Lock Order | Yes | Auto-locks | N/A |
| View Order | Yes | Yes | Yes |

### Draft Order Object

```json
{
  "leagueId": "league-uuid-001",
  "seasonYear": 2026,
  "orderMethod": "manual",
  "serpentine": true,
  "order": [
    {
      "position": 1,
      "teamId": "team-uuid-003",
      "teamName": "Sluggers United"
    },
    {
      "position": 2,
      "teamId": "team-uuid-007",
      "teamName": "Diamond Kings"
    }
  ],
  "lockedAt": "2026-03-15T18:00:00Z",
  "status": "locked"
}
```

---

## Pick Trading System

### Trade Pick Configuration

| Setting | Type | Description |
|---------|------|-------------|
| `tradePicksEnabled` | boolean | Whether pick trading is allowed |
| `futurePickTrading` | boolean | Allow trading picks from future seasons |
| `futureYearsLimit` | integer | How many years ahead picks can be traded (1-5) |
| `tradeDeadline` | datetime | Cutoff for pick trades (null = no deadline) |
| `requireApproval` | boolean | Commissioner must approve trades |
| `vetoWindow` | integer | Hours for commissioner review (0 = instant) |

### Pick Trade Object

```json
{
  "tradeId": "trade-uuid-001",
  "leagueId": "league-uuid-001",
  "status": "pending",
  "proposedAt": "2026-02-15T14:30:00Z",
  "proposingTeam": {
    "teamId": "team-uuid-001",
    "sending": [
      {
        "type": "pick",
        "seasonYear": 2026,
        "round": 2,
        "originalOwner": "team-uuid-001"
      }
    ],
    "receiving": [
      {
        "type": "pick",
        "seasonYear": 2026,
        "round": 5,
        "originalOwner": "team-uuid-002"
      },
      {
        "type": "pick",
        "seasonYear": 2027,
        "round": 3,
        "originalOwner": "team-uuid-002"
      }
    ]
  },
  "receivingTeam": {
    "teamId": "team-uuid-002",
    "accepted": false
  },
  "commissionerApproval": null,
  "executedAt": null
}
```

### Trade Validation Rules

1. **Ownership Verification**: Teams can only trade picks they currently own
2. **Season Validity**: Future picks must be within `futureYearsLimit`
3. **Deadline Compliance**: Trades must occur before `tradeDeadline`
4. **Pick Availability**: Picks cannot be traded if already used or removed
5. **Balance Check**: Optional rule requiring trades to be "fair" (configurable)

---

## Pick Status Management

### Pick Status Values

| Status | Code | Description | Can Draft | Can Trade |
|--------|------|-------------|-----------|-----------|
| **Available** | `available` | Pick is active and unused | Yes | Yes |
| **Selected** | `selected` | Player has been drafted | No | No |
| **Traded** | `traded` | Pick ownership transferred | Depends | No |
| **Removed** | `removed` | Pick eliminated from draft | No | No |
| **Forfeited** | `forfeited` | Pick lost due to penalty | No | No |
| **Compensatory** | `compensatory` | Extra pick added as compensation | Yes | Configurable |

### Pick Status Object

```json
{
  "pickId": "pick-uuid-001",
  "leagueId": "league-uuid-001",
  "seasonYear": 2026,
  "round": 3,
  "pickNumber": 7,
  "overallPick": 31,
  "originalOwner": "team-uuid-001",
  "currentOwner": "team-uuid-002",
  "status": "available",
  "statusHistory": [
    {
      "status": "available",
      "timestamp": "2026-01-01T00:00:00Z",
      "modifiedBy": "system"
    },
    {
      "status": "traded",
      "timestamp": "2026-02-15T14:30:00Z",
      "modifiedBy": "commissioner-uuid",
      "tradeId": "trade-uuid-001"
    }
  ],
  "player": null,
  "notes": "Acquired from Team A in trade"
}
```

### Commissioner Pick Actions

| Action | Description | Audit Required |
|--------|-------------|----------------|
| `remove` | Remove pick from draft | Yes |
| `restore` | Restore previously removed pick | Yes |
| `reassign` | Change pick ownership (admin override) | Yes |
| `add_compensatory` | Add extra pick | Yes |
| `swap` | Swap two picks between teams | Yes |
| `void_selection` | Undo a completed pick | Yes |

---

## Draft Finalization

### Finalization Process

1. **Completion Check**: Verify all picks are made or accounted for
2. **Roster Validation**: Confirm all teams meet roster requirements
3. **Review Period**: Optional window for disputes (configurable)
4. **Commissioner Approval**: Final sign-off on draft results
5. **Archive Creation**: Generate immutable historical record
6. **Grid Lock**: Prevent further modifications to current season grid
7. **Next Season Prep**: Create next season's draft grid if it does not already exist

### Finalization Settings

| Setting | Type | Description |
|---------|------|-------------|
| `autoFinalize` | boolean | Automatically finalize when all picks complete |
| `reviewPeriodHours` | integer | Hours to wait before finalization (0-168) |
| `requireConfirmation` | boolean | Require commissioner explicit confirmation |
| `notifyOnFinalize` | boolean | Send notification to all league members |
| `createNextSeason` | boolean | Auto-create next season grid on finalize if it does not already exist |

### Finalization Object

```json
{
  "finalizationId": "final-uuid-001",
  "leagueId": "league-uuid-001",
  "seasonYear": 2026,
  "status": "finalized",
  "draftCompletedAt": "2026-03-15T23:45:00Z",
  "reviewPeriodEnd": "2026-03-16T23:45:00Z",
  "finalizedAt": "2026-03-16T23:45:00Z",
  "finalizedBy": "commissioner-uuid",
  "totalPicks": 276,
  "teamsParticipated": 12,
  "archiveId": "archive-uuid-001",
  "checksums": {
    "picks": "sha256-abc123...",
    "roster": "sha256-def456..."
  }
}
```

---

## Historical Draft Grid Archive

### Archive Structure

| Component | Description |
|-----------|-------------|
| **Grid Snapshot** | Complete draft grid at finalization |
| **Pick Details** | Full pick data including timing and metadata |
| **Team Rosters** | Final rosters after draft completion |
| **Trade History** | All pick trades for the season |
| **Audit Log** | Commissioner actions and modifications |
| **Statistics** | Draft analytics and metrics |

### Archive Object

```json
{
  "archiveId": "archive-uuid-001",
  "leagueId": "league-uuid-001",
  "leagueName": "The Mighty Sluggers League",
  "seasonYear": 2026,
  "createdAt": "2026-03-16T23:45:00Z",
  "draftFormat": "serpentine",
  "teamCount": 12,
  "totalRounds": 23,
  "grid": {
    "rounds": [
      {
        "roundNumber": 1,
        "picks": [
          {
            "pickNumber": 1,
            "overallPick": 1,
            "teamId": "team-uuid-003",
            "teamName": "Sluggers United",
            "player": {
              "playerId": "mlb-player-001",
              "name": "Mike Trout",
              "position": "OF",
              "mlbTeam": "LAA"
            },
            "timestamp": "2026-03-15T19:02:15Z"
          }
        ]
      }
    ]
  },
  "statistics": {
    "fastestPick": 8,
    "slowestPick": 89,
    "averagePickTime": 34,
    "autoPickCount": 5
  },
  "isLocked": true,
  "accessLevel": "league_members"
}
```

### Archive Access Control

| Access Level | Description |
|--------------|-------------|
| `public` | Anyone can view |
| `league_members` | Only current league members |
| `participants_only` | Only users who participated in that draft |
| `commissioner_only` | Restricted to commissioner access |

---

## Multi-Season Grid Management

### Season Grid Configuration

| Setting | Type | Description |
|---------|------|-------------|
| `currentSeason` | integer | Active season year |
| `futureSeasons` | array | Pre-created future season grids |
| `maxFutureSeasons` | integer | Maximum future grids allowed (1-5) |
| `autoCreateSeasons` | boolean | Auto-create next season on finalization |
| `inheritSettings` | boolean | Copy settings from previous season |

### Season Grid Object

```json
{
  "gridId": "grid-uuid-001",
  "leagueId": "league-uuid-001",
  "seasonYear": 2027,
  "status": "future",
  "createdAt": "2026-03-16T23:45:00Z",
  "createdBy": "commissioner-uuid",
  "teams": [
    {
      "teamId": "team-uuid-001",
      "position": 1,
      "picks": [
        {
          "round": 1,
          "status": "available",
          "originalOwner": "team-uuid-001",
          "currentOwner": "team-uuid-001"
        },
        {
          "round": 2,
          "status": "traded",
          "originalOwner": "team-uuid-001",
          "currentOwner": "team-uuid-005",
          "tradeId": "trade-uuid-002"
        }
      ]
    }
  ],
  "settings": {
    "rounds": 23,
    "draftFormat": "serpentine",
    "inherited": true
  }
}
```

### Season Status Values

| Status | Description |
|--------|-------------|
| `future` | Season not yet active, picks can be traded |
| `upcoming` | Next season, draft scheduling available |
| `active` | Current season, draft in progress or pending |
| `completed` | Draft finished, awaiting finalization |
| `archived` | Season finalized and archived |

---

## Statistics Import System

### Import Sources

| Source | Format | Description |
|--------|--------|-------------|
| **CSV Upload** | CSV | Manual file upload with mapping |
| **API Integration** | JSON | Direct connection to stats provider |
| **Platform Export** | JSON | Import from other fantasy platforms |
| **Manual Entry** | Form | Individual stat entry |

### Import Configuration

| Setting | Type | Description |
|---------|------|-------------|
| `sourceType` | enum | Import source type |
| `mappingProfile` | object | Column/field mapping configuration |
| `seasonYear` | integer | Target season for import |
| `overwriteExisting` | boolean | Replace existing data if present |
| `validationLevel` | enum | strict, lenient, none |
| `scheduledImport` | boolean | Enable recurring imports |
| `importFrequency` | string | Cron expression for scheduled imports |

### Import Profile Object

```json
{
  "profileId": "import-uuid-001",
  "leagueId": "league-uuid-001",
  "profileName": "Historical Season Stats",
  "sourceType": "csv",
  "mappingProfile": {
    "playerName": "column_A",
    "playerId": "column_B",
    "seasonYear": "column_C",
    "stats": {
      "batting_average": "column_D",
      "home_runs": "column_E",
      "rbi": "column_F",
      "stolen_bases": "column_G",
      "era": "column_H",
      "wins": "column_I",
      "strikeouts": "column_J"
    }
  },
  "validationRules": {
    "requirePlayerId": true,
    "allowPartialStats": true,
    "duplicateHandling": "update"
  },
  "createdBy": "commissioner-uuid",
  "lastUsed": "2026-01-04T10:30:00Z"
}
```

### Import Job Object

```json
{
  "jobId": "job-uuid-001",
  "profileId": "import-uuid-001",
  "leagueId": "league-uuid-001",
  "status": "completed",
  "startedAt": "2026-01-04T10:30:00Z",
  "completedAt": "2026-01-04T10:32:15Z",
  "seasonYear": 2025,
  "recordsProcessed": 1250,
  "recordsImported": 1248,
  "recordsFailed": 2,
  "errors": [
    {
      "row": 156,
      "field": "playerId",
      "error": "Player not found in database"
    }
  ],
  "importedBy": "commissioner-uuid"
}
```

---

## Data Structure Examples

### League Settings Object

```json
{
  "leagueId": "league-uuid-001",
  "settings": {
    "general": {
      "leagueName": "The Mighty Sluggers League",
      "isPublic": false,
      "maxTeams": 12,
      "allowLateJoin": true
    },
    "draft": {
      "format": "serpentine",
      "rounds": 23,
      "pickTimer": 90,
      "autoPickEnabled": true,
      "tradePicksEnabled": true,
      "futurePickTrading": true,
      "futureYearsLimit": 3
    },
    "commissioner": {
      "primaryCommissioner": "user-uuid-001",
      "deputies": ["user-uuid-002", "user-uuid-003"],
      "requireTradeApproval": false,
      "vetoWindowHours": 24
    },
    "finalization": {
      "autoFinalize": false,
      "reviewPeriodHours": 24,
      "createNextSeason": true
    }
  },
  "lastModified": "2026-01-05T09:00:00Z",
  "modifiedBy": "user-uuid-001"
}
```

### User Preferences Object

```json
{
  "userId": "user-uuid-001",
  "leagueId": "league-uuid-001",
  "teamId": "team-uuid-001",
  "preferences": {
    "team": {
      "teamName": "Grand Slam Giants",
      "abbreviation": "GSG",
      "colors": {
        "primary": "#1E40AF",
        "secondary": "#F59E0B"
      },
      "timezone": "America/New_York"
    },
    "notifications": {
      "draftReminders": true,
      "pickNotifications": true,
      "tradeProposals": true,
      "leagueAnnouncements": true,
      "emailDigest": "daily",
      "pushEnabled": true,
      "soundEnabled": true
    },
    "draft": {
      "autoPickEnabled": true,
      "autoPickStrategy": "queue",
      "draftQueue": ["mlb-player-001", "mlb-player-002"],
      "positionPriority": ["OF", "SP", "SS", "3B"],
      "excludedPlayers": []
    }
  },
  "lastUpdated": "2026-01-05T08:30:00Z"
}
```

---

## Business Rules

1. **Commissioner Uniqueness**: Each league has exactly one primary commissioner; ownership can be transferred but not shared
2. **Deputy Limitations**: Deputies cannot grant permissions they don't have or create other deputies
3. **Pick Trade Validation**: All trades must pass ownership verification before execution
4. **Finalization Permanence**: Once finalized, draft results cannot be modified (archive is immutable)
5. **Future Grid Limit**: Leagues cannot create more future grids than `maxFutureSeasons` setting
6. **Import Validation**: Statistical imports must pass validation rules before committing to database
7. **Audit Trail**: All commissioner actions must be logged with timestamp, actor, and action details
8. **Role Inheritance**: Higher roles inherit all permissions of lower roles
9. **Setting Propagation**: League setting changes apply immediately unless otherwise specified
10. **Removal Accountability**: Removed picks must include reason and can only be restored by commissioner

---

## Integration Points

| Component | Integration Description |
|-----------|------------------------|
| **User Authentication** | Validates user identity and retrieves role assignments |
| **Draft Engine** | Receives pick status updates and trade executions |
| **Notification Service** | Sends alerts for trades, picks, and announcements |
| **Statistics Database** | Stores and retrieves imported historical data |
| **Archive Storage** | Persists finalized draft grids for historical access |
| **Audit Logging** | Records all administrative actions for compliance |
| **Export Service** | Generates reports and data exports |

---

## User Interface Components

### Commissioner Dashboard

```
+----------------------------------------------------------+
|  League Management Dashboard                    [Settings]|
+----------------------------------------------------------+
|  Quick Actions                                            |
|  [Add User] [Set Draft Order] [Import Stats] [Finalize]  |
+------------------+---------------------------------------+
|  League Status   |  Recent Activity                      |
|  -------------   |  ---------------------------------    |
|  Teams: 12/12    |  - Trade proposed: Team A <> Team B  |
|  Status: Active  |  - New user joined: John Smith       |
|  Draft: Mar 15   |  - Pick traded: Round 2, Pick 5      |
|                  |  - Stats imported: 2025 Season       |
+------------------+---------------------------------------+
|  Deputy Commissioners              |  Season Grids       |
|  -------------------------         |  ---------------    |
|  [+] Mike Johnson (Full)           |  2026: Active       |
|  [+] Sarah Williams (Limited)      |  2027: Future       |
|  [Manage Deputies]                 |  2028: Future       |
|                                    |  [Manage Grids]     |
+------------------------------------+---------------------+
```

### Pick Status Manager

```
+----------------------------------------------------------+
|  Draft Pick Manager - Season 2026                         |
+----------------------------------------------------------+
|  Filter: [All Rounds v] [All Teams v] [All Status v]     |
+----------------------------------------------------------+
|  Round | Pick | Original Owner | Current Owner | Status  |
|  ------|------|----------------|---------------|---------|
|  1     | 1    | Team Alpha     | Team Alpha    | Avail   |
|  1     | 2    | Team Beta      | Team Gamma    | Traded  |
|  1     | 3    | Team Delta     | --            | Removed |
|  2     | 1    | Team Alpha     | Team Alpha    | Selected|
+----------------------------------------------------------+
|  Actions: [Trade Pick] [Remove Pick] [Restore] [Export]  |
+----------------------------------------------------------+
```

---

## Related Documents

| Document | Relationship | Description |
|----------|--------------|-------------|
| baseball-draft-overview.prompt.md | Parent | Main platform specification |
| draft-engine.prompt.md | Sibling | Draft execution logic and algorithms |
| api-specification.prompt.md | Sibling | REST and WebSocket API definitions |
| user-authentication.prompt.md | Related | User identity and access control |
| notification-system.prompt.md | Related | Alert and messaging specifications |

---

## Future Considerations

- **League Templates**: Pre-configured league setting templates for quick setup
- **Permission Presets**: Named permission bundles for common deputy roles
- **Automated Dispute Resolution**: AI-assisted trade fairness evaluation
- **Cross-League Pick Trading**: Trading picks between leagues (keeper leagues)
- **Commissioner Voting**: Multi-commissioner consensus for critical decisions
- **Bulk Operations API**: Batch processing for large-scale administrative tasks
- **Mobile Commissioner App**: Dedicated mobile interface for league management
- **Webhook Notifications**: External system integration for commissioner events
- **Advanced Analytics**: Historical trend analysis across seasons

---

## Change Log

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2026-01-05 | Initial | Initial prompt creation with user roles, team settings, commissioner tools, pick trading, draft finalization, archive system, multi-season grids, and statistics import |
