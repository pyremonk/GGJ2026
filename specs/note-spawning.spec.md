# Note Spawning Specification

## Overview
This specification defines how MIDI notes from level files spawn and move through the gameplay area in **Last Night at the Masquerade**. Each MIDI note value corresponds to a specific spawn point, and notes travel from these spawn points toward note targets positioned around the player.

## MIDI Note to Spawn Point Mapping

### Spawn Point Layout
All spawn point positions are defined in [screen-layout.spec.md](screen-layout.spec.md). The following MIDI notes map to specific spawn locations:

#### Top Edge Spawn Points
- **D#4 (MIDI 63)**: x=597, y=33 (top center-left)
- **E4 (MIDI 64)**: x=689, y=13 (top center)
- **F4 (MIDI 65)**: x=783, y=33 (top center-right)

#### Left Side Spawn Points (Behind Score UI)
- **D4 (MIDI 62)**: x=347, y=287 (upper left)
- **C#4 (MIDI 61)**: x=337, y=383 (middle left)
- **C4 (MIDI 60)**: x=347, y=473 (lower left)

#### Right Side Spawn Points (Behind Endgame Info UI)
- **F#4 (MIDI 66)**: x=1033, y=287 (upper right)
- **G4 (MIDI 67)**: x=1043, y=411 (middle right)
- **G#4 (MIDI 68)**: x=1033, y=497 (lower right)

#### Bottom Edge Spawn Points
- **B4 (MIDI 71)**: x=597, y=723 (bottom center-left)
- **A#4 (MIDI 70)**: x=689, y=677 (bottom center)
- **A4 (MIDI 69)**: x=783, y=723 (bottom center-right)

### Extended Offscreen Spawn Points
For notes requiring longer approach times, extended spawn points exist fully offscreen:
- **Top Range (D#4-F4)**: Additional spawn points above y=0
- **Bottom Range (A4-B4)**: Additional spawn points below y=1080
- **Left Range (C4-D4)**: Additional spawn points left of x=0
- **Right Range (F#4-G#4)**: Additional spawn points right of x=1920

*Note: All positions are based on 1920x1080 base resolution and scale proportionally when the game window is resized.*

## Note Targets

### Target Layout
Note targets are positioned in a cross pattern around the player at the center of the gameplay area (x=960, y=540). These targets indicate where notes should be hit for scoring.

#### Target Positions (Approximate)
Based on the reference layout, note targets are arranged as follows:
- **Up Target**: x=960, y=390 (approximately 150px above player)
- **Right Target**: x=1110, y=540 (approximately 150px right of player)
- **Down Target**: x=960, y=690 (approximately 150px below player)
- **Left Target**: x=810, y=540 (approximately 150px left of player)

### Target Visuals
- Sprite assets located in: `assets/note_targets/`
- Circular indicator design
- Targets remain visible throughout gameplay as reference points

## Note Movement Behavior

### Spawn to Target Movement
1. **Spawn**: Note appears at its designated spawn point based on MIDI note value
2. **Travel**: Note moves in a straight line from spawn point toward the corresponding note target
3. **Arrival**: Note reaches the note target, triggering the judgment window

### Movement Direction Mapping
Notes spawn and travel based on their position relative to the player:
- **Top spawns (D#4, E4, F4)**: Travel downward → Use "down" movement type
- **Bottom spawns (A4, A#4, B4)**: Travel upward → Use "up" movement type
- **Left spawns (C4, C#4, D4)**: Travel rightward → Use "right" movement type
- **Right spawns (F#4, G4, G#4)**: Travel leftward → Use "left" movement type

### Speed and Timing
- Note speed is calculated based on the MIDI tempo map and the distance from spawn point to target
- Notes must arrive at targets synchronized with the beat timestamp from the MIDI file
- The scheduler pre-calculates spawn times to ensure accurate arrival timing

## Visual States

### Normal State
- Default sprite appearance
- Note travels from spawn point toward target
- Standard color/brightness

### Approaching State (Judgment Window)
- **Trigger**: Note enters the judgment timing window near the target
- **Visual Change**: Note target tint shifts toward red
- **Duration**: Active during the perfect/good/ok judgment window
- **Purpose**: Provides visual feedback for timing accuracy

### Miss Threshold
- **Trigger**: Note passes through the target beyond the acceptable timing window
- **Behavior**: Note is removed from the game
- **Consequence**: Registers as a miss, affects combo and score

## Implementation Details

### Current Implementation (First Iteration)
- **Sprite Type**: Single-frame static sprites
- **Movement**: Linear interpolation from spawn point to target
- **Visuals**: Simple sprite with no animation
- **File Location**: `scripts/gameplay/` (note spawning logic)

### Future Implementation (Planned)
Notes will use animated sprites with directional animations:

#### Animation States
- **run_down**: For notes spawning at the top (D#4, E4, F4)
- **run_up**: For notes spawning at the bottom (A4, A#4, B4)
- **run_right**: For notes spawning on the left (C4, C#4, D4)
- **run_left**: For notes spawning on the right (F#4, G4, G#4)

#### Animation Triggers
- Animation is set when the note spawns based on its spawn point location
- Animation plays continuously as the note travels toward the target
- Animation may transition to hit/miss states on judgment

## Spawn Point to Target Assignment

### Directional Mapping
The game uses spatial logic to assign notes to targets:

| Spawn Location | MIDI Notes | Target Direction | Target Coordinate |
|----------------|------------|------------------|-------------------|
| Top Edge | D#4, E4, F4 | Down | x=960, y=690 |
| Bottom Edge | A4, A#4, B4 | Up | x=960, y=390 |
| Left Side | C4, C#4, D4 | Right | x=1110, y=540 |
| Right Side | F#4, G4, G#4 | Left | x=810, y=540 |

*Note: This is a simplified 4-target layout. The actual implementation may use multiple targets per direction or diagonal targets based on gameplay design.*

## Scene Structure

### Recommended Node Hierarchy
```
NoteSpawner (Node2D)
├── SpawnPoints (Node2D container)
│   ├── SpawnPoint_C4 (Marker2D)
│   ├── SpawnPoint_CSharp4 (Marker2D)
│   ├── SpawnPoint_D4 (Marker2D)
│   ├── SpawnPoint_DSharp4 (Marker2D)
│   ├── SpawnPoint_E4 (Marker2D)
│   ├── SpawnPoint_F4 (Marker2D)
│   ├── SpawnPoint_FSharp4 (Marker2D)
│   ├── SpawnPoint_G4 (Marker2D)
│   ├── SpawnPoint_GSharp4 (Marker2D)
│   ├── SpawnPoint_A4 (Marker2D)
│   ├── SpawnPoint_ASharp4 (Marker2D)
│   └── SpawnPoint_B4 (Marker2D)
├── NoteTargets (Node2D container)
│   ├── TargetUp (Sprite2D with collision)
│   ├── TargetDown (Sprite2D with collision)
│   ├── TargetLeft (Sprite2D with collision)
│   └── TargetRight (Sprite2D with collision)
└── ActiveNotes (Node2D container)
    └── (dynamically spawned note instances)
```

## Data Structures

### Note Spawn Data
```gdscript
class_name NoteSpawnData
extends Resource

@export var midi_note: int  # MIDI note value (60-71)
@export var spawn_time: float  # Absolute timestamp when to spawn
@export var arrival_time: float  # When note should reach target
@export var spawn_position: Vector2  # World position to spawn at
@export var target_position: Vector2  # Target to move toward
@export var movement_direction: String  # "up", "down", "left", "right"
```

### Spawn Point Configuration
```gdscript
const MIDI_NOTE_NAMES: Dictionary = {
	60: "C4",
	61: "C#4",
	62: "D4",
	63: "D#4",
	64: "E4",
	65: "F4",
	66: "F#4",
	67: "G4",
	68: "G#4",
	69: "A4",
	70: "A#4",
	71: "B4"
}

const SPAWN_POSITIONS: Dictionary = {
	60: Vector2(347, 473),   # C4
	61: Vector2(337, 383),   # C#4
	62: Vector2(347, 287),   # D4
	63: Vector2(597, 33),    # D#4
	64: Vector2(689, 13),    # E4
	65: Vector2(783, 33),    # F4
	66: Vector2(1033, 287),  # F#4
	67: Vector2(1043, 411),  # G4
	68: Vector2(1033, 497),  # G#4
	69: Vector2(783, 723),   # A4
	70: Vector2(689, 677),   # A#4
	71: Vector2(597, 723)    # B4
}
```

## Integration with Rhythm System

### MIDI Event Processing
1. MIDI file is parsed by `addons/godot_midi/`
2. Note events are extracted with timing information
3. `NoteScheduler` calculates spawn times based on travel distance and tempo
4. Notes are spawned ahead of their target arrival time
5. Scheduler monitors note positions and triggers judgment events

### Timing Calculations
```gdscript
# Example calculation
func calculate_spawn_time(arrival_time: float, spawn_pos: Vector2, target_pos: Vector2) -> float:
	var distance: float = spawn_pos.distance_to(target_pos)
	var travel_time: float = distance / note_speed
	return arrival_time - travel_time
```

## Related Specifications
- Screen layout and spawn positions: [screen-layout.spec.md](screen-layout.spec.md)
- Rhythm timing system: [rhythm-architecture.md](rhythm-architecture.md)
- Gameplay mechanics: [gameplay-overview.md](gameplay-overview.md)

## Visual Reference
See: `specs/spec_ref_images/Screen Layout, Spawn Points and Note Reference.png`
