import { Router, Request, Response } from 'express';
import { authMiddleware } from '../middleware/auth';
import * as UserModel from '../models/User';

const router = Router();

// Sync Firebase user to DynamoDB
router.post('/sync', authMiddleware, async (req: Request, res: Response) => {
  try {
    const user = await UserModel.upsertUser(req.user!.uid, {
      email: req.user!.email,
      displayName: req.user!.name || req.body.displayName,
      photoUrl: req.user!.picture || req.body.photoUrl,
    });

    res.json(user);
  } catch (error: any) {
    console.error('Error syncing user:', error);
    res.status(500).json({ error: 'Failed to sync user', message: error.message });
  }
});

// Get current user profile
router.get('/me', authMiddleware, async (req: Request, res: Response) => {
  try {
    const user = await UserModel.getUser(req.user!.uid);
    if (!user) {
      // Auto-create user if doesn't exist
      const newUser = await UserModel.upsertUser(req.user!.uid, {
        email: req.user!.email,
        displayName: req.user!.name,
        photoUrl: req.user!.picture,
      });
      res.json(newUser);
      return;
    }
    res.json(user);
  } catch (error: any) {
    console.error('Error getting user:', error);
    res.status(500).json({ error: 'Failed to get user', message: error.message });
  }
});

// Update user profile
router.put('/me', authMiddleware, async (req: Request, res: Response) => {
  try {
    const { displayName, photoUrl, preferences } = req.body;
    const user = await UserModel.upsertUser(req.user!.uid, {
      displayName,
      photoUrl,
      preferences,
    });
    res.json(user);
  } catch (error: any) {
    console.error('Error updating user:', error);
    res.status(500).json({ error: 'Failed to update user', message: error.message });
  }
});

export default router;
