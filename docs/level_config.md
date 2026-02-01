# LevelConfig Resource

**LevelConfig** is a custom Godot `Resource` class that stores all metadata and configuration for a single gameplay level. It acts as a data container that defines level properties, file references, and gameplay parameters.

## What It Contains

### Display Metadata

- `level_name` - Display name (e.g., "Level 1: The Awakening")
- `track_name` - Song title shown in "Now Playing" UI (e.g., "Night at the Masquerade")
- `artist_name` - Composer/artist name (e.g., "DJ Veilshift")

### File References

- `midi_file_path` - Path to MIDI file (e.g., `res://assets/levels/level_1.mid`)
- `audio_file_path` - Path to audio file (e.g., `res://assets/levels/level_1.ogg`)
- `next_level_path` - Path to next level scene (e.g., `res://scenes/game_scene/levels/level_2.tscn`)

### Gameplay Parameters

- `miss_threshold_percentage` - Failure threshold (default: 0.25 = 25% misses allowed)
- `mask_unlock_conditions` - Array of unlock criteria for the 4 masks (to be implemented)

## How to Create a LevelConfig Resource

### In Godot Editor

1. Right-click in FileSystem dock
2. Select **New Resource**
3. Choose **LevelConfig** from the list
4. Save as `level_1_config.tres` (or similar)

### Configure in Inspector

1. Set all string fields (level name, track name, artist)
2. Browse to select MIDI and audio files
3. Set next level path if applicable
4. Adjust miss threshold if needed (0.25 = 25%)

### Assign to Level Scene

1. Open your level scene (e.g., `level_1.tscn`)
2. Select root node
3. Drag the `.tres` resource to the `level_config` exported variable

## How It's Used in Code

### In gameplay_base.gd

```gdscript
@export var level_config: LevelConfig = null

func _start_level() -> void:
    if level_config and level_config.is_valid():
        # Load files from config
        var audio_stream = load(level_config.audio_file_path)
        music_player.load_files(audio_stream, level_config.midi_file_path)
        
        # Use config data for UI
        right_ui.set_track_info(
            level_config.track_name,
            level_config.artist_name,
            music_player.get_duration_ms()
        )
```

### In UIStateManager

```gdscript
func initialize(note_count: int, config: LevelConfig = null) -> void:
    level_config = config
    # Use config for mask unlock logic, etc.
```

## Test Mode vs Production Mode

### Test Mode (Current Setup)

- `level_config` = `null`
- Uses hardcoded test files: `test_midi_file` and `test_audio_file`
- Good for development and testing
- Falls back to default values

### Production Mode (For Actual Levels)

- Create a LevelConfig resource for each level
- Assign to level scene's root node
- Code checks: "if level_config exists, use it; else use test files"
- Full metadata displayed in UI

## Benefits

✅ **Data-driven**: Change level metadata without touching code  
✅ **Reusable**: Same gameplay scene, different configs  
✅ **Type-safe**: Godot validates file paths and types  
✅ **Inspector-friendly**: Easy to edit in Godot Editor  
✅ **Persistent**: Saved as `.tres` files in version control  
✅ **Validation**: Built-in `is_valid()` method checks required fields

## Example Workflow

### Step 1: Create Config Resource

Create `resources/levels/level_1_config.tres`:

```
level_name: "Midnight Waltz"
track_name: "Ballroom Shadows"
artist_name: "The Veilshifters"
midi_file_path: res://assets/levels/waltz.mid
audio_file_path: res://assets/levels/waltz.ogg
next_level_path: res://scenes/game_scene/levels/level_2.tscn
miss_threshold_percentage: 0.25
```

### Step 2: Assign to Level Scene

1. Open `scenes/game_scene/levels/level_1.tscn`
2. Select root `GameplayBase` node
3. Drag `level_1_config.tres` to the `level_config` property

### Step 3: Level Loads Automatically

The level will:
- Load correct MIDI and audio files
- Display track metadata in UI
- Use configured miss threshold
- Transition to next level on completion

## Validation

The `is_valid()` method checks that all required fields are populated:

```gdscript
func is_valid() -> bool:
    if level_name.is_empty():
        push_warning("LevelConfig: level_name is empty")
        return false
    if track_name.is_empty():
        push_warning("LevelConfig: track_name is empty")
        return false
    if midi_file_path.is_empty():
        push_warning("LevelConfig: midi_file_path is empty")
        return false
    if audio_file_path.is_empty():
        push_warning("LevelConfig: audio_file_path is empty")
        return false
    return true
```

Always call `level_config.is_valid()` before using the config to ensure all required data is present.

## Debugging

Use `get_debug_string()` for logging:

```gdscript
print(level_config.get_debug_string())
# Output: LevelConfig[Midnight Waltz] - Track: 'Ballroom Shadows' by The Veilshifters
```

## Related Files

- **Implementation**: [`scripts/level_config.gd`](../scripts/level_config.gd)
- **Usage**: [`scenes/game_scene/gameplay_base.gd`](../scenes/game_scene/gameplay_base.gd)
- **UI Integration**: [`scripts/ui/ui_state_manager.gd`](../scripts/ui/ui_state_manager.gd)

## Architecture Pattern

This follows the **Resource-based configuration** approach recommended in the project architecture, keeping game data separate from game logic. This pattern is consistent with Godot's best practices and makes levels easy to author and maintain.
