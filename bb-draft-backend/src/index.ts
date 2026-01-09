import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { createServer } from 'http';
import dotenv from 'dotenv';

import { initializeFirebase } from './config/firebase';
import { initializeDynamoDB } from './config/database';

// Routes
import userRoutes from './routes/users';

dotenv.config();

const app = express();
const httpServer = createServer(app);

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
