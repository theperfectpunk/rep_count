// RepCount Web App Logic

// Polyfill for crypto.randomUUID if in non-secure HTTP context
if (typeof window !== 'undefined' && (!window.crypto || !window.crypto.randomUUID)) {
  if (!window.crypto) window.crypto = {};
  window.crypto.randomUUID = function() {
    return '10000000-1000-4000-8000-100000000000'.replace(/[018]/g, function(c) {
      var r = (window.crypto.getRandomValues ? window.crypto.getRandomValues(new Uint8Array(1))[0] : Math.floor(Math.random() * 256));
      return (c ^ (r & 15 >> c / 4)).toString(16);
    });
  };
}

let activeWorkout = null;
let timerInterval = null;
let restTimerInterval = null;
let restSeconds = 0;
let currentRestPreset = 90;

let selectedMuscleGroup = 'All';
let selectedSubMuscle = null;

const muscleGroupMap = {
  'Chest': ['Chest'],
  'Back': ['Back'],
  'Shoulders': ['Shoulders'],
  'Legs': ['Quads', 'Hamstrings', 'Glutes', 'Adductors', 'Abductors', 'Calves'],
  'Arms': ['Biceps', 'Triceps', 'Forearms'],
  'Core': ['Abs'],
  'Other': ['Traps']
};

let masterExercises = [
  // CHEST
  { id: 'ex_bench_press', name: 'Barbell Bench Press', muscle: 'Chest', subMuscle: 'Mid Chest', equipment: 'Barbell', oneRepMax: 125 },
  { id: 'ex_incline_db_press', name: 'Incline Dumbbell Press', muscle: 'Chest', subMuscle: 'Upper Chest', equipment: 'Dumbbell', oneRepMax: 40 },
  { id: 'ex_cable_flyes', name: 'High-to-Low Cable Flyes', muscle: 'Chest', subMuscle: 'Lower Chest', equipment: 'Cable', oneRepMax: 32.5 },
  { id: 'ex_chest_dips', name: 'Weighted Chest Dips', muscle: 'Chest', subMuscle: 'Lower Chest', equipment: 'Dip Station', oneRepMax: 45 },

  // BACK / LATS
  { id: 'ex_pull_ups', name: 'Bodyweight Pull-Ups', muscle: 'Back', subMuscle: 'Lats', equipment: 'Pull-Up Bar', oneRepMax: 105 },
  { id: 'ex_barbell_row', name: 'Bent-Over Barbell Row', muscle: 'Back', subMuscle: 'Mid Back', equipment: 'Barbell', oneRepMax: 100 },
  { id: 'ex_lat_pulldown', name: 'Wide-Grip Lat Pulldown', muscle: 'Back', subMuscle: 'Lats', equipment: 'Cable', oneRepMax: 85 },
  { id: 'ex_seated_cable_row', name: 'Seated Cable Row', muscle: 'Back', subMuscle: 'Mid Back', equipment: 'Cable', oneRepMax: 90 },

  // SHOULDERS
  { id: 'ex_overhead_press', name: 'Overhead Barbell Press', muscle: 'Shoulders', subMuscle: 'Front Delt', equipment: 'Barbell', oneRepMax: 75 },
  { id: 'ex_db_lateral_raise', name: 'Dumbbell Lateral Raise', muscle: 'Shoulders', subMuscle: 'Side Delt', equipment: 'Dumbbell', oneRepMax: 17.5 },
  { id: 'ex_face_pulls', name: 'Rope Face Pulls', muscle: 'Shoulders', subMuscle: 'Rear Delt', equipment: 'Cable', oneRepMax: 35 },
  { id: 'ex_arnold_press', name: 'Dumbbell Arnold Press', muscle: 'Shoulders', subMuscle: 'Front Delt', equipment: 'Dumbbell', oneRepMax: 30 },

  // QUADS
  { id: 'ex_squat', name: 'Barbell Back Squat', muscle: 'Quads', subMuscle: 'Quads', equipment: 'Barbell', oneRepMax: 160 },
  { id: 'ex_leg_press', name: '45-Degree Leg Press', muscle: 'Quads', subMuscle: 'Quads', equipment: 'Machine', oneRepMax: 280 },
  { id: 'ex_leg_extension', name: 'Seated Leg Extension', muscle: 'Quads', subMuscle: 'Quads', equipment: 'Machine', oneRepMax: 90 },
  { id: 'ex_bulgarian_split_squat', name: 'Dumbbell Bulgarian Split Squat', muscle: 'Quads', subMuscle: 'Quads', equipment: 'Dumbbell', oneRepMax: 32 },

  // HAMSTRINGS & GLUTES
  { id: 'ex_deadlift', name: 'Conventional Deadlift', muscle: 'Hamstrings', subMuscle: 'Hamstrings', equipment: 'Barbell', oneRepMax: 190 },
  { id: 'ex_romanian_deadlift', name: 'Barbell Romanian Deadlift (RDL)', muscle: 'Hamstrings', subMuscle: 'Hamstrings', equipment: 'Barbell', oneRepMax: 140 },
  { id: 'ex_lying_leg_curl', name: 'Lying Leg Curl', muscle: 'Hamstrings', subMuscle: 'Hamstrings', equipment: 'Machine', oneRepMax: 65 },
  { id: 'ex_hip_thrust', name: 'Barbell Hip Thrust', muscle: 'Glutes', subMuscle: 'Glutes', equipment: 'Barbell', oneRepMax: 180 },

  // BICEPS & FOREARMS
  { id: 'ex_barbell_curl', name: 'EZ-Bar Bicep Curl', muscle: 'Biceps', subMuscle: 'Biceps', equipment: 'EZ-Bar', oneRepMax: 45 },
  { id: 'ex_hammer_curl', name: 'Dumbbell Hammer Curl', muscle: 'Biceps', subMuscle: 'Biceps', equipment: 'Dumbbell', oneRepMax: 22.5 },
  { id: 'ex_incline_bicep_curl', name: 'Incline Dumbbell Curl', muscle: 'Biceps', subMuscle: 'Biceps', equipment: 'Dumbbell', oneRepMax: 18 },

  // TRICEPS
  { id: 'ex_tricep_pushdown', name: 'Rope Tricep Pushdown', muscle: 'Triceps', subMuscle: 'Triceps', equipment: 'Cable', oneRepMax: 35 },
  { id: 'ex_skull_crushers', name: 'Lying EZ-Bar Skull Crushers', muscle: 'Triceps', subMuscle: 'Triceps', equipment: 'EZ-Bar', oneRepMax: 40 },
  { id: 'ex_overhead_tricep_ext', name: 'Overhead Dumbbell Tricep Extension', muscle: 'Triceps', subMuscle: 'Triceps', equipment: 'Dumbbell', oneRepMax: 30 },

  // CALVES
  { id: 'ex_standing_calf_raise', name: 'Standing Machine Calf Raise', muscle: 'Calves', subMuscle: 'Calves', equipment: 'Machine', oneRepMax: 110 },
  { id: 'ex_seated_calf_raise', name: 'Seated Calf Raise', muscle: 'Calves', subMuscle: 'Calves', equipment: 'Machine', oneRepMax: 70 },

  // ABS / CORE
  { id: 'ex_hanging_leg_raise', name: 'Hanging Leg Raise', muscle: 'Abs', subMuscle: 'Lower Abs', equipment: 'Pull-Up Bar', oneRepMax: 0 },
  { id: 'ex_ab_wheel_rollout', name: 'Ab Wheel Rollout', muscle: 'Abs', subMuscle: 'Upper Abs', equipment: 'Ab Wheel', oneRepMax: 0 },
  { id: 'ex_cable_crunch', name: 'Kneeling Cable Crunch', muscle: 'Abs', subMuscle: 'Upper Abs', equipment: 'Cable', oneRepMax: 50 },

  // GLUTES (NEW)
  { id: 'ex_glute_bridge', name: 'Barbell Glute Bridge', muscle: 'Glutes', subMuscle: 'Glutes', equipment: 'Barbell', oneRepMax: 120 },
  { id: 'ex_cable_kickback', name: 'Cable Glute Kickback', muscle: 'Glutes', subMuscle: 'Glutes', equipment: 'Cable', oneRepMax: 25 },
  { id: 'ex_step_up', name: 'Dumbbell Step-Up', muscle: 'Glutes', subMuscle: 'Glutes', equipment: 'Dumbbell', oneRepMax: 30 },

  // CHEST (extra)
  { id: 'ex_decline_bench', name: 'Decline Barbell Bench Press', muscle: 'Chest', subMuscle: 'Lower Chest', equipment: 'Barbell', oneRepMax: 90 },
  { id: 'ex_low_cable_fly', name: 'Low-to-High Cable Fly', muscle: 'Chest', subMuscle: 'Upper Chest', equipment: 'Cable', oneRepMax: 20 },

  // BACK (extra)
  { id: 'ex_tbar_row', name: 'T-Bar Row', muscle: 'Back', subMuscle: 'Mid Back', equipment: 'Barbell', oneRepMax: 80 },
  { id: 'ex_back_extension', name: 'Back Extension (Hyperextension)', muscle: 'Back', subMuscle: 'Lower Back', equipment: 'Bodyweight', oneRepMax: 0 },
  { id: 'ex_straight_arm_pulldown', name: 'Straight-Arm Cable Pulldown', muscle: 'Back', subMuscle: 'Lats', equipment: 'Cable', oneRepMax: 30 },

  // SHOULDERS (extra)
  { id: 'ex_reverse_fly', name: 'Dumbbell Reverse Fly', muscle: 'Shoulders', subMuscle: 'Rear Delt', equipment: 'Dumbbell', oneRepMax: 12 },
  { id: 'ex_cable_lateral_raise', name: 'Cable Lateral Raise', muscle: 'Shoulders', subMuscle: 'Side Delt', equipment: 'Cable', oneRepMax: 10 },

  // TRAPS
  { id: 'ex_barbell_shrug', name: 'Barbell Shrug', muscle: 'Traps', subMuscle: 'Traps', equipment: 'Barbell', oneRepMax: 100 },
  { id: 'ex_db_shrug', name: 'Dumbbell Shrug', muscle: 'Traps', subMuscle: 'Traps', equipment: 'Dumbbell', oneRepMax: 40 },

  // FOREARMS
  { id: 'ex_wrist_curl', name: 'Barbell Wrist Curl', muscle: 'Forearms', subMuscle: 'Forearms', equipment: 'Barbell', oneRepMax: 30 },
  { id: 'ex_reverse_wrist_curl', name: 'Reverse Barbell Wrist Curl', muscle: 'Forearms', subMuscle: 'Forearms', equipment: 'Barbell', oneRepMax: 20 },

  // ADDUCTORS & ABDUCTORS
  { id: 'ex_hip_adduction', name: 'Machine Hip Adduction', muscle: 'Adductors', subMuscle: 'Adductors', equipment: 'Machine', oneRepMax: 70 },
  { id: 'ex_hip_abduction', name: 'Machine Hip Abduction', muscle: 'Abductors', subMuscle: 'Abductors', equipment: 'Machine', oneRepMax: 60 },
  { id: 'ex_sumo_squat', name: 'Dumbbell Sumo Squat', muscle: 'Adductors', subMuscle: 'Adductors', equipment: 'Dumbbell', oneRepMax: 40 },

  // OBLIQUES / CORE
  { id: 'ex_russian_twist', name: 'Russian Twist', muscle: 'Abs', subMuscle: 'Obliques', equipment: 'Bodyweight', oneRepMax: 0 },
  { id: 'ex_side_plank', name: 'Side Plank', muscle: 'Abs', subMuscle: 'Obliques', equipment: 'Bodyweight', oneRepMax: 0 },

  // LEGS (extra)
  { id: 'ex_sissy_squat', name: 'Sissy Squat', muscle: 'Quads', subMuscle: 'Quads', equipment: 'Bodyweight', oneRepMax: 0 },
  { id: 'ex_nordic_curl', name: 'Nordic Hamstring Curl', muscle: 'Hamstrings', subMuscle: 'Hamstrings', equipment: 'Bodyweight', oneRepMax: 0 },
];

let currentUser = null;
let confirmationResult = null;
let recaptchaVerifier = null;
let isDemoMode = false;

async function initFirebaseAndExercises() {
  try {
    const res = await fetch('/api/firebase-config');
    const config = await res.json();
    if (typeof firebase !== 'undefined' && config.projectId) {
      if (!firebase.apps.length) {
        firebase.initializeApp(config);
      }
      setupAuthListener();
      const db = firebase.firestore();
      const snapshot = await db.collection('exercises').get();
      if (!snapshot.empty) {
        masterExercises = snapshot.docs.map(doc => {
          const data = doc.data();
          return {
            id: doc.id,
            name: data.name || doc.id,
            muscle: data.primaryMuscle || data.muscle || 'General',
            equipment: data.equipment || 'Equipment',
            oneRepMax: data.historicalOneRepMax || data.oneRepMax || 0
          };
        });
        localStorage.setItem('cached_exercises_json', JSON.stringify(masterExercises));
        renderExerciseList();
        return;
      }
    }
  } catch (err) {
    console.warn('Could not load Firebase config/exercises, checking local storage:', err);
    if (typeof firebase !== 'undefined' && firebase.auth) {
      setupAuthListener();
    }
  }

  // Load from persistent local storage if app ran before
  const localCache = localStorage.getItem('cached_exercises_json');
  if (localCache) {
    try {
      masterExercises = JSON.parse(localCache);
      console.log('📦 Loaded exercises from local persistent web cache');
      renderExerciseList();
    } catch (e) {
      console.warn('Error reading local web cache:', e);
    }
  }
}

function setupAuthListener() {
  if (typeof firebase === 'undefined' || !firebase.auth) return;

  try {
    const recaptchaContainer = document.getElementById('recaptcha-container');
    if (recaptchaContainer && !recaptchaVerifier) {
      recaptchaVerifier = new firebase.auth.RecaptchaVerifier('recaptcha-container', {
        size: 'invisible',
        callback: () => {
          console.log('reCAPTCHA solved');
        }
      });
    }
  } catch (e) {
    console.warn('RecaptchaVerifier init warning:', e);
  }

  firebase.auth().onAuthStateChanged(user => {
    currentUser = user;
    const authScreen = document.getElementById('screen-auth');
    const bottomNav = document.querySelector('.bottom-nav');

    if (user) {
      if (authScreen) authScreen.classList.remove('active');
      if (bottomNav) bottomNav.style.display = 'flex';

      updateHeaderProfile(user);
      window.switchTab('dashboard');
    } else {
      document.querySelectorAll('.screen').forEach(s => s.classList.remove('active'));
      if (authScreen) authScreen.classList.add('active');
      if (bottomNav) bottomNav.style.display = 'none';

      resetAuthUI();
    }
  });
}

function updateHeaderProfile(user) {
  const avatarElem = document.getElementById('headerAvatar');
  const nameElem = document.getElementById('headerUserName');
  const subElem = document.getElementById('headerUserSub');

  if (!user) return;

  let displayName = 'Demo User';
  let avatarText = 'DU';

  if (isDemoMode && isDemoMode !== 'anonymous') {
    displayName = '+1 555-555-5555';
    avatarText = 'DU';
  } else if (user.phoneNumber) {
    displayName = user.phoneNumber;
    avatarText = '📱';
  } else if (user.email) {
    displayName = user.email;
    avatarText = user.email.substring(0, 2).toUpperCase();
  } else if (user.isAnonymous) {
    displayName = 'Demo User';
    avatarText = '👤';
  }

  if (nameElem) nameElem.innerText = displayName;
  if (avatarElem) avatarElem.innerText = avatarText;
  if (subElem) subElem.innerText = '🔥 4 Week Streak';
}

function resetAuthUI() {
  const phoneSection = document.getElementById('phoneAuthSection');
  const otpSection = document.getElementById('otpSection');
  const phoneInput = document.getElementById('phoneNumberInput');
  const pinInputs = document.querySelectorAll('.otp-pin-input');

  if (phoneSection) phoneSection.style.display = 'block';
  if (otpSection) otpSection.style.display = 'none';
  if (phoneInput) phoneInput.value = '';
  pinInputs.forEach(i => i.value = '');
  confirmationResult = null;
  isDemoMode = false;
}

async function sendVerificationCode() {
  const countryCode = document.getElementById('countryCodeSelect')?.value || '+1';
  const phoneVal = document.getElementById('phoneNumberInput')?.value.trim() || '';

  if (!phoneVal) {
    showToast('Please enter a phone number', 'warning');
    return;
  }

  const cleanPhone = phoneVal.replace(/\D/g, '');
  const fullPhone = `${countryCode}${cleanPhone}`;

  if (fullPhone === '+15555555555') {
    handleDemoTestNumber();
    return;
  }

  if (typeof firebase === 'undefined' || !firebase.auth) {
    showToast('Firebase Auth not available. Using demo login.', 'warning');
    handleDemoTestNumber();
    return;
  }

  showToast('Sending verification code...', 'info');

  try {
    if (!recaptchaVerifier) {
      recaptchaVerifier = new firebase.auth.RecaptchaVerifier('recaptcha-container', { size: 'invisible' });
    }
    confirmationResult = await firebase.auth().signInWithPhoneNumber(fullPhone, recaptchaVerifier);
    
    document.getElementById('phoneAuthSection').style.display = 'none';
    document.getElementById('otpSection').style.display = 'block';
    const display = document.getElementById('otpPhoneDisplay');
    if (display) display.innerText = `Sent 6-digit code to ${fullPhone}`;
    
    const firstPin = document.querySelector('.otp-pin-input[data-index="0"]');
    if (firstPin) firstPin.focus();

    showToast('Verification code sent!', 'success');
  } catch (err) {
    console.error('Phone Auth Error:', err);
    showToast(`Error: ${err.message || 'Could not send SMS'}`, 'warning');
  }
}

async function verifyOtpCode() {
  const pinInputs = document.querySelectorAll('.otp-pin-input');
  let otpCode = '';
  pinInputs.forEach(input => otpCode += input.value.trim());

  if (otpCode.length < 6) {
    showToast('Please enter all 6 digits', 'warning');
    return;
  }

  showToast('Verifying code...', 'info');

  if (confirmationResult) {
    try {
      await confirmationResult.confirm(otpCode);
      showToast('Successfully authenticated!', 'success');
    } catch (err) {
      console.error('OTP Verification Error:', err);
      if (otpCode === '123456' || isDemoMode) {
        signInAnonymouslyFallback();
      } else {
        showToast('Invalid OTP code. Please try again.', 'warning');
      }
    }
  } else if (otpCode === '123456' || isDemoMode) {
    signInAnonymouslyFallback();
  } else {
    showToast('Signing in anonymously...', 'info');
    signInAnonymouslyFallback();
  }
}

function handleDemoTestNumber() {
  isDemoMode = '+15555555555';
  const countrySelect = document.getElementById('countryCodeSelect');
  const phoneInput = document.getElementById('phoneNumberInput');

  if (countrySelect) countrySelect.value = '+1';
  if (phoneInput) phoneInput.value = '555-555-5555';

  const phoneSection = document.getElementById('phoneAuthSection');
  const otpSection = document.getElementById('otpSection');
  if (phoneSection) phoneSection.style.display = 'none';
  if (otpSection) otpSection.style.display = 'block';

  const display = document.getElementById('otpPhoneDisplay');
  if (display) display.innerText = 'Demo Number: +1 555-555-5555 (OTP: 123456)';

  const demoPin = ['1', '2', '3', '4', '5', '6'];
  document.querySelectorAll('.otp-pin-input').forEach((input, idx) => {
    input.value = demoPin[idx] || '';
  });

  showToast('Demo test values loaded (+1 555-555-5555, OTP: 123456)', 'success');
}

async function signInAnonymouslyFallback() {
  try {
    showToast('Signing in...', 'info');
    if (typeof firebase !== 'undefined' && firebase.auth) {
      await firebase.auth().signInAnonymously();
    } else {
      if (document.getElementById('screen-auth')) document.getElementById('screen-auth').classList.remove('active');
      if (document.querySelector('.bottom-nav')) document.querySelector('.bottom-nav').style.display = 'flex';
      updateHeaderProfile({ isAnonymous: true });
      window.switchTab('dashboard');
    }
    showToast('Signed in successfully!', 'success');
  } catch (err) {
    console.error('Anonymous Sign In Error:', err);
    showToast(`Error: ${err.message}`, 'warning');
  }
}


let routines = [];
let editingRoutineId = null;
let currentEditorExercises = [];
let selectedPickerExercises = new Set();

const defaultRoutines = [
  {
    id: 'push_day_a',
    title: 'Push Day A (Chest/Shoulders/Triceps)',
    folder: 'Custom Workouts',
    duration: 55,
    exercises: [
      {
        name: 'Barbell Bench Press',
        muscle: 'Chest',
        sets: [
          { weight: 60, reps: 10, prev: '55 × 10', completed: false },
          { weight: 80, reps: 8, prev: '75 × 8', completed: false },
          { weight: 100, reps: 6, prev: '95 × 6', completed: false }
        ]
      },
      {
        name: 'Overhead Barbell Press',
        muscle: 'Shoulders',
        sets: [
          { weight: 40, reps: 10, prev: '37.5 × 10', completed: false },
          { weight: 50, reps: 8, prev: '47.5 × 8', completed: false }
        ]
      },
      {
        name: 'High-to-Low Cable Flyes',
        muscle: 'Chest',
        sets: [
          { weight: 20, reps: 12, prev: '17.5 × 12', completed: false },
          { weight: 25, reps: 10, prev: '22.5 × 10', completed: false }
        ]
      }
    ]
  },
  {
    id: 'pull_day_a',
    title: 'Pull Day A (Back/Biceps)',
    folder: 'Custom Workouts',
    duration: 50,
    exercises: [
      {
        name: 'Bodyweight Pull-Ups',
        muscle: 'Back',
        sets: [
          { weight: 0, reps: 10, prev: 'BW × 10', completed: false },
          { weight: 0, reps: 8, prev: 'BW × 8', completed: false }
        ]
      },
      {
        name: 'Conventional Deadlift',
        muscle: 'Hamstrings',
        sets: [
          { weight: 100, reps: 8, prev: '90 × 8', completed: false },
          { weight: 140, reps: 5, prev: '130 × 5', completed: false }
        ]
      },
      {
        name: 'EZ-Bar Bicep Curl',
        muscle: 'Biceps',
        sets: [
          { weight: 30, reps: 12, prev: '25 × 12', completed: false },
          { weight: 35, reps: 10, prev: '30 × 10', completed: false }
        ]
      }
    ]
  }
];

const routineTemplates = {
  'Push Day A': defaultRoutines[0].exercises,
  'Pull Day A': defaultRoutines[1].exercises
};

// Toast Notifications
function showToast(message, type = 'info', duration = 3000) {
  const container = document.getElementById('toastContainer');
  if (!container) return;

  const toast = document.createElement('div');
  toast.className = `toast toast-${type}`;
  const icon = type === 'success' ? '✓' : type === 'warning' ? '⚠️' : 'ℹ️';

  toast.innerHTML = `
    <span class="toast-icon">${icon}</span>
    <span class="toast-message">${message}</span>
  `;

  container.appendChild(toast);

  setTimeout(() => toast.classList.add('show'), 10);

  setTimeout(() => {
    toast.classList.remove('show');
    setTimeout(() => toast.remove(), 300);
  }, duration);
}

window.switchTab = function(tabId) {
  document.querySelectorAll('.screen').forEach(s => s.classList.remove('active'));
  document.querySelectorAll('.nav-item').forEach(n => n.classList.remove('active'));

  const targetScreen = document.getElementById(`screen-${tabId}`);
  if (targetScreen) targetScreen.classList.add('active');

  const indexMap = { dashboard: 0, routines: 1, logger: 2, exercises: 3, analytics: 4 };
  const navItems = document.querySelectorAll('.nav-item');
  if (navItems[indexMap[tabId]]) {
    navItems[indexMap[tabId]].classList.add('active');
  }
};

window.startEmptyWorkout = function(title = 'Quick Workout', initialExercises = []) {
  activeWorkout = {
    title: title,
    startTime: Date.now(),
    durationSeconds: 0,
    exercises: initialExercises
  };

  const headerActions = document.getElementById('workoutHeaderActions');
  if (headerActions) headerActions.style.display = 'flex';

  const titleElem = document.getElementById('activeWorkoutTitle');
  if (titleElem) titleElem.innerText = title;

  if (timerInterval) clearInterval(timerInterval);
  timerInterval = setInterval(() => {
    if (!activeWorkout) return;
    activeWorkout.durationSeconds++;
    const mins = String(Math.floor(activeWorkout.durationSeconds / 60)).padStart(2, '0');
    const secs = String(activeWorkout.durationSeconds % 60).padStart(2, '0');
    const timeElem = document.getElementById('activeWorkoutTime');
    if (timeElem) timeElem.innerText = `⏱️ ${mins}:${secs} • ${calculateTotalVolume().toLocaleString()} kg volume`;
  }, 1000);

  renderWorkoutLogs();
  window.switchTab('logger');
  showToast(`Started ${title}`, 'success');
};

window.startRoutineById = function(id) {
  const routine = routines.find(r => r.id === id || r.title === id);
  if (routine) {
    const exercisesCopy = JSON.parse(JSON.stringify(routine.exercises || []));
    window.startEmptyWorkout(routine.title, exercisesCopy);
  } else {
    const exercises = routineTemplates[id] ? JSON.parse(JSON.stringify(routineTemplates[id])) : [];
    window.startEmptyWorkout(id, exercises);
  }
};

window.startRoutine = function(name) {
  window.startRoutineById(name);
};

function calculateTotalVolume() {
  if (!activeWorkout) return 0;
  let total = 0;
  activeWorkout.exercises.forEach(ex => {
    ex.sets.forEach(s => {
      if (s.completed) total += (s.weight || 0) * (s.reps || 0);
    });
  });
  return total;
}

function renderWorkoutLogs() {
  const container = document.getElementById('exerciseLogsContainer');
  if (!container) return;

  if (!activeWorkout || activeWorkout.exercises.length === 0) {
    container.innerHTML = `
      <div class="empty-workout-placeholder">
        <div style="font-size: 40px; margin-bottom: 12px;">🏋️</div>
        <h3 style="font-size: 16px; margin-bottom: 6px;">No exercises added yet</h3>
        <p style="color: var(--text-muted); font-size: 13px; margin-bottom: 20px;">Start building your workout session.</p>
        <button class="btn-primary" onclick="window.openExercisePickerModal()">+ Add your first exercise</button>
      </div>
    `;
    return;
  }

  container.innerHTML = activeWorkout.exercises.map((ex, exIdx) => `
    <div class="card">
      <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px;">
        <div style="display: flex; align-items: center; gap: 8px;">
          <h3 style="font-size: 16px;">${ex.name}</h3>
          <button class="btn-trash-icon" title="Remove exercise" onclick="window.removeExercise(${exIdx})">🗑️</button>
        </div>
        <button style="background: none; border: none; color: var(--primary); font-weight: bold; cursor: pointer; font-size: 13px;" onclick="window.openPlateModal(${ex.sets[0]?.weight || 60})">🧮 Calculator</button>
      </div>

      <div class="set-table-wrapper">
        <table class="set-table">
          <thead>
            <tr>
              <th style="width: 36px;">SET</th>
              <th style="width: 75px;">EST 1RM</th>
              <th>KG</th>
              <th>REPS</th>
              <th style="width: 36px;">✓</th>
            </tr>
          </thead>
          <tbody>
            ${ex.sets.map((s, setIdx) => `
              <tr class="set-row">
                <td>
                  <div class="set-num ${s.completed ? 'completed' : ''} ${s.type && s.type !== 'NORMAL' ? 'type-' + s.type.toLowerCase() : ''}"
                       onclick="window.cycleSetType(${exIdx}, ${setIdx})"
                       title="Click to cycle set type: Normal, Warmup (W), Drop (D), Failure (F)">
                    ${s.type === 'WARMUP' ? 'W' : s.type === 'DROPSET' ? 'D' : s.type === 'FAILURE' ? 'F' : (setIdx + 1)}
                  </div>
                </td>
                <td>
                  <div class="set-prev" title="Estimated 1RM on completion">
                    ${s.completed && s.reps > 0 ? Math.round(s.weight * (1 + s.reps / 30)) + ' kg' : (s.prev || '—')}
                  </div>
                </td>
                <td><input type="number" class="set-input" value="${s.weight}" onchange="window.updateSetVal(${exIdx}, ${setIdx}, 'weight', this.value)"></td>
                <td><input type="number" class="set-input" value="${s.reps}" onchange="window.updateSetVal(${exIdx}, ${setIdx}, 'reps', this.value)"></td>
                <td><button class="set-check ${s.completed ? 'completed' : ''}" onclick="window.toggleSet(${exIdx}, ${setIdx})">✓</button></td>
              </tr>
            `).join('')}
          </tbody>
        </table>
      </div>

      <button style="background: none; border: none; color: var(--primary); font-weight: bold; margin-top: 10px; cursor: pointer; font-size: 13px;" onclick="window.addSet(${exIdx})">+ Add Set</button>
    </div>
  `).join('');
}

window.cycleSetType = function(exIdx, setIdx) {
  if (!activeWorkout) return;
  const s = activeWorkout.exercises[exIdx].sets[setIdx];
  const types = ['NORMAL', 'WARMUP', 'DROPSET', 'FAILURE'];
  const curIdx = types.indexOf(s.type || 'NORMAL');
  s.type = types[(curIdx + 1) % types.length];
  const labels = {
    'NORMAL': 'Normal working set',
    'WARMUP': 'Warmup set (W)',
    'DROPSET': 'Drop set (D)',
    'FAILURE': 'Failure set (F)'
  };
  showToast(`Set ${setIdx + 1}: ${labels[s.type]}`, 'info');
  renderWorkoutLogs();
};

window.exportWorkoutsCSV = function() {
  const history = [
    { title: 'Push Heavy - Chest & Shoulders', date: '2026-09-01', duration: 75, volume: 12450, exercise: 'Barbell Bench Press', set: 1, type: 'WARMUP', weight: 60, reps: 12, est1rm: 84 },
    { title: 'Push Heavy - Chest & Shoulders', date: '2026-09-01', duration: 75, volume: 12450, exercise: 'Barbell Bench Press', set: 2, type: 'NORMAL', weight: 100, reps: 8, est1rm: 127 },
    { title: 'Push Heavy - Chest & Shoulders', date: '2026-09-01', duration: 75, volume: 12450, exercise: 'Incline Dumbbell Press', set: 1, type: 'NORMAL', weight: 36, reps: 10, est1rm: 48 },
    { title: 'Pull & Arms', date: '2026-08-30', duration: 60, volume: 9800, exercise: 'Bent-Over Barbell Row', set: 1, type: 'NORMAL', weight: 80, reps: 10, est1rm: 107 },
    { title: 'Leg Day Hypertrophy', date: '2026-08-28', duration: 80, volume: 15600, exercise: 'Barbell Back Squat', set: 1, type: 'NORMAL', weight: 140, reps: 6, est1rm: 168 }
  ];

  let csv = 'Date,Workout Title,Duration (min),Total Volume (kg),Exercise,Set,Type,Weight (kg),Reps,Est 1RM (kg)\n';
  history.forEach(row => {
    csv += `${row.date},"${row.title}",${row.duration},${row.volume},"${row.exercise}",${row.set},${row.type},${row.weight},${row.reps},${row.est1rm}\n`;
  });

  const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.setAttribute('href', url);
  link.setAttribute('download', `RepCount_Workouts_${new Date().toISOString().split('T')[0]}.csv`);
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  showToast('Workout history exported as CSV! 📥', 'success');
};

window.removeExercise = function(exIdx) {
  if (!activeWorkout) return;
  const removed = activeWorkout.exercises.splice(exIdx, 1);
  renderWorkoutLogs();
  showToast(`Removed ${removed[0]?.name || 'exercise'}`, 'info');
};

window.toggleSet = function(exIdx, setIdx) {
  if (!activeWorkout) return;
  const s = activeWorkout.exercises[exIdx].sets[setIdx];
  s.completed = !s.completed;
  if (s.completed) {
    window.startRestTimer(currentRestPreset);
  }
  renderWorkoutLogs();
};

window.updateSetVal = function(exIdx, setIdx, field, val) {
  if (!activeWorkout) return;
  activeWorkout.exercises[exIdx].sets[setIdx][field] = parseFloat(val) || 0;
};

window.addSet = function(exIdx) {
  if (!activeWorkout) return;
  const sets = activeWorkout.exercises[exIdx].sets;
  const lastSet = sets[sets.length - 1] || { weight: 60, reps: 10 };
  const prevStr = lastSet.weight > 0 ? `${lastSet.weight} × ${lastSet.reps}` : '—';
  sets.push({ weight: lastSet.weight, reps: lastSet.reps, prev: prevStr, completed: false });
  renderWorkoutLogs();
};

// Cancel Workout Modal Logic
window.openCancelModal = function() {
  const modal = document.getElementById('cancelConfirmModal');
  if (modal) modal.classList.add('active');
};

window.closeCancelModal = function() {
  const modal = document.getElementById('cancelConfirmModal');
  if (modal) modal.classList.remove('active');
};

window.confirmCancelWorkout = function() {
  if (timerInterval) clearInterval(timerInterval);
  if (restTimerInterval) clearInterval(restTimerInterval);
  activeWorkout = null;

  const headerActions = document.getElementById('workoutHeaderActions');
  if (headerActions) headerActions.style.display = 'none';

  const timerBar = document.getElementById('stickyTimerBar');
  if (timerBar) timerBar.style.display = 'none';

  window.closeCancelModal();
  window.switchTab('dashboard');
  showToast('Workout cancelled and discarded', 'warning');
};

// Rest Timer Logic
window.setRestDuration = function(secs) {
  currentRestPreset = secs;
  document.querySelectorAll('.preset-btn').forEach(btn => {
    btn.classList.toggle('active', parseInt(btn.dataset.sec) === secs);
  });
  window.startRestTimer(secs);
  showToast(`Rest timer set to ${secs}s`, 'info');
};

window.startRestTimer = function(secs) {
  restSeconds = secs;
  const timerBar = document.getElementById('stickyTimerBar');
  if (timerBar) timerBar.style.display = 'flex';
  updateTimerDisplay();

  if (restTimerInterval) clearInterval(restTimerInterval);
  restTimerInterval = setInterval(() => {
    if (restSeconds > 1) {
      restSeconds--;
      updateTimerDisplay();
    } else {
      window.stopTimer();
      showToast('Rest timer finished! Ready for next set 💪', 'success');
    }
  }, 1000);
};

function updateTimerDisplay() {
  const mins = String(Math.floor(restSeconds / 60)).padStart(2, '0');
  const secs = String(restSeconds % 60).padStart(2, '0');
  const timerElem = document.getElementById('timerTime');
  if (timerElem) timerElem.innerText = `${mins}:${secs}`;
}

window.addTimerTime = function(added) {
  restSeconds += added;
  updateTimerDisplay();
};

window.stopTimer = function() {
  if (restTimerInterval) clearInterval(restTimerInterval);
  const timerBar = document.getElementById('stickyTimerBar');
  if (timerBar) timerBar.style.display = 'none';
};

// Plate Calculator Logic
window.openPlateModal = function(weight) {
  const modalVal = document.getElementById('modalWeightVal');
  if (modalVal) modalVal.innerText = `${weight} kg`;

  const visualContainer = document.getElementById('plateVisualContainer');
  const breakdownList = document.getElementById('plateBreakdownList');

  const barWeight = 20;
  const targetWeight = parseFloat(weight) || 0;
  const plateWeightNeeded = targetWeight - barWeight;

  if (plateWeightNeeded <= 0) {
    if (visualContainer) {
      visualContainer.innerHTML = `<div class="empty-bar-msg">${targetWeight < barWeight ? 'Weight below 20kg Olympic bar weight' : 'Empty 20kg Olympic Bar'}</div>`;
    }
    if (breakdownList) {
      breakdownList.innerHTML = `<p style="text-align: center; color: var(--text-muted); font-size: 13px;">No plates needed for standard 20kg bar.</p>`;
    }
  } else {
    const weightPerSide = plateWeightNeeded / 2;
    const availablePlates = [25, 20, 15, 10, 5, 2.5, 1.25];
    const plateColors = {
      25: '#ff4d4d',
      20: '#4d79ff',
      15: '#ffcc00',
      10: '#2ecc71',
      5: '#e0e0e0',
      2.5: '#636e72',
      1.25: '#b2bec3'
    };

    let rem = weightPerSide;
    const breakdown = [];
    const visualPlates = [];

    availablePlates.forEach(p => {
      if (rem >= p - 0.0001) {
        const count = Math.floor((rem + 0.0001) / p);
        if (count > 0) {
          breakdown.push({ plate: p, count });
          for (let i = 0; i < count; i++) {
            visualPlates.push(p);
          }
          rem = Math.round((rem - count * p) * 1000) / 1000;
        }
      }
    });

    if (visualContainer) {
      visualContainer.innerHTML = `
        <div class="barbell-sleeve">
          <div class="sleeve-bar"></div>
          <div class="sleeve-collar"></div>
          <div class="plates-stack">
            ${visualPlates.map(p => `
              <div class="visual-plate" style="background-color: ${plateColors[p]}; height: ${getPlateHeight(p)}px;" title="${p}kg">
                <span>${p}</span>
              </div>
            `).join('')}
          </div>
        </div>
      `;
    }

    if (breakdownList) {
      breakdownList.innerHTML = `
        <div style="font-size: 11px; font-weight: 700; color: var(--text-muted); margin-bottom: 8px; text-transform: uppercase;">Per Side Breakdown (${weightPerSide} kg):</div>
        <div class="breakdown-grid">
          ${breakdown.map(b => `
            <div class="breakdown-chip" style="border-left: 4px solid ${plateColors[b.plate]};">
              <span class="chip-count">${b.count} ×</span>
              <span class="chip-weight">${b.plate} kg</span>
            </div>
          `).join('')}
        </div>
        ${rem > 0 ? `<div style="font-size: 11px; color: var(--accent-gold); margin-top: 8px;">+ ${rem} kg remainder per side</div>` : ''}
      `;
    }
  }

  const modal = document.getElementById('plateModal');
  if (modal) modal.classList.add('active');
};

function getPlateHeight(weight) {
  const map = { 25: 72, 20: 64, 15: 56, 10: 48, 5: 40, 2.5: 32, 1.25: 24 };
  return map[weight] || 32;
}

window.closePlateModal = function() {
  const modal = document.getElementById('plateModal');
  if (modal) modal.classList.remove('active');
};

// Exercise Picker Modal Logic
window.openExercisePickerModal = function() {
  window.filterPickerExercises('');
  const modal = document.getElementById('exercisePickerModal');
  if (modal) modal.classList.add('active');
};

window.closeExercisePickerModal = function() {
  const modal = document.getElementById('exercisePickerModal');
  if (modal) modal.classList.remove('active');
};

window.filterPickerExercises = function(query) {
  const list = document.getElementById('pickerExerciseList');
  if (!list) return;

  const q = query.toLowerCase().trim();
  const filtered = masterExercises.filter(ex => 
    ex.name.toLowerCase().includes(q) || ex.muscle.toLowerCase().includes(q)
  );

  list.innerHTML = filtered.map(ex => `
    <div class="card" style="display: flex; justify-content: space-between; align-items: center; cursor: pointer; margin-bottom: 8px; padding: 12px;" onclick="window.selectExerciseForWorkout('${ex.name.replace(/'/g, "\\'")}')">
      <div>
        <h4 style="font-size: 14px;">${ex.name}</h4>
        <p style="color: var(--text-muted); font-size: 11px;">${ex.muscle} • ${ex.equipment}</p>
      </div>
      <span style="color: var(--primary); font-size: 20px; font-weight: bold;">+</span>
    </div>
  `).join('');
};

window.selectExerciseForWorkout = function(exerciseName) {
  if (!activeWorkout) {
    window.startEmptyWorkout('Quick Workout');
  }

  const masterEx = masterExercises.find(m => m.name === exerciseName);
  const baseWeight = masterEx ? Math.round(masterEx.oneRepMax * 0.6) : 40;

  activeWorkout.exercises.push({
    name: exerciseName,
    sets: [
      { weight: baseWeight, reps: 10, prev: `${Math.max(0, baseWeight - 5)} × 10`, completed: false },
      { weight: baseWeight + 10, reps: 8, prev: `${baseWeight} × 8`, completed: false },
    ]
  });

  window.closeExercisePickerModal();
  renderWorkoutLogs();
  showToast(`Added ${exerciseName}`, 'success');
};

// Two-Level Muscle Filter Logic
window.selectMuscleGroup = function(group) {
  selectedMuscleGroup = group;
  selectedSubMuscle = null;

  const primaryButtons = document.querySelectorAll('#primaryMuscleFilterContainer .muscle-filter-btn');
  primaryButtons.forEach(btn => {
    if (btn.dataset.group === group) {
      btn.classList.add('active');
    } else {
      btn.classList.remove('active');
    }
  });

  renderSubMuscleFilters();
  renderExerciseList();
};

window.selectSubMuscle = function(sub) {
  if (selectedSubMuscle === sub) {
    selectedSubMuscle = null;
  } else {
    selectedSubMuscle = sub;
  }

  renderSubMuscleFilters();
  renderExerciseList();
};

function renderSubMuscleFilters() {
  const container = document.getElementById('subMuscleFilterContainer');
  if (!container) return;

  if (selectedMuscleGroup === 'All') {
    container.style.display = 'none';
    container.innerHTML = '';
    return;
  }

  const groupMuscles = muscleGroupMap[selectedMuscleGroup] || [];
  const exercisesInGroup = masterExercises.filter(ex => groupMuscles.includes(ex.muscle));
  const subMuscles = [...new Set(exercisesInGroup.map(ex => ex.subMuscle).filter(Boolean))];

  if (subMuscles.length === 0) {
    container.style.display = 'none';
    container.innerHTML = '';
    return;
  }

  container.style.display = 'flex';
  
  let html = `<button class="submuscle-filter-btn ${selectedSubMuscle === null ? 'active' : ''}" onclick="window.selectSubMuscle(null)">All ${selectedMuscleGroup}</button>`;
  
  subMuscles.forEach(sub => {
    const isActive = selectedSubMuscle === sub;
    html += `<button class="submuscle-filter-btn ${isActive ? 'active' : ''}" onclick="window.selectSubMuscle('${sub.replace(/'/g, "\\'")}')">${sub}</button>`;
  });

  container.innerHTML = html;
}

// Exercise Library Search & Filter Logic
function renderExerciseList(query = null) {
  const list = document.getElementById('exerciseList');
  if (!list) return;

  const searchInput = document.getElementById('searchInput');
  const q = (query !== null && query !== undefined ? query : (searchInput ? searchInput.value : '')).toLowerCase().trim();

  const groupMuscles = selectedMuscleGroup === 'All' ? null : muscleGroupMap[selectedMuscleGroup];

  const filtered = masterExercises.filter(ex => {
    const matchesSearch = !q ||
      ex.name.toLowerCase().includes(q) ||
      (ex.muscle && ex.muscle.toLowerCase().includes(q)) ||
      (ex.subMuscle && ex.subMuscle.toLowerCase().includes(q)) ||
      (ex.equipment && ex.equipment.toLowerCase().includes(q));

    const matchesGroup = !groupMuscles || groupMuscles.includes(ex.muscle);
    const matchesSubMuscle = !selectedSubMuscle || ex.subMuscle === selectedSubMuscle;

    return matchesSearch && matchesGroup && matchesSubMuscle;
  });

  if (filtered.length === 0) {
    list.innerHTML = `<div style="text-align: center; color: var(--text-muted); margin: 32px 0;">No exercises found matching current filters</div>`;
    return;
  }

  list.innerHTML = filtered.map(ex => `
    <div class="card" style="display: flex; justify-content: space-between; align-items: center;">
      <div>
        <h4 style="font-size: 15px;">${ex.name}</h4>
        <p style="color: var(--text-muted); font-size: 12px; margin-top: 4px; display: flex; align-items: center; flex-wrap: wrap; gap: 6px;">
          <span>${ex.muscle} • ${ex.equipment}</span>
          ${ex.subMuscle ? `<span style="background: #00B894; color: #11111b; padding: 2px 8px; border-radius: 12px; font-size: 10px; font-weight: 700;">${ex.subMuscle}</span>` : ''}
        </p>
      </div>
      <span style="color: var(--success); font-weight: bold; font-size: 13px;">1RM: ${ex.oneRepMax}kg</span>
    </div>
  `).join('');
}

// Workout Summary Modal Logic
function openWorkoutSummaryModal() {
  if (!activeWorkout) return;

  const durationSecs = activeWorkout.durationSeconds || 0;
  const mins = Math.floor(durationSecs / 60);
  const secs = durationSecs % 60;
  const timeFormatted = `${String(mins).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;

  const totalVol = calculateTotalVolume();

  let completedSetsCount = 0;
  let prCount = 0;

  const summaryListHtml = activeWorkout.exercises.map(ex => {
    const compSets = ex.sets.filter(s => s.completed);
    completedSetsCount += compSets.length;

    const masterEx = masterExercises.find(m => m.name.toLowerCase() === ex.name.toLowerCase());
    const maxWeight = compSets.reduce((max, s) => Math.max(max, s.weight), 0);
    let isPR = false;
    if (masterEx && maxWeight > masterEx.oneRepMax) {
      isPR = true;
      prCount++;
    }

    return `
      <div style="background: rgba(255,255,255,0.03); border: 1px solid var(--card-border); border-radius: 10px; padding: 10px; margin-bottom: 8px; display: flex; justify-content: space-between; align-items: center;">
        <div>
          <div style="font-weight: 700; font-size: 14px;">${ex.name} ${isPR ? '<span style="color: var(--accent-gold); font-size: 11px;">🏆 PR!</span>' : ''}</div>
          <div style="color: var(--text-muted); font-size: 12px; margin-top: 2px;">${compSets.length} / ${ex.sets.length} sets completed</div>
        </div>
        <div style="font-weight: bold; font-size: 13px; color: var(--primary);">
          ${maxWeight > 0 ? maxWeight + ' kg max' : '—'}
        </div>
      </div>
    `;
  }).join('') || '<p style="color: var(--text-muted); font-size: 13px;">No exercises logged.</p>';

  document.getElementById('summaryWorkoutTitle').innerText = activeWorkout.title;
  document.getElementById('summaryTime').innerText = timeFormatted;
  document.getElementById('summaryVolume').innerText = `${totalVol.toLocaleString()} kg`;
  document.getElementById('summarySets').innerText = completedSetsCount;
  document.getElementById('summaryPRs').innerText = `🏆 ${prCount} PR${prCount !== 1 ? 's' : ''}`;
  document.getElementById('summaryExerciseList').innerHTML = summaryListHtml;

  const modal = document.getElementById('workoutSummaryModal');
  if (modal) modal.classList.add('active');
}

function saveAndFinishWorkout() {
  if (timerInterval) clearInterval(timerInterval);
  if (restTimerInterval) clearInterval(restTimerInterval);

  const modal = document.getElementById('workoutSummaryModal');
  if (modal) modal.classList.remove('active');

  const headerActions = document.getElementById('workoutHeaderActions');
  if (headerActions) headerActions.style.display = 'none';

  const timerBar = document.getElementById('stickyTimerBar');
  if (timerBar) timerBar.style.display = 'none';

  activeWorkout = null;
  window.switchTab('dashboard');
  showToast('Workout saved successfully!', 'success');
}

// --- ROUTINE BUILDER & PERSISTENCE LOGIC ---

async function loadRoutines() {
  const userId = (typeof firebase !== 'undefined' && firebase.auth && firebase.auth().currentUser) ? firebase.auth().currentUser.uid : null;
  if (userId) {
    try {
      const db = firebase.firestore();
      const snapshot = await db.collection('users').doc(userId).collection('routines').get();
      if (!snapshot.empty) {
        routines = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
        localStorage.setItem('repcount_routines_cache', JSON.stringify(routines));
        renderRoutines();
        return;
      }
    } catch (e) {
      console.warn('Could not fetch Firestore routines:', e);
    }
  }

  const cached = localStorage.getItem('repcount_routines_cache');
  if (cached) {
    try {
      routines = JSON.parse(cached);
    } catch (e) {
      routines = JSON.parse(JSON.stringify(defaultRoutines));
    }
  } else {
    routines = JSON.parse(JSON.stringify(defaultRoutines));
  }
  renderRoutines();
}

function calculateRoutineVolume(routine) {
  if (!routine || !routine.exercises || routine.exercises.length === 0) return 0;
  let totalVol = 0;
  routine.exercises.forEach(ex => {
    if (ex.sets && ex.sets.length > 0) {
      ex.sets.forEach(s => {
        const w = parseFloat(s.weight) || 0;
        const r = parseFloat(s.reps) || 0;
        totalVol += w * r;
      });
    } else {
      const masterEx = masterExercises.find(m => m.name.toLowerCase() === (ex.name || '').toLowerCase());
      const estW = masterEx && masterEx.oneRepMax > 0 ? Math.round(masterEx.oneRepMax * 0.6) : 40;
      totalVol += estW * 10 * 3;
    }
  });
  return totalVol;
}

function renderRoutines() {
  const container = document.getElementById('routinesContainer');
  if (!container) return;

  if (routines.length === 0) {
    container.innerHTML = `
      <div class="empty-workout-placeholder">
        <div style="font-size: 40px; margin-bottom: 12px;">📁</div>
        <h3 style="font-size: 16px; margin-bottom: 6px;">No routines created yet</h3>
        <p style="color: var(--text-muted); font-size: 13px; margin-bottom: 20px;">Create custom workout templates for fast logging.</p>
        <button class="btn-primary" onclick="window.openRoutineEditor()">+ Create Routine</button>
      </div>
    `;
    return;
  }

  container.innerHTML = routines.map(r => {
    const vol = calculateRoutineVolume(r);
    const exCount = r.exercises ? r.exercises.length : 0;
    const folder = r.folder || 'Custom Workouts';
    const duration = r.duration || 60;

    return `
      <div class="card routine-card" data-routine-id="${r.id}">
        <div style="display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 6px;">
          <div>
            <span class="routine-folder-badge">📁 ${folder}</span>
            <h4 style="font-size: 16px; margin-top: 6px; margin-bottom: 4px;">${r.title}</h4>
            <p style="color: var(--text-muted); font-size: 13px;">
              ${exCount} ${exCount === 1 ? 'Exercise' : 'Exercises'} • Est. ${duration} mins • <span style="color: var(--accent-gold); font-weight: 600;">${vol.toLocaleString()} kg est. volume</span>
            </p>
          </div>
          <button class="btn-trash-icon" onclick="event.stopPropagation(); window.deleteRoutine('${r.id}')" title="Delete Routine">🗑️</button>
        </div>

        <div class="routine-card-details" id="routine-details-${r.id}" style="display: none; margin-top: 12px; padding-top: 12px; border-top: 1px solid var(--card-border);">
          <div style="font-size: 11px; font-weight: 700; color: var(--text-muted); letter-spacing: 0.5px; margin-bottom: 6px;">EXERCISE BREAKDOWN</div>
          <div class="routine-details-list">
            ${(r.exercises || []).map(ex => {
              let exVol = 0;
              if (ex.sets && ex.sets.length > 0) {
                ex.sets.forEach(s => { exVol += (parseFloat(s.weight) || 0) * (parseFloat(s.reps) || 0); });
              } else {
                const masterEx = masterExercises.find(m => m.name.toLowerCase() === (ex.name || '').toLowerCase());
                const estW = masterEx && masterEx.oneRepMax > 0 ? Math.round(masterEx.oneRepMax * 0.6) : 40;
                exVol = estW * 10 * 3;
              }
              const muscle = ex.muscle || (masterExercises.find(m => m.name.toLowerCase() === (ex.name || '').toLowerCase())?.muscle || 'General');
              const setCount = ex.sets ? ex.sets.length : 3;
              return `
                <div class="routine-details-item">
                  <div>
                    <span style="font-weight: 600;">${ex.name}</span>
                    <span class="muscle-chip">${muscle}</span>
                  </div>
                  <div style="color: var(--text-muted); font-size: 12px;">
                    ${setCount} sets • <span style="color: var(--accent-gold);">${exVol.toLocaleString()} kg</span>
                  </div>
                </div>
              `;
            }).join('')}
          </div>
          <div style="margin-top: 8px; text-align: right; font-size: 12px; font-weight: bold; color: var(--success);">
            Total Estimated Volume: ${vol.toLocaleString()} kg
          </div>
        </div>

        <div style="display: flex; gap: 8px; margin-top: 14px;">
          <button class="btn-primary" style="flex: 2; padding: 10px; font-size: 14px;" onclick="window.startRoutineById('${r.id}')">Start Routine</button>
          <button class="btn-secondary" style="flex: 1; padding: 10px; background: rgba(255,255,255,0.08); border: 1px solid var(--card-border); border-radius: 12px; color: white; font-weight: bold; cursor: pointer; font-size: 13px;" onclick="window.openRoutineEditor('${r.id}')">Edit</button>
          <button class="btn-secondary" style="padding: 10px 12px; background: rgba(255,255,255,0.05); border: 1px solid var(--card-border); border-radius: 12px; color: var(--text-muted); font-size: 12px; cursor: pointer;" onclick="window.toggleRoutineDetails('${r.id}')">Details 🔽</button>
        </div>
      </div>
    `;
  }).join('');

  attachRoutineLongPress();
}

window.toggleRoutineDetails = function(id) {
  const detailsElem = document.getElementById(`routine-details-${id}`);
  if (detailsElem) {
    const isHidden = detailsElem.style.display === 'none';
    detailsElem.style.display = isHidden ? 'block' : 'none';
  }
};

function attachRoutineLongPress() {
  document.querySelectorAll('.routine-card').forEach(card => {
    let pressTimer = null;
    const routineId = card.getAttribute('data-routine-id');

    const startPress = (e) => {
      if (e.target.tagName === 'BUTTON' || e.target.closest('button')) return;
      pressTimer = setTimeout(() => {
        if (confirm(`Open editor for routine?`)) {
          window.openRoutineEditor(routineId);
        }
      }, 700);
    };

    const cancelPress = () => {
      if (pressTimer) clearTimeout(pressTimer);
    };

    card.addEventListener('touchstart', startPress, { passive: true });
    card.addEventListener('touchend', cancelPress);
    card.addEventListener('mousedown', startPress);
    card.addEventListener('mouseup', cancelPress);
    card.addEventListener('mouseleave', cancelPress);
  });
}

window.openRoutineEditor = function(routineId = null) {
  editingRoutineId = routineId;
  const modal = document.getElementById('routineEditorModal');
  const titleInput = document.getElementById('routineTitleInput');
  const folderInput = document.getElementById('routineFolderInput');
  const durationSelect = document.getElementById('routineDurationSelect');
  const modalTitle = document.getElementById('routineEditorModalTitle');

  if (routineId) {
    const r = routines.find(item => item.id === routineId);
    if (r) {
      if (modalTitle) modalTitle.innerText = 'Edit Routine';
      if (titleInput) titleInput.value = r.title || '';
      if (folderInput) folderInput.value = r.folder || 'Custom Workouts';
      if (durationSelect) durationSelect.value = r.duration || '60';
      currentEditorExercises = JSON.parse(JSON.stringify(r.exercises || []));
    }
  } else {
    if (modalTitle) modalTitle.innerText = 'Create Routine';
    if (titleInput) titleInput.value = '';
    if (folderInput) folderInput.value = 'Custom Workouts';
    if (durationSelect) durationSelect.value = '60';
    currentEditorExercises = [];
  }

  renderEditorSelectedExercises();
  if (modal) modal.classList.add('active');
};

window.closeRoutineEditorModal = function() {
  const modal = document.getElementById('routineEditorModal');
  if (modal) modal.classList.remove('active');
};

function renderEditorSelectedExercises() {
  const container = document.getElementById('routineSelectedExercisesList');
  const countTag = document.getElementById('routineExerciseCount');
  if (countTag) {
    countTag.innerText = `${currentEditorExercises.length} ${currentEditorExercises.length === 1 ? 'exercise' : 'exercises'}`;
  }

  if (!container) return;

  if (currentEditorExercises.length === 0) {
    container.innerHTML = `
      <div style="text-align: center; padding: 20px; color: var(--text-muted); font-size: 13px; background: rgba(255,255,255,0.02); border-radius: 10px; border: 1px dashed var(--card-border);">
        No exercises added yet. Tap "+ Add Exercises" below.
      </div>
    `;
    return;
  }

  container.innerHTML = currentEditorExercises.map((ex, idx) => {
    const masterEx = masterExercises.find(m => m.name.toLowerCase() === (ex.name || '').toLowerCase());
    const muscle = ex.muscle || masterEx?.muscle || 'General';

    return `
      <div class="routine-exercise-item">
        <div class="reorder-btns">
          <button class="reorder-btn" onclick="window.moveEditorExerciseUp(${idx})" ${idx === 0 ? 'disabled style="opacity: 0.3;"' : ''} title="Move Up">▲</button>
          <button class="reorder-btn" onclick="window.moveEditorExerciseDown(${idx})" ${idx === currentEditorExercises.length - 1 ? 'disabled style="opacity: 0.3;"' : ''} title="Move Down">▼</button>
        </div>

        <div style="flex: 1; padding: 0 6px;">
          <div style="display: flex; align-items: center; gap: 4px;">
            <span style="font-weight: 700; font-size: 14px;">${ex.name}</span>
            <span class="muscle-chip">${muscle}</span>
          </div>
          <div style="color: var(--text-muted); font-size: 11px; margin-top: 2px;">
            ${ex.sets ? ex.sets.length : 3} default sets
          </div>
        </div>

        <button class="btn-trash-icon" onclick="window.removeEditorExercise(${idx})" title="Remove Exercise">🗑️</button>
      </div>
    `;
  }).join('');
}

window.moveEditorExerciseUp = function(idx) {
  if (idx > 0) {
    const temp = currentEditorExercises[idx];
    currentEditorExercises[idx] = currentEditorExercises[idx - 1];
    currentEditorExercises[idx - 1] = temp;
    renderEditorSelectedExercises();
  }
};

window.moveEditorExerciseDown = function(idx) {
  if (idx < currentEditorExercises.length - 1) {
    const temp = currentEditorExercises[idx];
    currentEditorExercises[idx] = currentEditorExercises[idx + 1];
    currentEditorExercises[idx + 1] = temp;
    renderEditorSelectedExercises();
  }
};

window.removeEditorExercise = function(idx) {
  currentEditorExercises.splice(idx, 1);
  renderEditorSelectedExercises();
};

window.openRoutineExercisePickerModal = function() {
  selectedPickerExercises.clear();
  window.filterRoutinePickerExercises('');
  const modal = document.getElementById('routineExercisePickerModal');
  if (modal) modal.classList.add('active');
};

window.closeRoutineExercisePickerModal = function() {
  const modal = document.getElementById('routineExercisePickerModal');
  if (modal) modal.classList.remove('active');
};

window.filterRoutinePickerExercises = function(query = '') {
  const list = document.getElementById('routinePickerExerciseList');
  if (!list) return;

  const q = query.toLowerCase().trim();
  const filtered = masterExercises.filter(ex =>
    ex.name.toLowerCase().includes(q) || ex.muscle.toLowerCase().includes(q)
  );

  list.innerHTML = filtered.map(ex => {
    const isChecked = selectedPickerExercises.has(ex.name);
    return `
      <div class="routine-picker-item ${isChecked ? 'selected' : ''}" onclick="window.togglePickerCheckbox('${ex.name.replace(/'/g, "\\'")}')">
        <div>
          <div style="font-weight: 700; font-size: 14px;">${ex.name}</div>
          <div style="color: var(--text-muted); font-size: 11px;">${ex.muscle} • ${ex.equipment}</div>
        </div>
        <input type="checkbox" class="routine-picker-checkbox" ${isChecked ? 'checked' : ''} onclick="event.stopPropagation(); window.togglePickerCheckbox('${ex.name.replace(/'/g, "\\'")}')">
      </div>
    `;
  }).join('');

  updatePickerAddButton();
};

window.togglePickerCheckbox = function(exName) {
  if (selectedPickerExercises.has(exName)) {
    selectedPickerExercises.delete(exName);
  } else {
    selectedPickerExercises.add(exName);
  }
  const searchInput = document.getElementById('routinePickerSearchInput');
  window.filterRoutinePickerExercises(searchInput?.value || '');
};

function updatePickerAddButton() {
  const btn = document.getElementById('addSelectedExercisesBtn');
  if (btn) {
    btn.innerText = `Add Selected (${selectedPickerExercises.size})`;
  }
}

window.addSelectedExercisesToRoutine = function() {
  selectedPickerExercises.forEach(exName => {
    const masterEx = masterExercises.find(m => m.name === exName);
    const baseW = masterEx && masterEx.oneRepMax > 0 ? Math.round(masterEx.oneRepMax * 0.6) : 40;

    currentEditorExercises.push({
      name: exName,
      muscle: masterEx?.muscle || 'General',
      sets: [
        { weight: baseW, reps: 10, prev: '—', completed: false },
        { weight: baseW + 5, reps: 8, prev: '—', completed: false },
        { weight: baseW + 10, reps: 6, prev: '—', completed: false }
      ]
    });
  });

  renderEditorSelectedExercises();
  window.closeRoutineExercisePickerModal();
  showToast(`Added ${selectedPickerExercises.size} ${selectedPickerExercises.size === 1 ? 'exercise' : 'exercises'} to routine`, 'success');
};

window.saveRoutineFromEditor = async function() {
  const titleInput = document.getElementById('routineTitleInput');
  const folderInput = document.getElementById('routineFolderInput');
  const durationSelect = document.getElementById('routineDurationSelect');

  const title = (titleInput?.value || '').trim() || 'Untitled Routine';
  const folder = (folderInput?.value || '').trim() || 'Custom Workouts';
  const duration = parseInt(durationSelect?.value) || 60;

  if (currentEditorExercises.length === 0) {
    showToast('Please add at least one exercise to the routine', 'warning');
    return;
  }

  let routineId = editingRoutineId;
  if (!routineId) {
    routineId = 'rt_' + Date.now() + '_' + Math.random().toString(36).substring(2, 7);
  }

  const routineObj = {
    id: routineId,
    title: title,
    folder: folder,
    duration: duration,
    exercises: currentEditorExercises
  };

  const existingIdx = routines.findIndex(r => r.id === routineId);
  if (existingIdx >= 0) {
    routines[existingIdx] = routineObj;
  } else {
    routines.push(routineObj);
  }

  const userId = (typeof firebase !== 'undefined' && firebase.auth && firebase.auth().currentUser) ? firebase.auth().currentUser.uid : null;
  if (userId) {
    try {
      const db = firebase.firestore();
      await db.collection('users').doc(userId).collection('routines').doc(routineId).set(routineObj);
      showToast('Routine saved to cloud', 'success');
    } catch (err) {
      console.warn('Firestore save error:', err);
      showToast('Routine saved locally', 'info');
    }
  } else {
    showToast('Routine saved locally', 'success');
  }

  localStorage.setItem('repcount_routines_cache', JSON.stringify(routines));
  renderRoutines();
  window.closeRoutineEditorModal();
};

window.deleteRoutine = async function(id) {
  if (!confirm('Are you sure you want to delete this routine?')) return;

  routines = routines.filter(r => r.id !== id);

  const userId = (typeof firebase !== 'undefined' && firebase.auth && firebase.auth().currentUser) ? firebase.auth().currentUser.uid : null;
  if (userId) {
    try {
      const db = firebase.firestore();
      await db.collection('users').doc(userId).collection('routines').doc(id).delete();
    } catch (e) {
      console.warn('Firestore delete error:', e);
    }
  }

  localStorage.setItem('repcount_routines_cache', JSON.stringify(routines));
  renderRoutines();
  showToast('Routine deleted', 'warning');
};

document.addEventListener('DOMContentLoaded', () => {
  renderExerciseList();
  initFirebaseAndExercises();
  loadRoutines();

  const createRoutineBtn = document.getElementById('createRoutineBtn');
  if (createRoutineBtn) {
    createRoutineBtn.addEventListener('click', () => window.openRoutineEditor());
  }

  if (typeof firebase !== 'undefined' && firebase.auth) {
    try {
      firebase.auth().onAuthStateChanged(() => loadRoutines());
    } catch (e) {}
  }

  const searchInput = document.getElementById('searchInput');
  if (searchInput) {
    searchInput.addEventListener('input', (e) => renderExerciseList(e.target.value));
    searchInput.addEventListener('keyup', (e) => renderExerciseList(e.target.value));
  }

  const startBtn = document.getElementById('startEmptyWorkoutBtn');
  if (startBtn) {
    startBtn.addEventListener('click', () => window.startEmptyWorkout());
  }

  const addExBtn = document.getElementById('addExerciseBtn');
  if (addExBtn) {
    addExBtn.addEventListener('click', () => {
      window.openExercisePickerModal();
    });
  }

  const cancelBtn = document.getElementById('cancelWorkoutBtn');
  if (cancelBtn) {
    cancelBtn.addEventListener('click', () => window.openCancelModal());
  }

  const finishBtn = document.getElementById('finishWorkoutBtn');
  if (finishBtn) {
    finishBtn.addEventListener('click', () => openWorkoutSummaryModal());
  }

  const saveSummaryBtn = document.getElementById('saveSummaryBtn');
  if (saveSummaryBtn) {
    saveSummaryBtn.addEventListener('click', () => saveAndFinishWorkout());
  }

  // Auth Button Listeners
  const sendCodeBtn = document.getElementById('sendCodeBtn');
  if (sendCodeBtn) {
    sendCodeBtn.addEventListener('click', () => sendVerificationCode());
  }

  const verifyOtpBtn = document.getElementById('verifyOtpBtn');
  if (verifyOtpBtn) {
    verifyOtpBtn.addEventListener('click', () => verifyOtpCode());
  }

  const demoTestBtn = document.getElementById('demoTestBtn');
  if (demoTestBtn) {
    demoTestBtn.addEventListener('click', () => handleDemoTestNumber());
  }

  const anonymousLoginBtn = document.getElementById('anonymousLoginBtn');
  if (anonymousLoginBtn) {
    anonymousLoginBtn.addEventListener('click', () => signInAnonymouslyFallback());
  }

  const changePhoneBtn = document.getElementById('changePhoneBtn');
  if (changePhoneBtn) {
    changePhoneBtn.addEventListener('click', () => {
      document.getElementById('phoneAuthSection').style.display = 'block';
      document.getElementById('otpSection').style.display = 'none';
      confirmationResult = null;
    });
  }

  // OTP Inputs auto-advance & paste handler
  const otpInputs = document.querySelectorAll('.otp-pin-input');
  otpInputs.forEach((input, idx) => {
    input.addEventListener('input', (e) => {
      if (e.target.value.length === 1 && idx < otpInputs.length - 1) {
        otpInputs[idx + 1].focus();
      }
    });

    input.addEventListener('keydown', (e) => {
      if (e.key === 'Backspace' && !e.target.value && idx > 0) {
        otpInputs[idx - 1].focus();
      }
    });

    input.addEventListener('paste', (e) => {
      e.preventDefault();
      const pasted = (e.clipboardData || window.clipboardData).getData('text').trim();
      if (/^\d{6}$/.test(pasted)) {
        pasted.split('').forEach((digit, i) => {
          if (otpInputs[i]) otpInputs[i].value = digit;
        });
        if (otpInputs[5]) otpInputs[5].focus();
      }
    });
  });

  // Profile bar click -> Sign out prompt
  const profileBar = document.querySelector('.profile-bar');
  if (profileBar) {
    profileBar.style.cursor = 'pointer';
    profileBar.title = 'Click to sign out';
    profileBar.addEventListener('click', () => {
      if (typeof firebase !== 'undefined' && firebase.auth && firebase.auth().currentUser) {
        if (confirm('Do you want to sign out?')) {
          firebase.auth().signOut().then(() => {
            showToast('Signed out successfully', 'info');
          });
        }
      }
    });
  }
});
