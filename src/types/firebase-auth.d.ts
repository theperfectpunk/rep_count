import '@firebase/auth';

declare module 'firebase/auth' {
  export * from '@firebase/auth';
  export function getReactNativePersistence(storage: any): any;
  export function initializeAuth(app: any, config?: any): any;
}
