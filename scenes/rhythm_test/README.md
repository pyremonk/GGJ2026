# Rhythm Game Architecture - Test Scene

Complete implementation of the rhythm game architecture with MIDI-driven timing.

## Quick Start

1. **Open the test scene**: `scenes/rhythm_test/rhythm_test.tscn`
2. **Default files are pre-loaded**: Testing_Track.ogg and Testing_Track.mid
3. **Optional - Calibrate latency**: Click "Calibrate Latency" and tap spacebar 8 times on the metronome beats
4. **Select beat subdivision**: Quarter Notes (default) or Eighth Notes
5. **Press Start**: Music begins, tap spacebar to the beat
6. **Watch feedback**: 
   - Moving bar indicator shows when to tap
   - Rating + offset shows timing accuracy (e.g., "PERFECT +5ms")
   - Score and combo update in real-time

## Architecture Components

### Data Classes
- **BeatEvent** (`scripts/midi/BeatEvent.gd`) - Beat timing data
- **HitRating** (`scripts/gameplay/HitRating.gd`) - Rating system with thresholds

### Audio System
- **MusicPlayer** (`scripts/audio/MusicPlayer.gd`) - Synced audio + MIDI playback
- **LatencyCalibration** (`scripts/audio/LatencyCalibration.gd`) - Metronome-based calibration

### MIDI System
- **MIDIEventRouter** (`scripts/midi/MIDIEventRouter.gd`) - Hybrid beat generation:
  - Checks MIDI track 1 for authored beat notes
  - Falls back to auto-generated beats from tempo map
- **NoteScheduler** (`scripts/midi/NoteScheduler.gd`) - Schedules upcoming beats

### Gameplay System
- **PlayerInput** (`scripts/gameplay/PlayerInput.gd`) - Precise input timing
- **Judge** (`scripts/gameplay/Judge.gd`) - Timing accuracy with latency compensation
- **Referee** (`scripts/gameplay/Referee.gd`) - Score, combo, statistics tracking

### UI System
- **BeatIndicator** (`scripts/ui/BeatIndicator.gd`) - Moving bar visual
- **FeedbackDisplay** (`scripts/ui/FeedbackDisplay.gd`) - Rating + offset display

## Signal Flow

```
MIDIEventRouter generates beats
    ↓
NoteScheduler schedules beats → upcoming_beat
    ↓
BeatIndicator animates
    ↓
PlayerInput detects spacebar → input_pressed
    ↓
Judge evaluates timing → judgment_made
    ↓
├─→ FeedbackDisplay shows rating
└─→ Referee updates score/combo
```

## Hit Windows

- **Perfect**: ±50ms → 100 points
- **Great**: ±100ms → 75 points
- **Good**: ±150ms → 50 points
- **Miss**: Beyond ±150ms → 0 points, breaks combo

## Testing Different Files

1. Click "Audio: ..." button to select a different audio file
2. Click "MIDI: ..." button to select a different MIDI file
3. Both files must be selected before Start button enables

## MIDI File Requirements

- Must have tempo map metadata
- Optional: Place note-on events in track 1 for custom beat patterns
- If track 1 is empty, beats auto-generate from tempo

## Architecture Notes

- **All timing uses `Time.get_ticks_msec()`** for precision
- **MIDI tempo map is the single source of truth** for beat timing
- **Signal-driven architecture** - no tight coupling between components
- **Modular design** - each script has a single responsibility
- **Type-safe** - explicit static types throughout

## Next Steps

This test scene validates the core architecture. For the full game:
1. Add multi-lane support (4 lanes with different input keys)
2. Integrate with shoot 'em up gameplay (spawn enemies on beats)
3. Add grid-based movement synchronized to beats
4. Implement combo multipliers and power-ups
5. Create level progression system
