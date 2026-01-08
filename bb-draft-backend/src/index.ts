import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { createServer } from 'http';
import { Server } from 'socket.io';
import dotenv from 'dotenv';

import { initializeFirebase } from './config/firebase';
import { initializeDynamoDB, createTables } from './config/database';
import { initializeSocket } from './socket';

// Routes
import userRoutes from './routes/users';
import playerRoutes from './routes/players';
import leagueRoutes from './routes/leagues';
import teamRoutes from './routes/teams';
import draftRoutes from './routes/drafts';
import tradeRoutes from './routes/trades';
import encyclopediaRoutes from './routes/encyclopedia';

dotenv.config();

const app = express();
const httpServer = createServer(app);
const io = new Server(httpServer, {
  cors: {
    origin: process.env.CORS_ORIGIN || '*',
    methods: ['GET', 'POST'],
  },
});

// Middleware
app.use(helmet());
app.use(cors({
  origin: process.env.CORS_ORIGIN || '*',
  credentials: true,
}));
app.use(express.json());

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// API Routes
app.use('/api/users', userRoutes);
app.use('/api/players', playerRoutes);
app.use('/api/leagues', leagueRoutes);
app.use('/api/teams', teamRoutes);
app.use('/api/drafts', draftRoutes);
app.use('/api/trades', tradeRoutes);
app.use('/api/encyclopedia', encyclopediaRoutes);

// Error handler
app.use((err: Error, req: express.Request, res: express.Response, next: express.NextFunction) => {
  console.error('Error:', err);
  res.status(500).json({ error: 'Internal server error', message: err.message });
});

// Initialize services and start server
async function start() {
  try {
    // Initialize Firebase Admin SDK
    initializeFirebase();
    console.log('Firebase initialized');

    // Initialize DynamoDB
    await initializeDynamoDB();
    console.log('DynamoDB connected');

    // Create tables if they don't exist (non-blocking)
    try {
      await createTables();
      console.log('DynamoDB tables ready');
    } catch (tableError) {
      console.warn('Warning: Could not create tables:', (tableError as Error).message);
      console.log('Continuing without table creation...');
    }

    // Initialize Socket.io
    initializeSocket(io);
    console.log('Socket.io initialized');

    const PORT = process.env.PORT || 3000;
    httpServer.listen(PORT, () => {
      console.log(`Server running on port ${PORT}`);
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
}

start();

export { io };
