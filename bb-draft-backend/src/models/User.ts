import { GetCommand, PutCommand } from '@aws-sdk/lib-dynamodb';
import { getDocClient } from '../config/database';
import { User } from '../types';

const TABLE_NAME = 'bb_draft_users';

export async function getUser(userId: string): Promise<User | null> {
  const client = getDocClient();
  const result = await client.send(
    new GetCommand({
      TableName: TABLE_NAME,
      Key: { userId },
    })
  );
  return (result.Item as User) || null;
}

export async function putUser(user: User): Promise<void> {
  const client = getDocClient();
  await client.send(
    new PutCommand({
      TableName: TABLE_NAME,
      Item: user,
    })
  );
}

export async function upsertUser(userId: string, data: Partial<User>): Promise<User> {
  const existing = await getUser(userId);
  const now = new Date().toISOString();

  const user: User = {
    userId,
    email: data.email || existing?.email || '',
    displayName: data.displayName || existing?.displayName || '',
    photoUrl: data.photoUrl || existing?.photoUrl,
    preferences: data.preferences || existing?.preferences,
    createdAt: existing?.createdAt || now,
    updatedAt: now,
  };

  await putUser(user);
  return user;
}
