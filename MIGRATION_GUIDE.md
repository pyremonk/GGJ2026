# MIDI to JSON Beat Chart Migration

This document describes the changes made to remove runtime MIDI plugin dependency and enable WebGL export.

## Overview

The game now uses pre-generated JSON beat chart files instead of parsing MIDI at runtime. This eliminates the need for the `godot-midi` GDExtension DLL, making WebGL export possible.

## Changes Made

### 1. New Beat Chart System

**Created Files:**
- `scripts/midi/BeatChart.gd` - Resource class for beat chart data
- `addons/beat_chart_generator/beat_chart_generator.gd` - Editor script to generate JSON from MIDI
- `addons/beat_chart_generator/plugin.gd` - Auto-generation plugin
- `addons/beat_chart_generator/plugin.cfg` - Plugin configuration
- `addons/beat_chart_generator/README.md` - Plugin documentation

**Beat Chart Structure:**
```gdscript
class_name BeatChart extends Resource
- beat_events: Array[Dictionary]  # Timing data for each note
- tempo_map: Array[Dictionary]    # BPM changes over time
- metadata: Dictionary            # Track info, duration, etc.
```

### 2. Modified Core Systems

**MIDIEventRouter.gd:**
- Changed `load_midi_data(midi_resource, tempo_map)` → `load_beat_chart(beat_chart_path)`
- Removed runtime MIDI parsing: `_parse_midi_track()`, `_check_track_has_notes()`, `_ticks_to_ms()`
- Added `_load_beats_from_chart()` to convert JSON data to BeatEvent objects
- Updated `_generate_beats_from_tempo()` to use beat chart tempo map
- Removed dependencies on MidiResource properties

**MusicPlayer.gd:**
- Changed `load_files(audio, midi_resource)` → `load_files(audio)`
- Removed `_midi_resource` property
- Removed `get_tempo_map()` and `get_midi_resource()` methods
- Simplified to only handle audio playback

**LevelConfig.gd:**
- Changed `@export var midi_resource: Resource` → `@export_file("*.beats.json") var beat_chart_path: String`
- Updated `is_valid()` to check `beat_chart_path` instead of `midi_resource`

**gameplay_base.gd:**
- Changed test exports: `test_midi_file` → `test_beat_chart`
- Updated `_start_test_level()` to load beat charts instead of MIDI
- Simplified loading flow: no more tempo map extraction

**rhythm_test.gd:**
- Changed `_midi_resource` → `_beat_chart_path`
- Updated UI buttons: `midi_file_button` → `beat_chart_button`
- Updated file dialogs to select `.beats.json` files
- Removed MIDI resource loading logic

### 3. Updated Resource Files

**Level Configs:**
- `scenes/game_scene/levels/level_1_config.tres` - Points to `Testing_Track.beats.json`
- `scenes/game_scene/levels/level_2_config.tres` - Points to `Espionage on the Dance Floor MIDI Map.beats.json`
- `scenes/game_scene/levels/level_3_config.tres` - Points to `Tower-of-Babel-Midi-Mapping.beats.json`

**Scene Files:**
- `scenes/game_scene/gameplay_base.tscn` - Updated inline LevelConfig resource

## Next Steps

### 1. Generate Beat Chart JSON Files

**Option A: Enable Plugin (Recommended)**
1. Open Godot editor
2. Go to **Project > Project Settings > Plugins**
3. Enable "Beat Chart Generator"
4. Select any `.mid` file in FileSystem
5. Right-click → **Reimport**
6. Plugin will auto-generate `.beats.json` files

**Option B: Run Generator Script**
1. Open `addons/beat_chart_generator/beat_chart_generator.gd`
2. Go to **File > Run** (Ctrl+Shift+X)
3. Script will scan and generate all beat charts

Expected output files:
- `assets/testing_track/Testing_Track.beats.json`
- `assets/tracks/espionage/Espionage on the Dance Floor MIDI Map.beats.json`
- `assets/tracks/tower-of-bassle/Tower-of-Babel-Midi-Mapping.beats.json`

### 2. Update Scene UI References

**rhythm_test.tscn needs updating:**
The scene still references nodes that may need renaming:
- `%MIDIFileButton` → `%BeatChartButton`
- `%MIDIFileDialog` → `%BeatChartDialog`

Open `scenes/rhythm_test/rhythm_test.tscn` in the editor and verify/update node names.

### 3. Test in Editor

1. Run `scenes/opening/opening.tscn` (main scene)
2. Start a level and verify notes spawn correctly
3. Check console output for "Loaded beat chart" messages
4. Run `scenes/rhythm_test/rhythm_test.tscn` for debugging

### 4. Configure WebGL Export

**Export Preset Settings:**
1. Go to **Project > Export**
2. Select or create "HTML5" export preset
3. In **Resources** tab, exclude the MIDI plugin:
   - Add filter: `addons/godot_midi/bin/*`
   - Or mark `godot_midi` plugin as "Editor Only"

**Verify:**
- Export the project
- Check that no `.wasm` or `.dll` files from godot_midi are included
- Test the exported build in a browser

### 5. Update Existing MIDI Edits

**Workflow for MIDI changes:**
1. Edit `.mid` file in your MIDI editor
2. Save the file
3. Godot will auto-import and trigger beat chart regeneration
4. `.beats.json` file will be updated automatically
5. No code changes needed!

**Manual regeneration:**
- If auto-generation doesn't trigger, use **FileSystem > Reimport**
- Or run the generator script manually

## Technical Details

### MIDI Note Mapping

Both the generator and game use identical mapping (CRITICAL - must stay in sync):

```gdscript
const TARGET_MAPPING: Dictionary = {
    60: "left",    # C4 (Middle C)
    61: "left",    # C#4
    62: "left",    # D4
    63: "up",      # D#4
    64: "up",      # E4
    65: "up",      # F4
    66: "right",   # F#4
    67: "right",   # G4
    68: "right",   # G#4
    69: "down",    # A4
    70: "down",    # A#4
    71: "down"     # B4
}
```

Files using this mapping:
- `addons/beat_chart_generator/beat_chart_generator.gd`
- `scripts/midi/MIDIEventRouter.gd`
- `scripts/gameplay/NoteSpawner.gd`

### JSON Format Example

```json
{
    "beat_events": [
        {
            "hit_time_ms": 1000.0,
            "beat_number": 0,
            "midi_note": 69,
            "direction": "down",
            "velocity": 80
        }
    ],
    "tempo_map": [
        {
            "time_ms": 0.0,
            "bpm": 120.0,
            "ppq": 480
        }
    ],
    "metadata": {
        "track_name": "Testing_Track",
        "source_midi": "res://assets/testing_track/Testing_Track.mid",
        "total_beats": 100,
        "duration_ms": 60000.0,
        "generated_timestamp": "2026-02-07T12:00:00"
    }
}
```

### Auto-Generation vs Authored Notes

The system supports two modes (determined automatically):

**Authored Mode** (when beat_events exists):
- Uses note timing from MIDI track
- Preserves exact note placement
- Supports different directions per note

**Auto-Generated Mode** (when beat_events is empty):
- Generates beats at regular intervals
- Uses tempo_map for BPM changes
- All beats default to "down" direction
- Controlled by `beat_subdivision` export variable

## Troubleshooting

**Error: "Failed to load beat chart"**
- Verify `.beats.json` file exists next to `.mid` file
- Check LevelConfig `beat_chart_path` is correct
- Regenerate beat chart if MIDI was recently modified

**No beats spawning in game**
- Check console for "Loaded beat chart" message
- Verify beat_events array is not empty in JSON
- Ensure MIDIEventRouter.load_beat_chart() is called before generate_beat_events()

**MIDI plugin still included in export**
- Check export preset resource filters
- Verify `addons/godot_midi/bin/` is excluded
- Clear export cache and re-export

**Beat chart not auto-generating**
- Ensure plugin is enabled in Project Settings
- Check Output panel for error messages
- Try manual reimport or run generator script

## Files Safe to Delete (After Verification)

Once the system is tested and working, these files are no longer needed at runtime:
- `scripts/midi/midi_api_test.gd` (development/testing only)

**DO NOT delete:**
- `addons/godot_midi/` folder (still needed for editor-time MIDI import)
- `.mid` files (source files for beat chart generation)

## Backward Compatibility

**Breaking Changes:**
- Old LevelConfig resources with `midi_resource` will not work
- Runtime code expecting `music_player.get_tempo_map()` will fail
- Any custom scripts calling `midi_router.load_midi_data()` need updating

**Migration:**
1. Generate beat charts for all MIDI files
2. Update all LevelConfig resources to use `beat_chart_path`
3. Update custom scripts to use `load_beat_chart(path)` instead of `load_midi_data()`

## Performance Notes

**Benefits:**
- No runtime MIDI parsing overhead
- Faster level loading (JSON parsing vs MIDI parsing)
- Smaller runtime memory footprint
- WebGL compatibility

**Considerations:**
- JSON files are slightly larger than MIDI (text vs binary)
- Beat charts must be regenerated when MIDI changes
- Version control includes generated files (add `.beats.json` to git)

## Future Enhancements

Potential improvements:
- Binary beat chart format for smaller file size
- Beat chart diff/merge tools for version control
- In-editor beat chart preview
- Batch generation command-line tool
- Beat chart validation on export

---

**Migration Date:** February 7, 2026  
**Godot Version:** 4.5  
**Plugin Version:** 1.0
