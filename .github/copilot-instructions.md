# GGJ2026 - AI Agent Instructions

**GGJ2026** is a vertical-scrolling rhythm shoot 'em up built in Godot 4.5, combining grid-based combat with beat-synchronized movement.

## Architecture Overview

### Core Game Framework
Built using patterns inspired by Maaack's Game Template, providing:
- Menu system (main, options, pause, level select)
- Scene loading infrastructure via `SceneLoader` autoload
- Persistent state management through `GlobalState` static class
- Audio controllers: `ProjectMusicController`, `ProjectUISoundController`, and `MenuMusicManager` (autoloads)

### State Management Pattern
Game state uses a two-tier Resource-based system:
- **GlobalState** (`scripts/core/state/global_state.gd`) - Static class providing persistent storage methods for all game state
- **GameState** (`scripts/game_state.gd`) - Static wrapper accessing `GlobalState.get_or_create_state(STATE_NAME, FILE_PATH)`
- **LevelState** (`scripts/level_state.gd`) - Per-level data (tutorial progress, custom properties)

**Critical pattern**: Always access state through static methods on `GameState`, never directly instantiate. Example:
```gdscript
var level_state: LevelState = GameState.get_level_state(scene_file_path)
level_state.tutorial_read = true
GlobalState.save()  # Always call after modifying state
```

### Level Architecture
- Levels emit `level_won(next_level_path: String)` and `level_lost` signals
- **LevelManager** (`scripts/core/managers/level_manager.gd`) coordinates level flow
- Project extends with `scripts/level_and_state_manager.gd` to sync LevelManager with GameState
- Level scenes: `scenes/game_scene/levels/*.tscn` inherit from `level.gd`

## Rhythm Game Architecture (MIDI-Driven)

**Target architecture** (from `specs/rhythm-architecture.md`):
- **MIDI tempo map** is the single source of truth for beat timing
- Schedule gameplay events ahead using absolute timestamps (never rely on physics/collisions for timing)
- Modular components: `MusicPlayer`, `MIDIEventRouter`, `NoteScheduler`, `Judge`, `PlayerInput`, `Referee`
- MIDI plugin: `addons/godot_midi/` provides MIDI parsing

**Key principle**: Never compute beats from BPM manually when MIDI tempo map exists. Use signal-driven architecture.

### CRITICAL: Direction Naming Convention
**Direction always refers to the SPAWN SIDE, which corresponds to the INPUT KEY and FEEDBACK LOCATION.**

Notes spawn from one side and travel toward the player at the center. The visual movement direction is irrelevant to gameplay logic:
- **"left" direction** = spawns from LEFT side, player presses LEFT arrow, feedback at LEFT target
- **"right" direction** = spawns from RIGHT side, player presses RIGHT arrow, feedback at RIGHT target
- **"up" direction** = spawns from TOP side, player presses UP arrow, feedback at UP target
- **"down" direction** = spawns from BOTTOM side, player presses DOWN arrow, feedback at DOWN target

**Example**: A note with direction="left" spawns at position (321, 531) on the LEFT side and travels toward the center. The player must press the LEFT arrow key to hit it, and feedback displays at the LEFT target.

**MIDI Note Mapping** (in `MIDIEventRouter.gd` and `NoteSpawner.gd`):
```gdscript
const TARGET_MAPPING: Dictionary = {
    60: "left",    # C4 - spawns LEFT, player presses LEFT
    61: "left",    # C#4 - spawns LEFT, player presses LEFT
    62: "left",    # D4 - spawns LEFT, player presses LEFT
    63: "up",      # D#4 - spawns TOP, player presses UP
    64: "up",      # E4 - spawns TOP, player presses UP
    65: "up",      # F4 - spawns TOP, player presses UP
    66: "right",   # F#4 - spawns RIGHT, player presses RIGHT
    67: "right",   # G4 - spawns RIGHT, player presses RIGHT
    68: "right",   # G#4 - spawns RIGHT, player presses RIGHT
    69: "down",    # A4 - spawns BOTTOM, player presses DOWN
    70: "down",    # A#4 - spawns BOTTOM, player presses DOWN
    71: "down"     # B4 - spawns BOTTOM, player presses DOWN
}
```

**This mapping MUST be identical in both files.** Never modify one without updating the other.

## GDScript Conventions (Strict)

### Type Safety
- **Always** use explicit static types: `var player_id: int = 0`, `func get_score() -> int:`
- Replace magic numbers with named constants: `const MAX_HEALTH: int = 100`
- `@onready` with full type annotations: `@onready var sprite: Sprite2D = $Sprite2D`

### Code Organization
```gdscript
# 1. Signals
signal player_moved(position: Vector2)

# 2. Constants
const MOVE_SPEED: float = 5.0

# 3. @export variables
@export var max_health: int = 100

# 4. @onready variables
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# 5. Regular variables
var current_health: int = 100

# 6. Lifecycle functions (_ready, _process, etc.)
# 7. Private functions (prefixed with _)
# 8. Public functions
```

### Naming & Style
- `snake_case`: functions/variables (`calculate_damage()`, `player_position`)
- `PascalCase`: classes/types (`PlayerController`, `GameState`)
- Tabs for indentation (not spaces)
- Early returns over nested conditionals:
```gdscript
func process_player(player: Node) -> void:
    if player == null:
        return
    if not player.is_alive():
        return
    player.attack()
```

### Data Structures
- **Never** use untyped dictionaries for data transfer - use typed classes extending `Resource` or `RefCounted`
- Use `@abstract` for base classes (must extend Godot type, inheritance only)
- Composition over inheritance - keep chains shallow (1-2 levels max)

### Event Bus Pattern
Public signals with wrapper emission functions:
```gdscript
signal player_moved(position: Vector3)
var _current_player_position: Vector3 = Vector3.ZERO

func emit_player_moved(position: Vector3) -> void:
    _current_player_position = position
    player_moved.emit(position)

func get_player_position() -> Vector3:
    return _current_player_position
```

## Project-Specific Patterns

### Scene References
Use unique node names (`%NodeName`) for in-scene references:
```gdscript
%TutorialManager.open_tutorials()
%ColorPickerButton.color = level_state.color
```

### Signal-Driven Communication
- Levels emit gameplay signals; LevelManager listens
- Windows (win/lose screens) emit user action signals
- Avoid direct node references between unrelated systems

### File Conventions
- **Never** manually create/edit `.uid` files - Godot editor manages these
- Level scenes: `scenes/game_scene/levels/level_*.tscn`
- Scripts mirror scene organization: `scenes/game_scene/levels/level.gd`
- Custom scripts: `scripts/` (game state, managers)

## Autoloads (Project Settings)
1. `AppConfig` - Template configuration
2. `SceneLoader` - Scene loading/transitions
3. `ProjectMusicController` - Cross-scene music blending
4. `ProjectUISoundController` - UI audio management
5. `MenuMusicManager` - Menu music state management

Access via singleton pattern: `SceneLoader.load_scene(path)`, `GlobalState.save()` (note: GlobalState is a static class, not an autoload)

## Development Workflows

### Testing Levels
Run from `scenes/opening/opening.tscn` (main scene) or directly test individual levels in `scenes/game_scene/levels/`

### State Debugging
Saved state: `user://global_state.tres` - Delete to reset all progress

### MIDI Integration
- MIDI files processed by `addons/godot_midi/`
- Timing components go in `scripts/audio/` and `scripts/midi/` (per architecture doc)
- Never mix audio playback logic with MIDI parsing

## Key References
- **Architecture spec**: `specs/rhythm-architecture.md` (comprehensive rhythm game patterns)
- **Gameplay design**: `specs/gameplay-interactions.spec.md` (grid combat, power-ups, scoring)
- **Note spawning**: `specs/note-spawning.spec.md` (note timing, spawn mechanics)
- **UI spec**: `specs/ui.spec.md` (UI layout and feedback systems)
- **State examples**: `scripts/game_state.gd`, `scripts/level_and_state_manager.gd`
- **Level template**: `scenes/game_scene/levels/level.gd`
