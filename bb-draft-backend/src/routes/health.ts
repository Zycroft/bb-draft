import { Router, Request, Response } from 'express';
import { getDynamoClient } from '../config/database';
import { ListTablesCommand } from '@aws-sdk/client-dynamodb';

const router = Router();

// Basic health check
router.get('/', (req: Request, res: Response) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Database connectivity check
router.get('/db', async (req: Request, res: Response) => {
  try {
    const dynamoClient = getDynamoClient();

    // Try to list tables as a connectivity test
    await dynamoClient.send(new ListTablesCommand({ Limit: 1 }));

    res.json({
      status: 'ok',
      database: 'connected',
      timestamp: new Date().toISOString(),
    });
  } catch (error: any) {
    console.error('Database health check failed:', error.message);
    res.status(503).json({
      status: 'error',
      database: 'disconnected',
      timestamp: new Date().toISOString(),
    });
  }
});

export default router;
