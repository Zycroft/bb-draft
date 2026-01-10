import { Router, Request, Response } from 'express';
import { getCurrentVersion, getNextVersion } from '../models/Version';

const router = Router();

/**
 * GET /version/current
 * Returns the current version without incrementing the counter
 */
router.get('/current', async (req: Request, res: Response) => {
  try {
    const majorMinorPatch = (req.query.majorMinorPatch as string) || '0.0.0';
    const result = await getCurrentVersion(majorMinorPatch);

    res.json(result);
  } catch (error: any) {
    console.error('Error getting current version:', error.message);
    res.status(500).json({
      error: 'Failed to get current version',
      message: error.message,
    });
  }
});

/**
 * POST /version/next
 * Atomically increments and returns the next version number
 * Used by deployment pipeline to generate new versions
 */
router.post('/next', async (req: Request, res: Response) => {
  try {
    const majorMinorPatch = req.body?.majorMinorPatch || '0.0.0';
    const result = await getNextVersion(majorMinorPatch);

    console.log(`Version incremented: ${result.version}`);
    res.json(result);
  } catch (error: any) {
    console.error('Error incrementing version:', error.message);
    res.status(500).json({
      error: 'Failed to increment version',
      message: error.message,
    });
  }
});

export default router;
