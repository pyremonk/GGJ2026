# Creating Levels for GGJ2026

This guide explains how to create and integrate rhythm gameplay levels into the menu system with non-linear progression and win/lose screens.

## Architecture Overview

### Level Structure

The game uses a **wrapper pattern** for levels:

```
GameplayLevel (Control node)
├─ Script: level.gd
├─ Export: next_level_path
└─ GameplayBase (instanced scene)
    ├─ Script: gameplay_base.gd
    ├─ Export: level_config (LevelConfig resource)
    ├─ Export: test_midi_file (fallback)
    └─ Export: test_audio_file (fallback)
```

### Signal Flow

```
gameplay_base.gd
  ├─ Emits: level_won(next_level_path: String)
  └─ Emits: level_lost
         ↓
level.gd
  ├─ Forwards: level_won signal
  └─ Forwards: level_lost signal
         ↓
level_and_state_manager.gd (LevelManager)
  ├─ Shows: level_won_window.tscn or game_won_window.tscn
  └─ Shows: level_lost_window.tscn
         ↓
Player Actions
  ├─ Continue → Load next level
  ├─ Restart → Reload current level
  └─ Main Menu → Return to menu
```

## Creating a New Level

### Step 1: Create Level Wrapper Scene

1. **In Godot Editor**: Scene → New Scene
2. **Root Node**: Add `Control` node (name it `GameplayLevel1`, `GameplayLevel2`, etc.)
3. **Attach Script**: [scenes/game_scene/levels/level.gd](scenes/game_scene/levels/level.gd)
4. **Set Anchors**: Full Rect (anchors 0,0,1,1)

### Step 2: Add GameplayBase Instance

1. **Instance Scene**: Scene → Instantiate Child Scene → Select [scenes/game_scene/gameplay_base.tscn](scenes/game_scene/gameplay_base.tscn)
2. **Set Unique Name**: In Scene tree, right-click the GameplayBase node → Access as Unique Name (adds `%` prefix)
3. **Verify Name**: Ensure it shows as `%GameplayBase` in the scene tree

### Step 3: Configure Root Node (Wrapper)

Select the root `GameplayLevel` node and configure in Inspector:

**Script Variables:**
- `next_level_path`: Path to the next level scene (e.g., `res://scenes/game_scene/levels/gameplay_level_2.tscn`)
  - Leave **empty** for the final level

### Step 4: Configure GameplayBase Node

Select the `%GameplayBase` node and configure in Inspector:

**Primary Configuration:**
- `level_config`: Create or assign a LevelConfig resource (see next section)

**Fallback Testing (optional):**
- `test_midi_file`: Direct path to MIDI file (used only if `level_config` is null)
- `test_audio_file`: Direct path to audio file (used only if `level_config` is null)
- `next_level_path`: Leave **empty** (handled by wrapper)

### Step 5: Save the Scene

Save to: `res://scenes/game_scene/levels/gameplay_level_X.tscn`

## Creating LevelConfig Resources

### What is LevelConfig?

`LevelConfig` is a custom Resource that stores all metadata and file paths for a level:

```gdscript
class_name LevelConfig
extends Resource

@export var level_name: String = ""
@export var track_name: String = ""
@export var artist_name: String = ""
@export_file("*.mid") var midi_file_path: String = ""
@export_file("*.ogg") var audio_file_path: String = ""
```

### Creating a LevelConfig

1. **In FileSystem Panel**: Navigate to `res://resources/` (or create a `levels/` subfolder)
2. **Right-click** → New Resource
3. **Search**: Type "LevelConfig" and select it
4. **Save**: Name it descriptively (e.g., `espionage_level_config.tres`)
5. **Configure in Inspector**:
   - `level_name`: Display name (e.g., "Espionage on the Dance Floor")
   - `track_name`: Song title
   - `artist_name`: Artist name
   - `midi_file_path`: Path to MIDI file (e.g., `res://assets/tracks/espionage/espionage.mid`)
   - `audio_file_path`: Path to audio file (e.g., `res://assets/tracks/espionage/espionage.ogg`)

### Assigning LevelConfig to Levels

1. **Open** your level wrapper scene (e.g., `gameplay_level_1.tscn`)
2. **Select** the `%GameplayBase` node
3. **In Inspector**: Find `level_config` property
4. **Drag & Drop** your `.tres` resource file or click and select it

## Level Progression System

### Non-Linear Progression

The game uses **non-linear progression** where each level explicitly defines the next level:

**game_ui.tscn → LevelManager:**
- `starting_level_path`: First level to load (e.g., `gameplay_level_1.tscn`)
- `scene_lister`: **Removed** (not used in non-linear mode)

**Each level wrapper:**
- `next_level_path`: Path to next level or empty for final level

### Progression Flow

1. **Start**: LevelManager loads `starting_level_path`
2. **Play**: Player plays rhythm game
3. **Win Condition**: Track completes with < 25% miss rate
4. **Win Action**: 
   - `gameplay_base.gd` emits `level_won(next_level_path)`
   - `level.gd` forwards signal to LevelManager
   - LevelManager shows win window with "Continue" button
   - Continue loads the `next_level_path` from the wrapper
5. **Lose Condition**: ≥ 25% miss rate OR resonance depleted
6. **Lose Action**:
   - `gameplay_base.gd` emits `level_lost()`
   - LevelManager shows lose window with "Retry"/"Menu" buttons

### Final Level Behavior

For the **last level** in the game:
- Set `next_level_path` to **empty string** (`""`)
- On win, LevelManager shows `game_won_window.tscn` instead of `level_won_window.tscn`

## Win/Lose Conditions

### Win Condition
Track completes AND miss rate < 25%:
```gdscript
# In gameplay_base.gd:
var miss_rate: float = float(miss_count) / float(_total_beats)
if miss_rate < MISS_THRESHOLD_PERCENT:  # 0.25 = 25%
    level_won.emit(next_level_path)
```

### Lose Conditions

**1. Too Many Misses:**
- Track completes with miss rate ≥ 25%

**2. Resonance Depleted:**
- Resonance bar reaches zero during gameplay
- Immediately triggers `level_lost.emit()`

## Testing Levels

### Direct Scene Testing

**Test standalone** (without menu system):
1. Open `gameplay_base.tscn` directly
2. Set `test_midi_file` and `test_audio_file` in Inspector
3. Press F6 to run the scene
4. Gameplay will start automatically after 1 second

**Test with wrapper:**
1. Open `gameplay_level_1.tscn`
2. Ensure `%GameplayBase` has valid `level_config` or test files
3. Press F6 to run the scene

### Full Integration Testing

**Test complete flow** (menu → gameplay → windows):
1. Run main scene: [scenes/opening/opening.tscn](scenes/opening/opening.tscn)
2. Click "Play" button
3. Complete or fail the level
4. Verify win/lose windows appear correctly

## Adding Levels to Game

### Update Starting Level

To change which level starts the game:

1. **Open**: [scenes/game_scene/game_ui.tscn](scenes/game_scene/game_ui.tscn)
2. **Select**: `LevelManager` node
3. **In Inspector**: Update `starting_level_path` to your desired first level

### Level Chain Example

```
starting_level_path = "gameplay_level_1.tscn"
                              ↓
                    next_level_path = "gameplay_level_2.tscn"
                              ↓
                    next_level_path = "gameplay_level_3.tscn"
                              ↓
                    next_level_path = "" (final level)
                              ↓
                    game_won_window.tscn
```

## State Management

### GameState Integration

The `level.gd` script integrates with the GameState system:

```gdscript
func _ready() -> void:
    level_state = GameState.get_level_state(scene_file_path)
    # Loads per-level state (tutorial status, custom properties, etc.)
```

### Checkpoint System

The `level_and_state_manager.gd` automatically saves progress:

```gdscript
func set_checkpoint_level_path(value: String) -> void:
    super.set_checkpoint_level_path(value)
    GameState.set_checkpoint_level_path(value)  # Persists to disk
```

When a level is won, the checkpoint advances to the next level.

## Troubleshooting

### Level Won't Load

**Check:**
- Level path in `starting_level_path` or `next_level_path` is correct
- Level scene file exists at the specified path
- GameplayBase is named `%GameplayBase` (unique name)

### Music/Notes Don't Play

**Check:**
- `level_config` is assigned and has valid file paths
- MIDI and audio files exist at specified paths
- MIDI file has tempo map and note events
- Audio file is `.ogg` format

### Signals Not Firing

**Check:**
- GameplayBase has unique name: `%GameplayBase`
- `level.gd` script is attached to wrapper root node
- Check console for "GameplayBase: Track finished" message

### Win/Lose Window Doesn't Appear

**Check:**
- [game_ui.tscn](scenes/game_scene/game_ui.tscn) LevelManager has:
  - `level_won_scene` set to [level_won_window.tscn](scenes/windows/level_won_window.tscn)
  - `level_lost_scene` set to [level_lost_window.tscn](scenes/windows/level_lost_window.tscn)
  - `game_won_scene` set to [game_won_window.tscn](scenes/windows/game_won_window.tscn)

## Quick Reference

### File Locations

| Item | Path |
|------|------|
| Level Wrapper Template | `scenes/game_scene/levels/gameplay_level_X.tscn` |
| GameplayBase Scene | `scenes/game_scene/gameplay_base.tscn` |
| Level Script | `scenes/game_scene/levels/level.gd` |
| GameplayBase Script | `scenes/game_scene/gameplay_base.gd` |
| LevelConfig Script | `scripts/level_config.gd` |
| Game UI (Manager) | `scenes/game_scene/game_ui.tscn` |
| Level Manager Script | `scripts/level_and_state_manager.gd` |

### Key Export Variables

**Level Wrapper (level.gd):**
- `next_level_path`: Next level scene path or empty

**GameplayBase (gameplay_base.gd):**
- `level_config`: LevelConfig resource
- `test_midi_file`: Fallback MIDI path
- `test_audio_file`: Fallback audio path

**LevelManager (game_ui.tscn):**
- `starting_level_path`: First level to load
- `level_won_scene`: Win screen scene
- `level_lost_scene`: Lose screen scene
- `game_won_scene`: Game complete screen

### Signals

**gameplay_base.gd emits:**
- `level_won(next_level_path: String)` - Track completed successfully
- `level_lost` - Failed due to misses or resonance

**level.gd forwards:**
- `level_won(level_path: String)` - From GameplayBase to LevelManager
- `level_lost` - From GameplayBase to LevelManager
