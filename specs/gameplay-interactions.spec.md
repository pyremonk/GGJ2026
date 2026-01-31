# Gameplay Interactions Specification

This document defines the core player input actions, their mappings, and UI feedback for level outcomes.

## Player Input Actions

### Up Action
**Purpose**: Hit notes traveling downward toward the player

**Input Mappings**:
- **Keyboard**: `W` key
- **Keyboard (Arrow)**: `Up Arrow` key
- **Controller (D-Pad)**: Up direction
- **Controller (Face Button)**: Y button (Xbox layout)

**Target**: Notes traveling down toward the note target above the player

---

### Down Action
**Purpose**: Hit notes traveling upward toward the player

**Input Mappings**:
- **Keyboard**: `S` key
- **Keyboard (Arrow)**: `Down Arrow` key
- **Controller (D-Pad)**: Down direction
- **Controller (Face Button)**: A button (Xbox layout)

**Target**: Notes traveling up toward the note target below the player

---

### Left Action
**Purpose**: Hit notes traveling rightward toward the player

**Input Mappings**:
- **Keyboard**: `A` key
- **Keyboard (Arrow)**: `Left Arrow` key
- **Controller (D-Pad)**: Left direction
- **Controller (Face Button)**: X button (Xbox layout)

**Target**: Notes traveling right toward the note target to the left of the player

---

### Right Action
**Purpose**: Hit notes traveling leftward toward the player

**Input Mappings**:
- **Keyboard**: `D` key
- **Keyboard (Arrow)**: `Right Arrow` key
- **Controller (D-Pad)**: Right direction
- **Controller (Face Button)**: B button (Xbox layout)

**Target**: Notes traveling left toward the note target to the right of the player

---

## Level Outcome UI

### Level Failed
**Trigger**: Player fails to meet level completion requirements

**UI Display**: "You have failed" message

**Player Options**:
1. **Restart Level** - Reload the current level from the beginning
2. **Exit to Main Menu** - Return to the main menu scene
3. **Level Selection** - Open level picker scene (to be defined later)

---

### Level Completed
**Trigger**: Player successfully completes level requirements

**UI Display**: "Success!" message

**Player Options**:
1. **Restart Level** - Replay the current level from the beginning
2. **Next Level** - Progress to the next level in sequence
3. **Level Selection** - Open level picker scene (to be defined later)

---

## Notes

- Input mappings follow standard action-game conventions (WASD + arrow keys for keyboard)
- Controller mappings use Xbox layout as reference
- Note travel directions are relative to the player's central position
- Level picker scene implementation details TBD
