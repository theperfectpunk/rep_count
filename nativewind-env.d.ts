/// <reference types="nativewind/types" />
declare module '*.css';

declare module 'firebase/auth' {
  import type { Persistence } from '@firebase/auth';
  export function getReactNativePersistence(storage: any): Persistence;
}
