import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, ScanCommand, UpdateCommand } from '@aws-sdk/lib-dynamodb';
import dotenv from 'dotenv';

dotenv.config();

const MLB_API_BASE = 'https://statsapi.mlb.com/api/v1';

interface BatterStats {
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

interface PitcherStats {
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

interface PlayerStats {
  batting?: BatterStats;
  pitching?: PitcherStats;
}

async function fetchPlayerStats(mlbId: number, season: number): Promise<PlayerStats | null> {
  try {
    const url = `${MLB_API_BASE}/people/${mlbId}/stats?stats=season&season=${season}&group=hitting,pitching`;
    const response = await fetch(url);
    const data = await response.json() as any;

    if (!data.stats || data.stats.length === 0) {
      return null;
    }

    const stats: PlayerStats = {};

    for (const statGroup of data.stats) {
      if (!statGroup.splits || statGroup.splits.length === 0) continue;

      const split = statGroup.splits[0];
      const s = split.stat;

      if (statGroup.group?.displayName === 'hitting' && s.atBats > 0) {
        stats.batting = {
          gamesPlayed: s.gamesPlayed || 0,
          atBats: s.atBats || 0,
          runs: s.runs || 0,
          hits: s.hits || 0,
          doubles: s.doubles || 0,
          triples: s.triples || 0,
          homeRuns: s.homeRuns || 0,
          rbi: s.rbi || 0,
          stolenBases: s.stolenBases || 0,
          caughtStealing: s.caughtStealing || 0,
          walks: s.baseOnBalls || 0,
          strikeouts: s.strikeOuts || 0,
          avg: s.avg || '.000',
          obp: s.obp || '.000',
          slg: s.slg || '.000',
          ops: s.ops || '.000',
        };
      }

      if (statGroup.group?.displayName === 'pitching' && parseFloat(s.inningsPitched || '0') > 0) {
        stats.pitching = {
          wins: s.wins || 0,
          losses: s.losses || 0,
          era: s.era || '0.00',
          games: s.gamesPlayed || 0,
          gamesStarted: s.gamesStarted || 0,
          saves: s.saves || 0,
          inningsPitched: s.inningsPitched || '0.0',
          hits: s.hits || 0,
          runs: s.runs || 0,
          earnedRuns: s.earnedRuns || 0,
          homeRuns: s.homeRuns || 0,
          walks: s.baseOnBalls || 0,
          strikeouts: s.strikeOuts || 0,
          whip: s.whip || '0.00',
          avg: s.avg || '.000',
        };
      }
    }

    return Object.keys(stats).length > 0 ? stats : null;
  } catch (error) {
    return null;
  }
}

async function getAllPlayers(docClient: DynamoDBDocumentClient): Promise<Array<{ playerId: string; mlbId: number; fullName: string }>> {
  const players: Array<{ playerId: string; mlbId: number; fullName: string }> = [];
  let lastKey: any = undefined;

  do {
    const result = await docClient.send(new ScanCommand({
      TableName: 'bb_draft_players',
      ProjectionExpression: 'playerId, mlbId, fullName',
      ExclusiveStartKey: lastKey,
    }));

    if (result.Items) {
      players.push(...result.Items as any[]);
    }
    lastKey = result.LastEvaluatedKey;
  } while (lastKey);

  return players;
}

async function updatePlayerStats(
  docClient: DynamoDBDocumentClient,
  playerId: string,
  stats: PlayerStats
): Promise<void> {
  await docClient.send(new UpdateCommand({
    TableName: 'bb_draft_players',
    Key: { playerId },
    UpdateExpression: 'SET stats = :stats, lastUpdated = :updated',
    ExpressionAttributeValues: {
      ':stats': stats,
      ':updated': new Date().toISOString(),
    },
  }));
}

async function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}

async function main() {
  const season = 2024;
  console.log(`Importing ${season} stats for MLB players...\n`);

  const dynamoClient = new DynamoDBClient({
    endpoint: process.env.DYNAMODB_ENDPOINT || 'http://localhost:8000',
    region: process.env.DYNAMODB_REGION || 'us-east-1',
    credentials: {
      accessKeyId: process.env.AWS_ACCESS_KEY_ID || 'local',
      secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY || 'local',
    },
  });

  const docClient = DynamoDBDocumentClient.from(dynamoClient, {
    marshallOptions: { removeUndefinedValues: true },
  });

  console.log('Fetching player list from DynamoDB...');
  const players = await getAllPlayers(docClient);
  console.log(`Found ${players.length} players\n`);

  let updated = 0;
  let skipped = 0;
  let errors = 0;
  const batchSize = 50;

  for (let i = 0; i < players.length; i++) {
    const player = players[i];

    try {
      const stats = await fetchPlayerStats(player.mlbId, season);

      if (stats) {
        await updatePlayerStats(docClient, player.playerId, stats);
        updated++;

        const hasB = stats.batting ? 'B' : '-';
        const hasP = stats.pitching ? 'P' : '-';
        process.stdout.write(`\r[${hasB}${hasP}] Updated ${updated} | Skipped ${skipped} | Errors ${errors} | ${i + 1}/${players.length}`);
      } else {
        skipped++;
        process.stdout.write(`\r[--] Updated ${updated} | Skipped ${skipped} | Errors ${errors} | ${i + 1}/${players.length}`);
      }

      // Rate limit: ~20 requests per second
      if ((i + 1) % batchSize === 0) {
        await sleep(2500);
      }
    } catch (error) {
      errors++;
      process.stdout.write(`\r[!!] Updated ${updated} | Skipped ${skipped} | Errors ${errors} | ${i + 1}/${players.length}`);
    }
  }

  console.log('\n\n--- Summary ---');
  console.log(`Total players: ${players.length}`);
  console.log(`Updated with stats: ${updated}`);
  console.log(`No ${season} stats: ${skipped}`);
  console.log(`Errors: ${errors}`);
}

main().catch(console.error);
