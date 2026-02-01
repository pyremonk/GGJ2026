# Veilshifts Feature Specification

## Overview

**Veilshifts** are special notes that transform the player's appearance when successfully hit. These notes have specific MIDI velocity values that trigger sprite changes for both the note itself and the player, with corresponding UI feedback in the right panel.

## Core Concept

- Special notes spawn with unique mask sprites based on their MIDI velocity
- Successfully hitting a veilshift note changes the player's sprite to match
- UI indicators show which masks have been collected (full opacity = collected)
- Visual effect accompanies the transformation
- Player sprite resets to default on level load/scene change

## MIDI Velocity Mapping

| Velocity | Note Sprite         | On Hit: Player Sprite | UI Indicator  |
|----------|---------------------|----------------------|---------------|
| 69       | Player-Mask-1.png   | Player-Mask-1.png    | Mask1Icon → α=1.0 |
| 79       | Player-Mask-2.png   | Player-Mask-2.png    | Mask2Icon → α=1.0 |
| 89       | Player-Mask-3.png   | Player-Mask-3.png    | Mask3Icon → α=1.0 |
| 99       | Player-Mask-4.png   | Player-Mask-4.png    | Mask4Icon → α=1.0 |

**Note**: Velocity 99 listed for Mask-4 (correcting duplicate velocity 89 from original request)

## Asset Paths

### Note Sprites (Veilshift Variants)
- `res://assets/masks/Player-Mask-1.png`
- `res://assets/masks/Player-Mask-2.png`
- `res://assets/masks/Player-Mask-3.png`
- `res://assets/masks/Player-Mask-4.png` (assuming this exists)

### Default Player Sprite
- `res://assets/masks/Player-Mask.png`

### UI Indicators (Right Panel)
- `%Mask1Icon` - TextureRect in [right_panel.tscn](../scenes/game_scene/ui/right_panel.tscn)
- `%Mask2Icon` - TextureRect in [right_panel.tscn](../scenes/game_scene/ui/right_panel.tscn)
- `%Mask3Icon` - TextureRect in [right_panel.tscn](../scenes/game_scene/ui/right_panel.tscn)
- `%Mask4Icon` - TextureRect in [right_panel.tscn](../scenes/game_scene/ui/right_panel.tscn)

## Implementation Requirements

### 1. Note Classification

**File**: [scripts/gameplay/Note.gd](../scripts/gameplay/Note.gd)

- Add `is_veilshift: bool` property
- Add `veilshift_mask_id: int` property (1-4, or 0 for non-veilshift)
- Detect veilshift notes based on velocity in initialization
- Apply appropriate sprite texture on spawn

```gdscript
const VEILSHIFT_VELOCITIES: Dictionary = {
    69: {"mask_id": 1, "texture_path": "res://assets/masks/Player-Mask-1.png"},
    79: {"mask_id": 2, "texture_path": "res://assets/masks/Player-Mask-2.png"},
    89: {"mask_id": 3, "texture_path": "res://assets/masks/Player-Mask-3.png"},
    99: {"mask_id": 4, "texture_path": "res://assets/masks/Player-Mask-4.png"}
}
```

### 2. Note Spawning

**File**: [scripts/gameplay/NoteSpawner.gd](../scripts/gameplay/NoteSpawner.gd)

- Pass velocity data when spawning notes
- Ensure spawned notes configure themselves as veilshifts when applicable

### 3. Player Transformation

**File**: [scripts/gameplay/PlayerEffects.gd](../scripts/gameplay/PlayerEffects.gd) *(or new dedicated script)*

- Listen for successful veilshift hits via signal from Judge/Referee
- Change player sprite texture: `%Player.texture = load("res://assets/masks/Player-Mask-X.png")`
- Trigger transformation visual effect
- Emit signal for UI update: `veilshift_collected.emit(mask_id: int)`

**Player Node**: `%Player` in [gameplay_base.tscn](../scenes/game_scene/gameplay_base.tscn)

### 4. UI State Management

**File**: [scripts/ui/ui_state_manager.gd](../scripts/ui/ui_state_manager.gd) or [right_panel.gd](../scenes/game_scene/ui/right_panel.gd)

- Listen for `veilshift_collected` signal
- Update corresponding mask icon alpha to 1.0 (full opacity)
- Persist veilshift collection state per level (optional - depends on design intent)

**Example**:
```gdscript
func _on_veilshift_collected(mask_id: int) -> void:
    match mask_id:
        1: %Mask1Icon.modulate.a = 1.0
        2: %Mask2Icon.modulate.a = 1.0
        3: %Mask3Icon.modulate.a = 1.0
        4: %Mask4Icon.modulate.a = 1.0
```

### 5. Visual Effects

**Location**: PlayerEffects or dedicated VFX system

**Suggested Effect Sequence**:
1. On successful hit of veilshift note:
   - Play miss-like particle effect at note position (visual confusion/disruption)
   - Animate note sprite rushing toward player center
   - On collision with player:
     - Flash/pulse effect on player sprite
     - Swap player texture to new mask
     - Optional: emit mask-specific particle burst
     - Update UI indicator

**Audio**: Consider adding unique SFX for veilshift collection (distinct from normal hit sounds)

### 6. Scene Reset Logic

**File**: [scenes/game_scene/gameplay_base.gd](../scenes/game_scene/gameplay_base.gd)

- On `_ready()` or level initialization:
  - Reset player sprite to default: `%Player.texture = load("res://assets/masks/Player-Mask.png")`
  - Reset all mask icon alphas to 0.498 (current default per right_panel.tscn)

```gdscript
func _reset_veilshifts() -> void:
    %Player.texture = load("res://assets/masks/Player-Mask.png")
    %Mask1Icon.modulate.a = 0.498
    %Mask2Icon.modulate.a = 0.498
    %Mask3Icon.modulate.a = 0.498
    %Mask4Icon.modulate.a = 0.498
```

## Signal Architecture

### New Signals

**PlayerEffects** (or dedicated Veilshift manager):
```gdscript
signal veilshift_collected(mask_id: int)
```

**Judge/Referee** (extend existing hit signals):
```gdscript
# Option A: Extend existing hit_successful signal with note data
signal hit_successful(judgment: String, note: Note)

# Option B: New dedicated signal
signal veilshift_hit(mask_id: int, note: Note)
```

## Integration Points

### Existing Systems

1. **MIDIEventRouter** - Already passes velocity data; no changes needed
2. **NoteScheduler** - Velocity preserved in scheduled note data
3. **Judge** - On successful hit, check if note is veilshift and emit appropriate signals
4. **Referee** - May need awareness of veilshift state for scoring/combo logic (if masks affect gameplay)

### State Persistence (Optional)

If veilshifts should persist across level restarts (design decision needed):
- Add `collected_masks: Array[int]` to [LevelState](../scripts/level_state.gd)
- Save/load mask collection status with `GlobalState.save()`
- Restore UI and player sprite on level load

## Open Design Questions

1. **Persistence**: Should collected masks persist across level attempts, or reset on retry?
2. **Gameplay Impact**: Do collected masks unlock abilities, affect scoring, or purely cosmetic?
3. **Mask-4 Asset**: Confirm `Player-Mask-4.png` exists (only Mask-1 through Mask-6 and Player-Mask-1/2/3 seen in imports)
4. **Multiple Collection**: Can player collect same mask multiple times, or lock after first collection?
5. **Miss Behavior**: If veilshift note is missed, does it affect UI/state differently than normal miss?

## Testing Checklist

- [X] Veilshift notes spawn with correct sprite based on velocity
- [X] Non-veilshift notes unaffected by velocity values
- [X] Player sprite changes on successful hit
- [X] UI indicator updates to full opacity
- [X] Visual effect plays on transformation
- [X] Player sprite resets to default on level restart
- [X] UI indicators reset to default alpha on level restart
- [X] All 4 mask variants functional
- [ ] Edge case: Multiple rapid veilshift hits
- [ ] Edge case: Missing a veilshift note

## Related Specifications

- [gameplay-interactions.spec.md](gameplay-interactions.spec.md) - Hit/miss mechanics
- [note-spawning.spec.md](note-spawning.spec.md) - Note creation and initialization
- [rhythm-architecture.md](rhythm-architecture.md) - MIDI data flow
- [ui.spec.md](ui.spec.md) - Right panel structure

## Implementation Priority

**Phase 1 - Core Mechanics**:
1. Note velocity detection and sprite assignment
2. Player sprite transformation on hit
3. UI indicator updates

**Phase 2 - Polish**:
4. Visual effects
5. Audio feedback
6. State persistence (if needed)

**Phase 3 - Testing**:
7. Edge cases and integration testing
8. Balance adjustments based on gameplay feel
