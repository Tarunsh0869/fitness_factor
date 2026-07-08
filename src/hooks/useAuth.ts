import { useState, useEffect } from 'react';
import { authService } from '../services/authService';

export const useAuth = () => {
  const [user, setUser] = useState(authService.getCurrentUser());
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const unsubscribe = authService.onAuthStateChanged((updatedUser) => {
      setUser(updatedUser);
      setLoading(false);
    });

    return () => {
      unsubscribe();
    };
  }, []);

  return { user, loading };
};