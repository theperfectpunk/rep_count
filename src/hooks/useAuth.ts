import { useState, useEffect } from 'react';
import { onAuthStateChanged, User } from 'firebase/auth';
import { doc, getDoc } from 'firebase/firestore';
import { auth, db } from '../config/firebase';

export interface UserProfile {
  uid: string;
  email?: string | null;
  displayName?: string | null;
  activePlanId?: string | null;
  [key: string]: any;
}

export function useAuth() {
  const [user, setUser] = useState<User | null>(auth.currentUser);
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [loading, setLoading] = useState<boolean>(true);

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (currentUser) => {
      setUser(currentUser);
      if (currentUser) {
        try {
          const userDoc = await getDoc(doc(db, 'users', currentUser.uid));
          if (userDoc.exists()) {
            setProfile({ uid: currentUser.uid, ...userDoc.data() } as UserProfile);
          } else {
            setProfile({ uid: currentUser.uid, email: currentUser.email, displayName: currentUser.displayName });
          }
        } catch (e) {
          setProfile({ uid: currentUser.uid, email: currentUser.email, displayName: currentUser.displayName });
        }
      } else {
        setProfile(null);
      }
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  return { user, profile, loading };
}
