import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { createServer } from 'http';
import dotenv from 'dotenv';

import { initializeFirebase } from './config/firebase';
import { initializeDynamoDB } from './config/database';

// Routes
import healthRoutes from './routes/health';
import userRoutes from './routes/users';
import versionRoutes from './routes/version';

dotenv.config();

const app = express();
const httpServer = createServer(app);

// Middleware
app.use(helmet());

// CORS configuration - allow production and localhost for development
const allowedOrigins = [
  'https://zycroft.duckdns.org',
  'http://localhost:8080',
  'http://localhost:8081',
  'http://127.0.0.1:8080',
  'http://127.0.0.1:8081',
];
app.use(cors({
  origin: (origin, callback) => {
    // Allow requests with no origin (like mobile apps or curl)
    if (!origin) return callback(null, true);
    if (allowedOrigins.includes(origin)) {
      return callback(null, true);
    }
    return callback(null, false);
  },
  credentials: true,
}));
app.use(express.json());

// Health routes
app.use('/health', healthRoutes);

// Version routes
app.use('/version', versionRoutes);

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
