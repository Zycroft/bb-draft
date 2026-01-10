import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient } from '@aws-sdk/lib-dynamodb';

let dynamoClient: DynamoDBClient;
let docClient: DynamoDBDocumentClient;

export async function initializeDynamoDB(): Promise<void> {
  dynamoClient = new DynamoDBClient({
    endpoint: process.env.DYNAMODB_ENDPOINT || 'http://localhost:8000',
    region: process.env.DYNAMODB_REGION || 'us-east-1',
    credentials: {
      accessKeyId: process.env.AWS_ACCESS_KEY_ID || 'local',
      secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY || 'local',
    },
  });

  docClient = DynamoDBDocumentClient.from(dynamoClient, {
    marshallOptions: {
      removeUndefinedValues: true,
    },
  });
}

export function getDynamoClient(): DynamoDBClient {
  return dynamoClient;
}

export function getDocClient(): DynamoDBDocumentClient {
  return docClient;
}

// Export docClient directly for easier imports
export { docClient };

// Table names
export const TABLES = {
  USERS: 'bb_draft_users',
  VERSIONS: 'bb_draft_versions',
};

// Alias for backward compatibility
export const TableNames = TABLES;
