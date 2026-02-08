# Beat Chart System Issue - Diagnosis and Fix

## Problem Summary
The beat chart system is not working because **all beat chart JSON files are empty** - they contain zero beat events. The game loads these empty beat charts, resulting in no notes spawning during gameplay.

## Root Cause
The beat chart generator (`addons/beat_chart_generator/beat_chart_generator.gd`) is running but failing to extract MIDI note events from .mid files. It successfully extracts tempo maps but returns zero beat events.

## Affected Files
All three beat chart files are empty:
- `assets/testing_track/Testing_Track.beats.json` (0 beats)
- `assets/tracks/espionage/Espionage on the Dance Floor MIDI Map.beats.json` (0 beats)
- `assets/tracks/tower-of-bassle/Tower-of-Babel-Midi-Mapping.beats.json` (0 beats)

## Diagnostic Steps

### Step 1: Test MIDI Plugin API
The beat chart generator may be using the wrong API methods to access MIDI events. We need to discover the actual API.

**Option A: Run the existing MIDI API test scene**
1. Open `scripts/midi/midi_api_test.gd` in the editor
2. Attach it to a Node in a test scene or run it as an EditorScript
3. Check the console output to see available methods and properties

**Option B: Run from command line** (if Godot is in PATH)
```bash
godot --headless --script scripts/midi/midi_api_test.gd
```

### Step 2: Run Beat Chart Generator with Debug Output
I've added extensive debug logging to the beat chart generator. To regenerate with debug output:

1. Open Godot Editor
2. Go to **File > Run** 
3. Select `addons/beat_chart_generator/beat_chart_generator.gd`
4. Click "Run"
5. Check the **Output** panel for debug messages showing:
   - MIDI resource type
   - Track count
   - Events found per track
   - Event structure
   - Note-on events found
   - Mapped notes

## Expected Debug Output Analysis

The generator expects MIDI events in this format:
```gdscript
{
	"type": "note",
	"subtype": 9,  # Note-on
	"velocity": 64,  # 1-127
	"note": 60,     # 60-71 (C4-B4)
	"delta": 480    # Ticks since last event
}
```

If the actual MIDI plugin provides events in a different format, we'll need to update the generator.

## Common Issues and Fixes

### Issue 1: MIDI plugin uses different event structure
**Symptoms:** Debug shows events found but structure doesn't match expected format  
**Fix:** Update `_extract_beat_events()` to use correct property names

### Issue 2: MIDI plugin uses different method names
**Symptoms:** Debug shows "No track count method or property found!" or track_count = 0  
**Fix:** Update the API calls in the generator based on MIDI API test output

### Issue 3: MIDI files don't contain notes in range 60-71
**Symptoms:** Debug shows note-on events but notes are outside 60-71 range  
**Fix:** Either:
- Update `TARGET_MAPPING` in the generator to include the actual note range
- Re-export MIDI files with notes in the C4-B4 range (60-71)

### Issue 4: MIDI import not working
**Symptoms:** MIDI resource fails to load or returns null  
**Fix:** 
- Reimport MIDI files: Right-click each .mid file → Reimport
- Check that godot_midi plugin is enabled in Project Settings → Plugins

## Immediate Workaround: Use Auto-Generated Beats

If MIDI note extraction can't be fixed quickly, the system has a fallback mode that generates beats automatically from the tempo map:

**In `scripts/midi/MIDIEventRouter.gd`:**
The `generate_beat_events()` method already has this logic:
```gdscript
if has_notes:
    print("MIDIEventRouter: Using authored notes from beat chart")
    _beat_events = _load_beats_from_chart()
else:
    print("MIDIEventRouter: Using auto-generated beats from tempo")
    _beat_events = _generate_beats_from_tempo()
```

Since beat charts are empty, it should fall back to auto-generated beats. If this isn't working:
1. Check console for "MIDIEventRouter: Using auto-generated beats from tempo" message
2. The auto-generated beats will all be "down" direction (S key)
3. This is playable but not ideal - proper MIDI notes are needed for 4-direction gameplay

## Testing After Fix

1. Regenerate beat charts using File > Run on `beat_chart_generator.gd`
2. Verify JSON files now contain beat events:
   ```bash
   cat "assets/testing_track/Testing_Track.beats.json" | grep -A 5 beat_events
   ```
3. Run a gameplay level and verify notes spawn
4. Check console for "GameplayBase: Loaded X beat events" (should be > 0)

## Current Status

✅ **Completed:**
- Diagnosed issue (empty beat charts)
- Added comprehensive debug logging to beat chart generator
- Identified potential API mismatch
- System has auto-generated beat fallback

⏳ **Next Steps:**
1. Run MIDI API test to determine correct API
2. Run beat chart generator to see debug output
3. Fix generator based on findings
4. Regenerate all beat charts
5. Test gameplay

## Files Modified

- `addons/beat_chart_generator/beat_chart_generator.gd` - Added debug output
- `scripts/midi/midi_debug_test.gd` - Created alternative debug script
