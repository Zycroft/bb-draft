// User types
export interface User {
  userId: string;
  email: string;
  displayName: string;
  photoUrl?: string;
  createdAt: string;
  updatedAt: string;
  preferences?: UserPreferences;
}

export interface UserPreferences {
  notifications: {
    draftReminders: boolean;
    pickNotifications: boolean;
    emailDigest: 'daily' | 'weekly' | 'never';
  };
  timezone: string;
}

// API Response types
export interface ApiError {
  error: string;
  message: string;
  details?: any;
}
