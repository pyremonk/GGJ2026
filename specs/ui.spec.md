# UI Specification

## Overview
**Last Night at the Masquerade** features a three-column layout with UI panels on the left and right sides of the central gameplay area. This specification defines the UI elements, their behavior, and the data they display.

**Related Specifications:**
- Screen layout and dimensions: [screen-layout.spec.md](screen-layout.spec.md)
- Gameplay mechanics: [gameplay-overview.md](gameplay-overview.md)
- Rhythm system: [rhythm-architecture.md](rhythm-architecture.md)

**Visual Reference:**
See: `specs/spec_ref_images/UI Layout Reference.png`

## Screen Division Recap

For reference (detailed in [screen-layout.spec.md](screen-layout.spec.md)):
- **Total Resolution**: 1920 x 1080 (16:9 aspect ratio)
- **Left UI Area** (Score and Meta Info): 420px wide, x=0 to x=420
- **Center Gameplay Area**: 1080px wide, x=420 to x=1500
- **Right UI Area** (Endgame Info): 420px wide, x=1500 to x=1920

*Note: All positions are based on 1920x1080 base resolution and scale proportionally when the game window is resized.*

## Score and Meta Info UI Area (Left Column)

### Overview
The left UI panel displays real-time gameplay statistics including score, combo, and the player's closeness to failure (Resonance system).

### Location
- **Position**: x=0 to x=420, y=0 to y=1080
- **Width**: 420px
- **Height**: 1080px

### UI Elements

#### 1. Game Title Display
**Description**: Game logo/title image  
**Asset**: `assets/ui_labels/UI-Label_Night-at-the-Masquerade.png`  
**Position**: Bottom of left panel (approximate y=950-1050)  
**Behavior**: Static display throughout gameplay

#### 2. Score Display
**Description**: Shows the player's current score  
**Components**:
- **Label Image**: `assets/ui_labels/UI-Label_Score.png`
- **Value Display**: Dynamic text showing numeric score value

**Position**: Upper portion of left panel (approximate y=100-200)  
**Initial Value**: 0  
**Update Behavior**: 
- Increments based on judgment ratings from the Judge component
- Score calculations handled by Referee component (see [rhythm-architecture.md](rhythm-architecture.md))
- Updates in real-time as judgments are made

**Data Source**: 
- `Referee.score_changed` signal
- Existing implementation in rhythm test scene: `scenes/rhythm_test/rhythm_test.gd` (lines 230-231)

**Implementation Example**:
```gdscript
@onready var score_label: Label = %ScoreLabel

func _on_score_changed(score: int) -> void:
	score_label.text = "Score: %d" % score
```

#### 3. Combo Display
**Description**: Shows the player's current combo count  
**Components**:
- **Label Image**: `assets/ui_labels/UI-Label_Combo.png`
- **Value Display**: Dynamic text showing combo count

**Position**: Below score display (approximate y=250-350)  
**Initial Value**: 0  
**Update Behavior**:
- Increments with each successful hit (Perfect, Good, OK ratings)
- Resets to 0 on Miss judgment
- Managed by Referee component

**Data Source**:
- `Referee.combo_changed` signal
- Existing implementation in rhythm test scene: `scenes/rhythm_test/rhythm_test.gd` (lines 233-234)

**Implementation Example**:
```gdscript
@onready var combo_label: Label = %ComboLabel

func _on_combo_changed(combo: int) -> void:
	combo_label.text = "Combo: %d" % combo
```

#### 4. Resonance Display
**Description**: Health-bar style indicator showing how close the player is to failing the level based on miss ratio

**Components**:
- **Label**: "RESONANCE" text or UI label image
- **Health Bar**: Visual progress bar or fill indicator
- **Stats Text**: Shows hits/total notes (e.g., "110 / 126")
- **Percentage**: Accuracy percentage (inverse of miss threshold)

**Position**: Middle section of left panel (approximate y=400-600)

**Visual Design**:
- Health bar starts at 100% (full)
- Depletes as player misses notes
- Color coding recommended (green → yellow → red as it depletes)

**Failure Threshold**:
- **Default**: 25% of total level notes missed = failure
- Configurable per level via LevelState
- Calculation: `miss_ratio = misses / total_notes`
- Failure occurs when: `miss_ratio >= 0.25`

**Display Elements**:

##### Health Bar Fill
- **Type**: ProgressBar or TextureProgressBar
- **Range**: 0 to 100 (percentage)
- **Initial Value**: 100
- **Update Formula**: `resonance_percentage = 100 - (miss_ratio * 100)`
- **Update Trigger**: After each judgment (especially Miss judgments)

##### Hit/Total Text
- **Format**: "HITS / TOTAL" (e.g., "110 / 126")
- **HITS**: Number of notes successfully hit (all ratings except Miss)
- **TOTAL**: Total number of notes in the level
- **Update Trigger**: After each judgment

##### Accuracy Percentage
- **Format**: "XX%" (e.g., "98%")
- **Calculation**: `accuracy = (hits / total_notes) * 100`
- **Alternative Calculation**: `accuracy = 100 - ((misses / total_notes) * 100)`
- **Update Trigger**: After each judgment
- **Visual**: Display next to or below the health bar

**Data Requirements**:
- Total note count: Available from MIDI file parsing / NoteScheduler
- Current hits: Track Perfect, Good, OK judgments
- Current misses: Track Miss judgments
- Source: Referee component should track these statistics

**Implementation Considerations**:
```gdscript
@onready var resonance_bar: ProgressBar = %ResonanceBar
@onready var resonance_text: Label = %ResonanceText
@onready var resonance_accuracy: Label = %ResonanceAccuracy

var total_notes: int = 0
var hits: int = 0
var misses: int = 0

func _on_total_notes_determined(count: int) -> void:
	total_notes = count

func _on_judgment_made(beat: BeatEvent, offset_ms: float, rating: HitRating.Rating) -> void:
	if rating == HitRating.Rating.MISS:
		misses += 1
	else:
		hits += 1
	
	_update_resonance_display()

func _update_resonance_display() -> void:
	var miss_ratio: float = float(misses) / float(total_notes) if total_notes > 0 else 0.0
	var resonance_percentage: float = 100.0 - (miss_ratio * 100.0)
	var accuracy: float = (float(hits) / float(total_notes) * 100.0) if total_notes > 0 else 100.0
	
	resonance_bar.value = resonance_percentage
	resonance_text.text = "%d / %d" % [hits, total_notes]
	resonance_accuracy.text = "%.0f%%" % accuracy
	
	# Check for failure condition
	if miss_ratio >= 0.25:  # 25% threshold
		_trigger_level_failure()
```

**Failure State**:
- When Resonance reaches failure threshold (default 25% miss ratio), emit level failure signal
- Level emits `level_lost` signal to LevelManager
- Transition to loss screen

## Endgame Info UI Area (Right Column)

### Overview
The right UI panel displays collectible progress (Veilshifts/Masks) and music track information.

### Location
- **Position**: x=1500 to x=1920, y=0 to y=1080
- **Width**: 420px
- **Height**: 1080px

### UI Elements

#### 1. Veilshifts Display
**Description**: Shows player progress in collecting masks during the level

**Components**:
- **Label Image**: `assets/ui_labels/UI-Label_Veilshifts.png`
- **Mask Icons**: 4 mask images representing collectibles

**Position**: Upper portion of right panel (approximate y=150-500)

**Mask Assets**:
- `assets/masks/Mask-1.png`
- `assets/masks/Mask-2.png`
- `assets/masks/Mask-3.png`
- `assets/masks/Mask-4.png`

**Visual States**:

##### Uncollected State (Default)
- **Opacity**: 50% (modulate alpha = 0.5)
- **Appearance**: Faded/ghosted mask image
- **Status**: Not yet unlocked

##### Collected State
- **Opacity**: 100% (modulate alpha = 1.0)
- **Appearance**: Full brightness mask image
- **Status**: Successfully unlocked
- **Transition**: Fade animation from 50% to 100% opacity

**Unlock Logic**:
- Mask unlocking logic will be defined in a separate specification
- Likely triggered by gameplay milestones (e.g., score thresholds, combo milestones, specific note patterns)
- Each mask unlocked independently

**Level Completion Condition**:
- **Requirement**: All 4 masks must be collected AND audio track must complete
- When both conditions are met, level emits `level_won(next_level_path)` signal
- Transition to victory screen

**Implementation Example**:
```gdscript
@onready var mask_icons: Array[TextureRect] = [
	%Mask1Icon,
	%Mask2Icon,
	%Mask3Icon,
	%Mask4Icon
]

var masks_collected: Array[bool] = [false, false, false, false]

func _ready() -> void:
	_initialize_mask_display()

func _initialize_mask_display() -> void:
	for i in range(mask_icons.size()):
		mask_icons[i].modulate.a = 0.5  # Start at 50% opacity

func _on_mask_collected(mask_index: int) -> void:
	if mask_index >= 0 and mask_index < masks_collected.size():
		masks_collected[mask_index] = true
		
		# Animate opacity change
		var tween: Tween = create_tween()
		tween.tween_property(mask_icons[mask_index], "modulate:a", 1.0, 0.3)
		
		_check_level_completion()

func _check_level_completion() -> void:
	var all_masks_collected: bool = masks_collected.all(func(m: bool) -> bool: return m)
	var track_finished: bool = music_player.is_finished()
	
	if all_masks_collected and track_finished:
		level_won.emit(next_level_path)
```

#### 2. Now Playing Display
**Description**: Shows information about the current music track

**Components**:
- **Label Image**: `assets/ui_labels/UI-Label_Now-Playing.png`
- **Track Name**: Dynamic text
- **Artist/Creator**: Dynamic text
- **Progress Bar**: Visual indicator of track playback progress
- **Time Display**: Current time / Total duration

**Position**: Lower portion of right panel (approximate y=600-1000)

**Display Elements**:

##### Track Name
- **Type**: Label or RichTextLabel
- **Content**: Name of the current level's music track
- **Source**: Level metadata or MIDI file metadata
- **Example**: "Testing Track"

##### Artist/Creator
- **Type**: Label
- **Content**: "By: [Artist Name]"
- **Source**: Level metadata
- **Example**: "By: Musician"
- **Position**: Below track name

##### Progress Bar
- **Type**: ProgressBar or custom visual indicator
- **Range**: 0 to track duration (in seconds or milliseconds)
- **Update**: Real-time based on MusicPlayer playback position
- **Visual**: Linear bar showing playback progress

##### Time Display
- **Type**: Label
- **Format**: "MM:SS / MM:SS" (current time / total duration)
- **Example**: "1:48 / 3:30"
- **Update Frequency**: Every frame or every second
- **Source**: `MusicPlayer.get_current_time_ms()` and track duration

**Data Requirements**:
- Track name: From level configuration or MIDI file
- Artist name: From level configuration
- Current playback position: `MusicPlayer.get_current_time_ms()`
- Total track duration: `MusicPlayer.get_duration_ms()` or calculated from MIDI tempo map

**Implementation Example**:
```gdscript
@onready var track_name_label: Label = %TrackNameLabel
@onready var artist_label: Label = %ArtistLabel
@onready var track_progress_bar: ProgressBar = %TrackProgressBar
@onready var time_display_label: Label = %TimeDisplayLabel

var track_duration_ms: float = 0.0

func _ready() -> void:
	_initialize_track_info()

func _initialize_track_info() -> void:
	# Load from level configuration
	track_name_label.text = level_config.track_name  # e.g., "Testing Track"
	artist_label.text = "By: %s" % level_config.artist_name
	
	# Get duration from MusicPlayer or MIDI tempo map
	track_duration_ms = music_player.get_duration_ms()
	track_progress_bar.max_value = track_duration_ms

func _process(delta: float) -> void:
	if music_player.is_playing():
		_update_now_playing_display()

func _update_now_playing_display() -> void:
	var current_time_ms: float = music_player.get_current_time_ms()
	
	# Update progress bar
	track_progress_bar.value = current_time_ms
	
	# Update time display
	var current_minutes: int = int(current_time_ms / 60000.0)
	var current_seconds: int = int((current_time_ms % 60000.0) / 1000.0)
	var total_minutes: int = int(track_duration_ms / 60000.0)
	var total_seconds: int = int((track_duration_ms % 60000.0) / 1000.0)
	
	time_display_label.text = "%d:%02d / %d:%02d" % [
		current_minutes,
		current_seconds,
		total_minutes,
		total_seconds
	]
```

## Layout Integration

### Scene Hierarchy Recommendation
```
GameLevel (Node2D)
├── BackgroundSpawnLayer (z=-100)
├── GameplayLayer (z=0)
├── UILayer (CanvasLayer z=100)
│   ├── LeftUI (Control, anchor left)
│   │   ├── GameTitleImage (TextureRect)
│   │   ├── ScoreSection (VBoxContainer)
│   │   │   ├── ScoreLabelImage (TextureRect)
│   │   │   └── ScoreValue (Label)
│   │   ├── ComboSection (VBoxContainer)
│   │   │   ├── ComboLabelImage (TextureRect)
│   │   │   └── ComboValue (Label)
│   │   └── ResonanceSection (VBoxContainer)
│   │       ├── ResonanceLabelImage (TextureRect)
│   │       ├── ResonanceBar (ProgressBar)
│   │       ├── ResonanceStats (Label) # "110 / 126"
│   │       └── ResonanceAccuracy (Label) # "98%"
│   └── RightUI (Control, anchor right)
│       ├── VeilshiftsSection (VBoxContainer)
│       │   ├── VeilshiftsLabelImage (TextureRect)
│       │   └── MaskContainer (HBoxContainer or GridContainer)
│       │       ├── Mask1Icon (TextureRect)
│       │       ├── Mask2Icon (TextureRect)
│       │       ├── Mask3Icon (TextureRect)
│       │       └── Mask4Icon (TextureRect)
│       └── NowPlayingSection (VBoxContainer)
│           ├── NowPlayingLabelImage (TextureRect)
│           ├── TrackNameLabel (Label)
│           ├── ArtistLabel (Label)
│           ├── TrackProgressBar (ProgressBar)
│           └── TimeDisplayLabel (Label)
```

### Anchor and Positioning Guidelines
- **LeftUI**: Anchor preset = Top Left, expand vertically
- **RightUI**: Anchor preset = Top Right, expand vertically
- Use VBoxContainer/HBoxContainer for automatic layout within panels
- Ensure proper margins to prevent UI elements from touching screen edges
- Use unique node names (%) for easy reference in scripts

## Data Structures

### Level Configuration Resource
```gdscript
class_name LevelConfig
extends Resource

## Configuration for a gameplay level including UI metadata

@export var level_name: String = ""
@export var track_name: String = ""
@export var artist_name: String = ""
@export var midi_file_path: String = ""
@export var audio_file_path: String = ""
@export var next_level_path: String = ""

# Resonance system
@export var miss_threshold_percentage: float = 0.25  # 25% = failure

# Mask unlock conditions (to be defined in separate spec)
@export var mask_unlock_conditions: Array[Dictionary] = []
```

### UI State Manager
```gdscript
class_name UIStateManager
extends Node

## Manages UI state and updates for gameplay HUD

signal mask_collected(mask_index: int)
signal resonance_depleted()
signal track_completed()

@onready var referee: Node = %Referee
@onready var music_player: Node = %MusicPlayer

var total_notes: int = 0
var hits: int = 0
var misses: int = 0
var masks_collected: Array[bool] = [false, false, false, false]

func initialize(note_count: int) -> void:
	total_notes = note_count
	hits = 0
	misses = 0
	masks_collected = [false, false, false, false]

func update_judgment(rating: HitRating.Rating) -> void:
	if rating == HitRating.Rating.MISS:
		misses += 1
	else:
		hits += 1
	
	_check_resonance()

func collect_mask(mask_index: int) -> void:
	if mask_index >= 0 and mask_index < 4 and not masks_collected[mask_index]:
		masks_collected[mask_index] = true
		mask_collected.emit(mask_index)

func get_resonance_percentage() -> float:
	if total_notes == 0:
		return 100.0
	var miss_ratio: float = float(misses) / float(total_notes)
	return 100.0 - (miss_ratio * 100.0)

func get_accuracy_percentage() -> float:
	if total_notes == 0:
		return 100.0
	return (float(hits) / float(total_notes)) * 100.0

func _check_resonance() -> void:
	if total_notes == 0:
		return
	
	var miss_ratio: float = float(misses) / float(total_notes)
	if miss_ratio >= 0.25:  # Default threshold
		resonance_depleted.emit()
```

## Integration with Existing Systems

### Rhythm Test Scene Compatibility
The scoring and combo system from `scenes/rhythm_test/rhythm_test.gd` can be directly reused:
- Score tracking: Lines 230-231 (`_on_score_changed`)
- Combo tracking: Lines 233-234 (`_on_combo_changed`)
- Judgment handling: Lines 222-224 (`_on_judgment_made`)

### Signal Flow
```
Judge.judgment_made
  → Referee._on_judgment_made (updates score/combo)
  → UIStateManager.update_judgment (updates resonance)
  → UI components update displays

NoteScheduler.upcoming_beat
  → (increments total_notes counter)

MaskUnlockSystem.mask_unlocked
  → UIStateManager.collect_mask
  → UI updates mask opacity

MusicPlayer.playback_finished
  → Check if all masks collected
  → Emit level_won if complete
```

## Visual Assets Reference

### UI Label Images
All label images located in: `assets/ui_labels/`
- `UI-Label_Score.png`
- `UI-Label_Combo.png`
- `UI-Label_Night-at-the-Masquerade.png`
- `UI-Label_Veilshifts.png`
- `UI-Label_Now-Playing.png`

### Mask Images
All mask images located in: `assets/masks/`
- `Mask-1.png`
- `Mask-2.png`
- `Mask-3.png`
- `Mask-4.png`

## Implementation Checklist

### Score and Meta Info UI
- [ ] Create LeftUI container with proper anchoring
- [ ] Add Score display with label image and dynamic value
- [ ] Add Combo display with label image and dynamic value
- [ ] Add Resonance section with:
  - [ ] Label/title
  - [ ] Progress bar (health bar style)
  - [ ] Hits/Total text display
  - [ ] Accuracy percentage display
- [ ] Connect to Referee signals for score/combo updates
- [ ] Implement resonance calculation and failure detection
- [ ] Add game title image at bottom

### Endgame Info UI
- [ ] Create RightUI container with proper anchoring
- [ ] Add Veilshifts section with:
  - [ ] Label image
  - [ ] 4 mask icon displays
  - [ ] Initial 50% opacity state
- [ ] Implement mask collection system:
  - [ ] Opacity transition animation (50% → 100%)
  - [ ] Mask unlock signal handling
- [ ] Add Now Playing section with:
  - [ ] Label image
  - [ ] Track name display
  - [ ] Artist name display
  - [ ] Progress bar
  - [ ] Time display (current/total)
- [ ] Connect to MusicPlayer for playback info
- [ ] Implement level completion check (all masks + track finished)

### Data and State Management
- [ ] Create LevelConfig resource structure
- [ ] Create UIStateManager script
- [ ] Integrate with existing Referee component
- [ ] Add total notes tracking from NoteScheduler
- [ ] Implement mask unlock conditions (see separate spec)

### Testing and Polish
- [ ] Test with rhythm test scene components
- [ ] Verify responsive scaling at different resolutions
- [ ] Test failure condition (25% miss threshold)
- [ ] Test mask collection and level completion
- [ ] Add visual feedback animations (score pop, combo counter, etc.)
- [ ] Ensure UI elements don't overlap with gameplay area

## Future Enhancements

### Visual Polish
- Animated number changes (score counter tween)
- Particle effects on mask collection
- Screen shake or pulse on combo milestones
- Color shifts on resonance bar based on health level
- Glow effects on collected masks

### Additional Stats
- Perfect/Good/OK/Miss breakdown
- Max combo achieved
- Current multiplier display
- Accuracy rating letter grade (S, A, B, C, D, F)

### Accessibility
- Colorblind-friendly resonance bar colors
- Text size scaling options
- High contrast mode for UI elements

## Related Specifications
- Screen layout: [screen-layout.spec.md](screen-layout.spec.md)
- Gameplay overview: [gameplay-overview.md](gameplay-overview.md)
- Rhythm architecture: [rhythm-architecture.md](rhythm-architecture.md)
- Note spawning: [note-spawning.spec.md](note-spawning.spec.md)
- Mask unlock conditions: (to be defined)
