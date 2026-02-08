# Beat Chart Generator Plugin

This plugin generates JSON beat chart files from MIDI resources, eliminating the need for the godot-midi runtime DLL and enabling WebGL export.

## Setup

### 1. Enable the Plugin

1. Open the Godot editor
2. Go to **Project > Project Settings > Plugins**
3. Enable "Beat Chart Generator"

When enabled, the plugin will automatically generate `.beats.json` files whenever MIDI files are imported or reimported.

### 2. Generate Initial Beat Charts

To generate beat charts for all existing MIDI files:

**Option A: Automatic (Recommended)**
1. In the Godot editor, select any `.mid` file in the FileSystem dock
2. Right-click and select **Reimport**
3. The plugin will automatically generate the corresponding `.beats.json` file
4. Repeat for each MIDI file, or use **Reimport** on the containing folder

**Option B: Manual Script Execution**
1. Open `addons/beat_chart_generator/beat_chart_generator.gd` in the editor
2. Go to **File > Run** (or press Ctrl+Shift+X)
3. The script will scan `assets/` for all `.mid` files and generate `.beats.json` files

## Generated Files

The plugin scans for MIDI files in:
- `assets/testing_track/Testing_Track.mid`
- `assets/tracks/espionage/Espionage on the Dance Floor MIDI Map.mid`
- `assets/tracks/tower-of-bassle/Tower-of-Babel-Midi-Mapping.mid`

For each `.mid` file, it generates a `.beats.json` file in the same directory containing:
- **beat_events**: Array of timing data (hit_time_ms, direction, velocity, etc.)
- **tempo_map**: Array of tempo changes with BPM and timing
- **metadata**: Track info, duration, generation timestamp

## Beat Chart Format

Example JSON structure:

```json
{
	"beat_events": [
		{
			"hit_time_ms": 0.0,
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

## Usage in Game

After generating beat charts, update your `LevelConfig` resources to reference the `.beats.json` files instead of MIDI resources:

```gdscript
# Old:
@export var midi_resource: Resource = null

# New:
@export_file("*.beats.json") var beat_chart_path: String = ""
```

## MIDI Note Mapping

The generator uses the same note-to-direction mapping as the game:
- **60-62** (C4-D4): Left
- **63-65** (D#4-F4): Up
- **66-68** (F#4-G#4): Right
- **69-71** (A4-B4): Down

## Troubleshooting

**Beat chart not generated after MIDI import:**
- Check the Output panel for error messages
- Ensure the plugin is enabled
- Manually run the generator script

**"Failed to load beat chart" error:**
- Verify the `.beats.json` file exists next to the `.mid` file
- Check file path in `LevelConfig` is correct
- Regenerate the beat chart if MIDI was recently modified

**WebGL export still includes MIDI plugin:**
- Ensure `godot_midi` plugin is disabled in export preset
- Or mark it "Editor Only" in plugin settings
