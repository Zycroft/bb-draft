import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, BatchWriteCommand } from '@aws-sdk/lib-dynamodb';
import dotenv from 'dotenv';

dotenv.config();

const MLB_API_BASE = 'https://statsapi.mlb.com/api/v1';

interface MLBPlayer {
  id: number;
  fullName: string;
  firstName: string;
  lastName: string;
  primaryPosition: { abbreviation: string };
  currentTeam?: { id: number; name: string };
  jerseyNumber?: string;
  batSide?: { code: string };
  pitchHand?: { code: string };
  birthDate?: string;
  height?: string;
  weight?: number;
  active: boolean;
}

interface Player {
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
  lastUpdated: string;
}

async function fetchMLBPlayers(season: number): Promise<MLBPlayer[]> {
  const response = await fetch(`${MLB_API_BASE}/sports/1/players?season=${season}`);
  const data = await response.json() as { people?: MLBPlayer[] };
  return data.people || [];
}

function transformPlayer(mlbPlayer: MLBPlayer): Player {
  return {
    playerId: `mlb_${mlbPlayer.id}`,
    mlbId: mlbPlayer.id,
    fullName: mlbPlayer.fullName,
    firstName: mlbPlayer.firstName,
    lastName: mlbPlayer.lastName,
    primaryPosition: mlbPlayer.primaryPosition?.abbreviation || 'Unknown',
    mlbTeam: mlbPlayer.currentTeam?.name || 'Free Agent',
    mlbTeamId: mlbPlayer.currentTeam?.id || 0,
    jerseyNumber: mlbPlayer.jerseyNumber,
    batSide: mlbPlayer.batSide?.code || 'Unknown',
    pitchHand: mlbPlayer.pitchHand?.code || 'Unknown',
    birthDate: mlbPlayer.birthDate,
    height: mlbPlayer.height,
    weight: mlbPlayer.weight,
    active: mlbPlayer.active,
    lastUpdated: new Date().toISOString(),
  };
}

async function batchWritePlayers(docClient: DynamoDBDocumentClient, players: Player[]): Promise<number> {
  const BATCH_SIZE = 25;
  let written = 0;

  for (let i = 0; i < players.length; i += BATCH_SIZE) {
    const batch = players.slice(i, i + BATCH_SIZE);
    const putRequests = batch.map(player => ({
      PutRequest: { Item: player }
    }));

    try {
      await docClient.send(new BatchWriteCommand({
        RequestItems: {
          'bb_draft_players': putRequests
        }
      }));
      written += batch.length;
      process.stdout.write(`\rWritten ${written}/${players.length} players...`);
    } catch (error) {
      console.error(`\nError writing batch at index ${i}:`, error);
    }
  }

  console.log('\n');
  return written;
}

async function main() {
  console.log('Initializing DynamoDB client...');

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

  console.log('Fetching MLB players for 2025 season...');
  const mlbPlayers = await fetchMLBPlayers(2025);
  console.log(`Found ${mlbPlayers.length} players`);

  console.log('Transforming player data...');
  const players = mlbPlayers.map(transformPlayer);

  // Count by position
  const positionCounts: Record<string, number> = {};
  players.forEach(p => {
    positionCounts[p.primaryPosition] = (positionCounts[p.primaryPosition] || 0) + 1;
  });
  console.log('\nPlayers by position:');
  Object.entries(positionCounts)
    .sort((a, b) => b[1] - a[1])
    .forEach(([pos, count]) => console.log(`  ${pos}: ${count}`));

  console.log('\nWriting to DynamoDB...');
  const written = await batchWritePlayers(docClient, players);
  console.log(`Successfully imported ${written} players!`);
}

main().catch(console.error);
