import * as admin from 'firebase-admin';
import path from 'path';

let firebaseApp: admin.app.App | null = null;

function isSkipAuth(): boolean {
  return process.env.FIREBASE_SKIP_AUTH === 'true';
}

export function initializeFirebase(): void {
  if (isSkipAuth()) {
    console.log('Firebase auth is disabled (FIREBASE_SKIP_AUTH=true)');
    return;
  }

  const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;

  if (serviceAccountPath) {
    // Use service account file if provided
    const serviceAccount = require(path.resolve(serviceAccountPath));
    firebaseApp = admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
  } else {
    // Use application default credentials (for Cloud environments)
    firebaseApp = admin.initializeApp({
      credential: admin.credential.applicationDefault(),
    });
  }
}

export function getFirebaseApp(): admin.app.App | null {
  return firebaseApp;
}

export function getAuth(): admin.auth.Auth | null {
  if (isSkipAuth() || !firebaseApp) return null;
  return admin.auth();
}

export async function verifyIdToken(token: string): Promise<admin.auth.DecodedIdToken> {
  if (isSkipAuth()) {
    // Return a mock decoded token for development
    return {
      uid: 'dev-user',
      email: 'dev@example.com',
      name: 'Dev User',
      aud: 'dev',
      auth_time: Math.floor(Date.now() / 1000),
      exp: Math.floor(Date.now() / 1000) + 3600,
      iat: Math.floor(Date.now() / 1000),
      iss: 'dev',
      sub: 'dev-user',
      firebase: {
        identities: {},
        sign_in_provider: 'dev',
      },
    } as admin.auth.DecodedIdToken;
  }
  return admin.auth().verifyIdToken(token);
}

export function isAuthSkipped(): boolean {
  return isSkipAuth();
}
