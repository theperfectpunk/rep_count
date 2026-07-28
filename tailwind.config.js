/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './app/**/*.{js,jsx,ts,tsx}',
    './src/**/*.{js,jsx,ts,tsx}',
  ],
  presets: [require('nativewind/preset')],
  theme: {
    extend: {
      colors: {
        primary: '#0A0A0F',
        card: '#14141F',
        elevated: '#1E1E2E',
        accent: '#6C5CE7',
        'accent-glow': '#A29BFE',
        success: '#00E676',
        warning: '#FFD600',
        danger: '#FF5252',
        'text-primary': '#F0F0F5',
        'text-secondary': '#8888A0',
      },
      fontFamily: {
        inter: ['Inter'],
        'inter-bold': ['Inter-Bold'],
        'space-grotesk': ['SpaceGrotesk'],
        'space-grotesk-bold': ['SpaceGrotesk-Bold'],
      },
    },
  },
  plugins: [],
};
