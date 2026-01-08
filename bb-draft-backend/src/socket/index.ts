import { Server, Socket } from 'socket.io';
import { verifyIdToken } from '../config/firebase';
import { setupDraftRoom } from './draftRoom';

interface AuthenticatedSocket extends Socket {
  userId?: string;
}

export function initializeSocket(io: Server): void {
  // Authentication middleware
  io.use(async (socket: AuthenticatedSocket, next) => {
    const token = socket.handshake.auth?.token;

    if (!token) {
      return next(new Error('Authentication required'));
    }

    try {
      const decoded = await verifyIdToken(token);
      socket.userId = decoded.uid;
      next();
    } catch (error) {
      next(new Error('Invalid token'));
    }
  });

  io.on('connection', (socket: AuthenticatedSocket) => {
    console.log(`User connected: ${socket.userId}`);

    // Set up draft room handlers
    setupDraftRoom(io, socket);

    socket.on('disconnect', () => {
      console.log(`User disconnected: ${socket.userId}`);
    });

    socket.on('error', (error) => {
      console.error(`Socket error for user ${socket.userId}:`, error);
    });
  });
}
