export interface Exercise {
  id: string;
  name: string;
  muscleGroup: 'chest' | 'back' | 'legs' | 'shoulders' | 'arms' | 'core';
  equipment: 'barbell' | 'dumbbell' | 'cable' | 'machine' | 'bodyweight' | 'other';
  description: string;
}

export const exercises: Exercise[] = [
  // CHEST (10)
  {
    id: 'barbell-bench-press',
    name: 'Barbell Bench Press',
    muscleGroup: 'chest',
    equipment: 'barbell',
    description: 'Lie on a flat bench, plant your feet firmly, and press the barbell vertically upward from lower-chest height with elbows at a 45-degree angle.',
  },
  {
    id: 'incline-barbell-bench-press',
    name: 'Incline Barbell Bench Press',
    muscleGroup: 'chest',
    equipment: 'barbell',
    description: 'Position an incline bench at 30–45 degrees to target the clavicular head of the chest, keeping your upper back engaged throughout the lift.',
  },
  {
    id: 'dumbbell-bench-press',
    name: 'Dumbbell Bench Press',
    muscleGroup: 'chest',
    equipment: 'dumbbell',
    description: 'Press dumbbells overhead from chest height on a flat bench, allowing a fuller range of motion and natural wrist rotation.',
  },
  {
    id: 'incline-dumbbell-press',
    name: 'Incline Dumbbell Press',
    muscleGroup: 'chest',
    equipment: 'dumbbell',
    description: 'Perform a dumbbell press on an inclined bench to emphasize the upper chest, lowering the weights slowly to chest level.',
  },
  {
    id: 'dumbbell-flyes',
    name: 'Dumbbell Flyes',
    muscleGroup: 'chest',
    equipment: 'dumbbell',
    description: 'Lie flat with a slight bend in your elbows and arc the dumbbells out wide, squeezing your chest at the top of the movement.',
  },
  {
    id: 'cable-flyes',
    name: 'Cable Flyes',
    muscleGroup: 'chest',
    equipment: 'cable',
    description: 'Stand between dual cable pulleys and pull the handles together in a hugging motion to maintain continuous tension on the pectorals.',
  },
  {
    id: 'chest-dips',
    name: 'Chest Dips',
    muscleGroup: 'chest',
    equipment: 'bodyweight',
    description: 'Lean your torso forward slightly on parallel bars while dipping down until shoulders are below elbows, engaging the lower chest.',
  },
  {
    id: 'machine-chest-press',
    name: 'Machine Chest Press',
    muscleGroup: 'chest',
    equipment: 'machine',
    description: 'Sit upright with handles at chest height and press forward along a fixed track, isolating the chest safely with maximum control.',
  },
  {
    id: 'pec-deck',
    name: 'Pec Deck',
    muscleGroup: 'chest',
    equipment: 'machine',
    description: 'Sit at the pec deck flye machine with elbows resting against the pads or handles, bringing them together to isolate pectoral muscle fibers.',
  },
  {
    id: 'push-ups',
    name: 'Push-ups',
    muscleGroup: 'chest',
    equipment: 'bodyweight',
    description: 'Maintain a rigid plank position while lowering your chest close to the floor, then press up forcefully keeping core tight.',
  },

  // BACK (10)
  {
    id: 'deadlift',
    name: 'Deadlift',
    muscleGroup: 'back',
    equipment: 'barbell',
    description: 'Hinge at the hips with a flat spine to lift the loaded barbell off the floor, engaging glutes, hamstrings, and upper back.',
  },
  {
    id: 'barbell-row',
    name: 'Barbell Row',
    muscleGroup: 'back',
    equipment: 'barbell',
    description: 'Bend forward at a 45-degree angle with a flat back and pull the barbell toward your lower ribs, driving with your elbows.',
  },
  {
    id: 'dumbbell-row',
    name: 'Dumbbell Row',
    muscleGroup: 'back',
    equipment: 'dumbbell',
    description: 'Support one knee and hand on a bench while pulling a heavy dumbbell to your hip, squeezing the lats at the top.',
  },
  {
    id: 'pull-ups',
    name: 'Pull-ups',
    muscleGroup: 'back',
    equipment: 'bodyweight',
    description: 'Grasp an overhead bar with an overhand wide grip and pull your body up until your chin clears the bar.',
  },
  {
    id: 'chin-ups',
    name: 'Chin-ups',
    muscleGroup: 'back',
    equipment: 'bodyweight',
    description: 'Use an underhand shoulder-width grip on a bar to pull yourself up, emphasizing both the lats and biceps.',
  },
  {
    id: 'lat-pulldown',
    name: 'Lat Pulldown',
    muscleGroup: 'back',
    equipment: 'cable',
    description: 'Sit facing the cable machine with thighs secured and pull the wide bar down to your upper chest while retracting scapulae.',
  },
  {
    id: 'seated-cable-row',
    name: 'Seated Cable Row',
    muscleGroup: 'back',
    equipment: 'cable',
    description: 'Sit upright with knees slightly bent and row the handle toward your abdomen, keeping your spine neutral and squeezing the middle back.',
  },
  {
    id: 't-bar-row',
    name: 'T-Bar Row',
    muscleGroup: 'back',
    equipment: 'barbell',
    description: 'Straddle a landmine or T-bar setup, hinging forward to row the weight toward your chest for middle-back thickness.',
  },
  {
    id: 'face-pulls',
    name: 'Face Pulls',
    muscleGroup: 'back',
    equipment: 'cable',
    description: 'Attach a rope to a high pulley and pull toward your face while externally rotating your shoulders to target rear delts and upper traps.',
  },
  {
    id: 'straight-arm-pulldown',
    name: 'Straight Arm Pulldown',
    muscleGroup: 'back',
    equipment: 'cable',
    description: 'Keep arms nearly straight and push a cable bar down from eye level to your thighs, isolating lat muscles throughout.',
  },

  // LEGS (12)
  {
    id: 'barbell-squat',
    name: 'Barbell Squat',
    muscleGroup: 'legs',
    equipment: 'barbell',
    description: 'Rest a barbell across your upper traps, hinge back at the hips, and bend knees until thighs are parallel to the floor before driving up.',
  },
  {
    id: 'front-squat',
    name: 'Front Squat',
    muscleGroup: 'legs',
    equipment: 'barbell',
    description: 'Rest the barbell across your anterior deltoids with elbows high, keeping your torso upright to shift focus onto the quadriceps.',
  },
  {
    id: 'leg-press',
    name: 'Leg Press',
    muscleGroup: 'legs',
    equipment: 'machine',
    description: 'Place feet shoulder-width on the sled platform, lower the weight until knees reach a 90-degree angle, and press back up without locking knees.',
  },
  {
    id: 'romanian-deadlift',
    name: 'Romanian Deadlift',
    muscleGroup: 'legs',
    equipment: 'barbell',
    description: 'Hinge at the hips with soft knees, lowering the bar along your shins until feeling a stretch in your hamstrings before extending glutes.',
  },
  {
    id: 'bulgarian-split-squat',
    name: 'Bulgarian Split Squat',
    muscleGroup: 'legs',
    equipment: 'dumbbell',
    description: 'Elevate one rear foot on a bench and lower your hips until the front knee reaches 90 degrees, targeting quads and glutes unilaterally.',
  },
  {
    id: 'leg-extension',
    name: 'Leg Extension',
    muscleGroup: 'legs',
    equipment: 'machine',
    description: 'Sit in the machine with lower legs behind the pad and extend your knees fully to isolate and contract the quadriceps.',
  },
  {
    id: 'leg-curl',
    name: 'Leg Curl',
    muscleGroup: 'legs',
    equipment: 'machine',
    description: 'Lie face down or sit in the curl machine and flex your knees to pull the pad toward your glutes, isolating hamstrings.',
  },
  {
    id: 'hack-squat',
    name: 'Hack Squat',
    muscleGroup: 'legs',
    equipment: 'machine',
    description: 'Position your back flat against the inclined sled pad and perform deep squats with fixed spine support for intense quad stimulus.',
  },
  {
    id: 'hip-thrust',
    name: 'Hip Thrust',
    muscleGroup: 'legs',
    equipment: 'barbell',
    description: 'Rest your upper back against a bench with a padded bar over your hips, driving through your heels to extend hips fully.',
  },
  {
    id: 'calf-raises-standing',
    name: 'Calf Raises (Standing)',
    muscleGroup: 'legs',
    equipment: 'machine',
    description: 'Stand on a calf block under shoulder pads, lower your heels for a full stretch, and press up onto toes to contract the gastrocnemius.',
  },
  {
    id: 'calf-raises-seated',
    name: 'Calf Raises (Seated)',
    muscleGroup: 'legs',
    equipment: 'machine',
    description: 'Sit with thigh pad locked above knees and raise heels upward to emphasize the deeper soleus calf muscle.',
  },
  {
    id: 'goblet-squat',
    name: 'Goblet Squat',
    muscleGroup: 'legs',
    equipment: 'dumbbell',
    description: 'Hold a dumbbell vertically against your chest and perform deep squats, using your elbows to guide knee tracking.',
  },

  // SHOULDERS (8)
  {
    id: 'overhead-press',
    name: 'Overhead Press',
    muscleGroup: 'shoulders',
    equipment: 'barbell',
    description: 'Stand tall with core braced and press the barbell vertically from collarbone to full overhead lockout.',
  },
  {
    id: 'dumbbell-shoulder-press',
    name: 'Dumbbell Shoulder Press',
    muscleGroup: 'shoulders',
    equipment: 'dumbbell',
    description: 'Sit on an upright bench and press dumbbells overhead from ear level, keeping elbows slightly tucked forward.',
  },
  {
    id: 'lateral-raises',
    name: 'Lateral Raises',
    muscleGroup: 'shoulders',
    equipment: 'dumbbell',
    description: 'Raise dumbbells out to your sides until parallel to the floor with pinkies slightly elevated to target the lateral head of deltoids.',
  },
  {
    id: 'front-raises',
    name: 'Front Raises',
    muscleGroup: 'shoulders',
    equipment: 'dumbbell',
    description: 'Lift dumbbells forward in front of your body up to eye level with controlled motion to isolate anterior deltoids.',
  },
  {
    id: 'rear-delt-flyes',
    name: 'Rear Delt Flyes',
    muscleGroup: 'shoulders',
    equipment: 'dumbbell',
    description: 'Bend forward at hips and raise dumbbells horizontally out to the sides to isolate posterior deltoids.',
  },
  {
    id: 'arnold-press',
    name: 'Arnold Press',
    muscleGroup: 'shoulders',
    equipment: 'dumbbell',
    description: 'Start with dumbbells at chest facing you and rotate palms outward as you press overhead, hitting all three deltoid heads.',
  },
  {
    id: 'upright-row',
    name: 'Upright Row',
    muscleGroup: 'shoulders',
    equipment: 'barbell',
    description: 'Pull a barbell upward along your torso toward chest level with elbows leading high to engage side delts and upper traps.',
  },
  {
    id: 'cable-lateral-raise',
    name: 'Cable Lateral Raise',
    muscleGroup: 'shoulders',
    equipment: 'cable',
    description: 'Use a low cable pulley to raise the handle across your body to shoulder height for constant lateral delt resistance.',
  },

  // ARMS (12)
  {
    id: 'barbell-curl',
    name: 'Barbell Curl',
    muscleGroup: 'arms',
    equipment: 'barbell',
    description: 'Stand with shoulder-width underhand grip and curl the barbell upward without using momentum or swinging your torso.',
  },
  {
    id: 'dumbbell-curl',
    name: 'Dumbbell Curl',
    muscleGroup: 'arms',
    equipment: 'dumbbell',
    description: 'Curl dumbbells upward while supinating wrists so palms face upward at peak contraction for maximum bicep engagement.',
  },
  {
    id: 'hammer-curl',
    name: 'Hammer Curl',
    muscleGroup: 'arms',
    equipment: 'dumbbell',
    description: 'Hold dumbbells with a neutral grip (palms facing each other) and curl upward to target the brachialis and brachioradialis.',
  },
  {
    id: 'preacher-curl',
    name: 'Preacher Curl',
    muscleGroup: 'arms',
    equipment: 'barbell',
    description: 'Rest triceps on an inclined preacher pad and curl the EZ bar or barbell upward to eliminate body momentum.',
  },
  {
    id: 'cable-curl',
    name: 'Cable Curl',
    muscleGroup: 'arms',
    equipment: 'cable',
    description: 'Attach a straight or EZ bar to a low cable and curl upward for uniform resistance throughout the entire ROM.',
  },
  {
    id: 'concentration-curl',
    name: 'Concentration Curl',
    muscleGroup: 'arms',
    equipment: 'dumbbell',
    description: 'Sit on a bench, brace your elbow against inner thigh, and curl dumbbell to your shoulder for strict bicep isolation.',
  },
  {
    id: 'tricep-pushdown',
    name: 'Tricep Pushdown',
    muscleGroup: 'arms',
    equipment: 'cable',
    description: 'Push a rope or bar attachment down on a high cable, locking out elbows completely at the bottom to target lateral and medial heads.',
  },
  {
    id: 'overhead-tricep-extension',
    name: 'Overhead Tricep Extension',
    muscleGroup: 'arms',
    equipment: 'dumbbell',
    description: 'Hold a dumbbell overhead with both hands and flex elbows to lower weight behind head, stretching the triceps long head.',
  },
  {
    id: 'skull-crushers',
    name: 'Skull Crushers',
    muscleGroup: 'arms',
    equipment: 'barbell',
    description: 'Lie on a bench and hinge at elbows to lower an EZ bar toward your forehead, then extend arms back to starting position.',
  },
  {
    id: 'close-grip-bench-press',
    name: 'Close Grip Bench Press',
    muscleGroup: 'arms',
    equipment: 'barbell',
    description: 'Bench press with hands placed narrow (shoulder-width apart) to shift major tension from chest to triceps.',
  },
  {
    id: 'tricep-dips',
    name: 'Tricep Dips',
    muscleGroup: 'arms',
    equipment: 'bodyweight',
    description: 'Keep torso upright on dip bars and lower body until upper arms are parallel to floor before pressing back up with triceps.',
  },
  {
    id: 'cable-tricep-kickback',
    name: 'Cable Tricep Kickback',
    muscleGroup: 'arms',
    equipment: 'cable',
    description: 'Hinge at waist with upper arm parallel to floor and extend cable arm backward until elbow locks out completely.',
  },

  // CORE (8)
  {
    id: 'plank',
    name: 'Plank',
    muscleGroup: 'core',
    equipment: 'bodyweight',
    description: 'Hold a isometric position on forearms and toes, keeping your body in a straight line while pulling belly button inward.',
  },
  {
    id: 'cable-crunch',
    name: 'Cable Crunch',
    muscleGroup: 'core',
    equipment: 'cable',
    description: 'Kneel in front of a high pulley with rope attachment held near ears and flex your spine down to pull elbows to thighs.',
  },
  {
    id: 'hanging-leg-raise',
    name: 'Hanging Leg Raise',
    muscleGroup: 'core',
    equipment: 'bodyweight',
    description: 'Hang from a pull-up bar and raise extended legs up to 90 degrees or chest height, controlling the lowering phase.',
  },
  {
    id: 'russian-twist',
    name: 'Russian Twist',
    muscleGroup: 'core',
    equipment: 'bodyweight',
    description: 'Sit with feet elevated and torso reclined 45 degrees, twisting shoulders side-to-side to work the obliques.',
  },
  {
    id: 'ab-wheel-rollout',
    name: 'Ab Wheel Rollout',
    muscleGroup: 'core',
    equipment: 'other',
    description: 'Kneel on floor and roll the ab wheel forward as far as possible while maintaining a hollow body, then pull back using abs.',
  },
  {
    id: 'bicycle-crunch',
    name: 'Bicycle Crunch',
    muscleGroup: 'core',
    equipment: 'bodyweight',
    description: 'Lie flat and alternate bringing opposite elbow to opposite knee while extending the opposite leg out straight.',
  },
  {
    id: 'decline-sit-up',
    name: 'Decline Sit-up',
    muscleGroup: 'core',
    equipment: 'bodyweight',
    description: 'Secure feet on a decline bench and sit up through full range of abdominal flexion for added core intensity.',
  },
  {
    id: 'woodchoppers',
    name: 'Woodchoppers',
    muscleGroup: 'core',
    equipment: 'cable',
    description: 'Pull cable diagonally across your body from high-to-low or low-to-high, rotating through the core to target rotational power.',
  },
];

export function getExercisesByMuscleGroup(group: string): Exercise[] {
  return exercises.filter((ex) => ex.muscleGroup.toLowerCase() === group.toLowerCase());
}

export function getExerciseById(id: string): Exercise | undefined {
  return exercises.find((ex) => ex.id === id);
}
