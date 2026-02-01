# Gameplay Base Scene Setup Instructions

The `gameplay_base.tscn` scene is the main gameplay scene that integrates all rhythm game systems with the shoot 'em up UI and layout.

## Scene Structure Overview

- **BackgroundSpawnLayer** (layer -1) - Contains 12 spawn points for notes (C4-B4)
- **GameplayLayer** - Contains Player, NoteTargets, and ActiveObjects
- **UILayer** (layer 2) - Contains LeftUI and RightUI panels

## Setup Steps

### 1. Set Test Files (Inspector - Root Node)

Select the `GameplayBase` root node and configure these exported variables:

**Required:**
- `test_midi_file`: `res://assets/testing_track/Testing_Track.mid`
- `test_audio_file`: `res://assets/testing_track/Testing_Track.ogg`

**Optional:**
- `level_config`: Leave empty for test mode (or create a LevelConfig resource)
- `next_level_path`: Leave empty for test mode

### 2. Configure MusicPlayer Node

Select `%MusicPlayer` node and set:
- `audio_delay_ms`: `2000.0` (2 seconds to allow notes to spawn and animate before audio starts)
- `default_bpm`: `120.0`
- Leave `audio_stream` and `midi_file_path` empty (set by code at runtime)

### 3. Configure NoteScheduler Node

Select `%NoteScheduler` node and set:
- `lookahead_ms`: `5000.0` (must be > `audio_delay_ms` to schedule notes before audio plays)

### 4. Configure MIDIEventRouter Node

Select `%MIDIEventRouter` node and set:
- `beat_subdivision`: `4` (quarter notes)
- `target_track_index`: `1` (check MIDI track 1 for authored notes)

### 5. Configure NoteSpawner Node

The `note_scene` property should already be set to `res://scenes/game_scene/note.tscn` ✅

All other properties are set by code in `_setup_rhythm_system()`

### 6. Verify Scene Structure

The scene should have:
- `BackgroundSpawnLayer` (layer -1) with 12 spawn points (C4-B4)
- `GameplayLayer` with Player, NoteTargets, and ActiveObjects
- `UILayer` (layer 2) with LeftUI and RightUI panels

All rhythm system nodes (`MusicPlayer`, `MIDIEventRouter`, `NoteScheduler`, `PlayerInput`, `Judge`, `Referee`, `NoteSpawner`, `UIStateManager`) should have unique names (`%`) and proper scripts attached.

## Testing the Scene

**Run the scene directly** (F6) from `gameplay_base.tscn`:

1. It will auto-load the test track on startup
2. After 1 second delay, music should start
3. Notes should spawn from spawn points and fly toward targets
4. Press **S key** (or Down arrow) when notes reach the center target
5. Watch UI update with score, combo, and resonance

## Expected Behavior

- Notes spawn 5 seconds before their hit time (lookahead)
- Audio starts 2 seconds after playback begins (audio_delay_ms)
- Notes should reach the center target exactly when the beat hits
- UI panels show real-time score, combo, resonance, and track info

## Troubleshooting

### Audio finishes immediately
- Verify test files exist and paths are correct in Inspector
- Check console for "GameplayBase: Loaded X beat events" message
- Ensure MIDI file has valid tempo map

### Notes don't spawn
- Check that all 12 spawn point nodes exist under `BackgroundSpawnLayer/SpawnPoints`
- Verify `NoteSpawner.note_scene` is set to the note scene
- Check that `lookahead_ms` (5000) > `audio_delay_ms` (2000)

### Input doesn't register
- Verify `move_down` input action is mapped to S key in Project Settings
- Check that PlayerInput node exists with script attached
- Ensure Judge and Referee nodes are properly connected

### UI doesn't update
- Verify LeftUI and RightUI scenes are properly instantiated
- Check that UIStateManager node exists and has script attached
- Confirm signal connections in `_connect_referee_signals()`

## Key Configuration Values

| Component | Property | Value | Purpose |
|-----------|----------|-------|---------|
| MusicPlayer | `audio_delay_ms` | 2000.0 | Delay audio start to allow note spawn animations |
| NoteScheduler | `lookahead_ms` | 5000.0 | Schedule notes this far in advance |
| MIDIEventRouter | `beat_subdivision` | 4 | Quarter notes (4) or eighth notes (8) |
| MIDIEventRouter | `target_track_index` | 1 | MIDI track to check for authored notes |

## Input Controls

- **S key** or **Down arrow**: Hit notes in the down/center position
- Additional directions (W/A/D or arrow keys) can be mapped for multi-lane gameplay

## Architecture Reference

See [`specs/rhythm-architecture.md`](../specs/rhythm-architecture.md) for detailed system design and signal flow diagrams.
