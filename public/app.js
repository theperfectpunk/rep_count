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

const masterExercises = [
  { id: 'ex1', name: 'Barbell Bench Press', muscle: 'Chest', equipment: 'Barbell', oneRepMax: 125 },
  { id: 'ex2', name: 'Barbell Back Squat', muscle: 'Quads', equipment: 'Barbell', oneRepMax: 160 },
  { id: 'ex3', name: 'Conventional Deadlift', muscle: 'Hamstrings', equipment: 'Barbell', oneRepMax: 190 },
  { id: 'ex4', name: 'Overhead Barbell Press', muscle: 'Shoulders', equipment: 'Barbell', oneRepMax: 75 },
  { id: 'ex5', name: 'Bodyweight Pull-Ups', muscle: 'Lats', equipment: 'Pull-Up Bar', oneRepMax: 105 },
  { id: 'ex6', name: 'Incline Dumbbell Press', muscle: 'Upper Chest', equipment: 'Dumbbell', oneRepMax: 40 },
  { id: 'ex7', name: 'High-to-Low Cable Flyes', muscle: 'Chest', equipment: 'Cable', oneRepMax: 32.5 },
  { id: 'ex8', name: 'EZ-Bar Bicep Curl', muscle: 'Biceps', equipment: 'EZ-Bar', oneRepMax: 45 },
  { id: 'ex9', name: 'Rope Tricep Pushdown', muscle: 'Triceps', equipment: 'Cable', oneRepMax: 35 },
  { id: 'ex10', name: 'Seated Leg Extension', muscle: 'Quads', equipment: 'Machine', oneRepMax: 90 },
];

const routineTemplates = {
  'Push Day A': [
    {
      name: 'Barbell Bench Press',
      sets: [
        { weight: 60, reps: 10, prev: '55 × 10', completed: false },
        { weight: 80, reps: 8, prev: '75 × 8', completed: false },
        { weight: 100, reps: 6, prev: '95 × 6', completed: false }
      ]
    },
    {
      name: 'Overhead Barbell Press',
      sets: [
        { weight: 40, reps: 10, prev: '37.5 × 10', completed: false },
        { weight: 50, reps: 8, prev: '47.5 × 8', completed: false }
      ]
    },
    {
      name: 'High-to-Low Cable Flyes',
      sets: [
        { weight: 20, reps: 12, prev: '17.5 × 12', completed: false },
        { weight: 25, reps: 10, prev: '22.5 × 10', completed: false }
      ]
    }
  ],
  'Pull Day A': [
    {
      name: 'Bodyweight Pull-Ups',
      sets: [
        { weight: 0, reps: 10, prev: 'BW × 10', completed: false },
        { weight: 0, reps: 8, prev: 'BW × 8', completed: false }
      ]
    },
    {
      name: 'Conventional Deadlift',
      sets: [
        { weight: 100, reps: 8, prev: '90 × 8', completed: false },
        { weight: 140, reps: 5, prev: '130 × 5', completed: false }
      ]
    },
    {
      name: 'EZ-Bar Bicep Curl',
      sets: [
        { weight: 30, reps: 12, prev: '25 × 12', completed: false },
        { weight: 35, reps: 10, prev: '30 × 10', completed: false }
      ]
    }
  ]
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

window.startRoutine = function(name) {
  const exercises = routineTemplates[name] ? JSON.parse(JSON.stringify(routineTemplates[name])) : [];
  window.startEmptyWorkout(name, exercises);
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
              <th style="width: 75px;">PREV</th>
              <th>KG</th>
              <th>REPS</th>
              <th style="width: 36px;">✓</th>
            </tr>
          </thead>
          <tbody>
            ${ex.sets.map((s, setIdx) => `
              <tr class="set-row">
                <td><div class="set-num ${s.completed ? 'completed' : ''}">${setIdx + 1}</div></td>
                <td><div class="set-prev">${s.prev || '—'}</div></td>
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

// Exercise Library Search Logic
function renderExerciseList(query = '') {
  const list = document.getElementById('exerciseList');
  if (!list) return;

  const q = query.toLowerCase().trim();
  const filtered = masterExercises.filter(ex => 
    ex.name.toLowerCase().includes(q) ||
    ex.muscle.toLowerCase().includes(q) ||
    ex.equipment.toLowerCase().includes(q)
  );

  if (filtered.length === 0) {
    list.innerHTML = `<div style="text-align: center; color: var(--text-muted); margin: 32px 0;">No exercises found matching "${query}"</div>`;
    return;
  }

  list.innerHTML = filtered.map(ex => `
    <div class="card" style="display: flex; justify-content: space-between; align-items: center;">
      <div>
        <h4 style="font-size: 15px;">${ex.name}</h4>
        <p style="color: var(--text-muted); font-size: 12px; margin-top: 2px;">${ex.muscle} • ${ex.equipment}</p>
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

document.addEventListener('DOMContentLoaded', () => {
  renderExerciseList();

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
});
