# Screen Layout Specification

## Overview
**Last Night at the Masquerade** uses a fixed 16:9 aspect ratio with a default resolution of 1920 x 1080. The game window is resizable while maintaining the aspect ratio (handled by Godot's display settings).

**Important**: All positions and dimensions defined in this spec are based on the 1920x1080 base resolution. When the game window is resized, all positions should maintain their relative position within the viewport using proportional scaling.

## Layout Dimensions

### Screen Proportions
- **Total Resolution**: 1920 x 1080 (16:9 aspect ratio)
- **Main Gameplay Area**: 1080 x 1080 (center square)
- **Left UI Area**: 420 x 1080 (Score and Meta Info)
- **Right UI Area**: 420 x 1080 (Endgame Info)

### Column Structure
The screen is divided into three main vertical columns from left to right:

1. **Score and Meta Info UI Area** (Left Column)
   - Width: 420px
   - Height: 1080px
   - Position: x=0 to x=420

2. **Main Gameplay Area** (Center Column)
   - Width: 1080px
   - Height: 1080px
   - Position: x=420 to x=1500
   - This is a perfect square for the rhythm game grid

3. **Endgame Info UI Area** (Right Column)
   - Width: 420px
   - Height: 1080px
   - Position: x=1500 to x=1920

## Z-Layer Architecture

The game uses a layered approach to allow objects to spawn behind UI areas and become visible as they enter the gameplay area.

### Layer Order (Front to Back)
1. **UI Layer** (z-index: 100)
   - Left and right UI columns
   - Always on top
   - Non-interactive background elements in UI areas should allow visibility of gameplay objects passing behind

2. **Gameplay Layer** (z-index: 0)
   - Player character
   - Note targets
   - Active enemies/beats
   - Projectiles and effects

3. **Background/Spawn Layer** (z-index: -100)
   - Spawn points for enemies/beats
   - Objects in this layer become visible once they move into the gameplay area
   - Extends behind the UI columns

## Spawn Point Layout

### General Concept
Spawn points are positioned around the perimeter of the screen, including areas behind the left and right UI columns. Objects spawn at these points and travel into the main gameplay area, creating a sense of depth as they emerge from behind the UI.

### Spawn Point Positions
Spawn points are labeled with musical note names corresponding to their MIDI pitch assignments. Positions are approximate based on the reference layout:

#### Top Edge Spawn Points
- **D#4**: x=597, y=33 (top center-left)
- **E4**: x=689, y=13 (top center)
- **F4**: x=783, y=33 (top center-right)

#### Left Column Spawn Points (Behind Score UI)
- **D4**: x=347, y=287 (upper left)
- **C#4**: x=337, y=383 (middle left)
- **C4**: x=347, y=473 (lower left)

#### Right Column Spawn Points (Behind Endgame Info UI)
- **F#4**: x=1033, y=287 (upper right)
- **G4**: x=1043, y=411 (middle right)
- **G#4**: x=1033, y=497 (lower right)

#### Bottom Edge Spawn Points
- **B4**: x=597, y=723 (bottom center-left)
- **A#4**: x=689, y=677 (bottom center)
- **A4**: x=783, y=723 (bottom center-right)

#### Extended Offscreen Spawn Points
Additional spawn points exist fully offscreen for enemies/beats that need more approach time:
- **D#4 to F4 range**: Spawn points above top edge (offscreen)
- **B4 to A4 range**: Spawn points below bottom edge (offscreen)
- **C4 to D4 range**: Spawn points left of left edge (offscreen)
- **F#4 to G#4 range**: Spawn points right of right edge (offscreen)

*Note: All spawn point positions are configurable in the Godot editor or via code. Coordinates listed above are based on the 1920x1080 reference layout and are relative to the full screen space. When the game window is resized, these positions should scale proportionally to maintain their relative position within the viewport.*

## Main Gameplay Area Details

### Note Targets
The center of the gameplay area contains note targets arranged in a cross or radial pattern around the player position. These targets indicate where notes/beats should be hit for scoring.

**Note Target Layout:**
- Positioned around the player in the center of the gameplay square
- Typically 4 directional targets (up, down, left, right) or diagonal variants
- Distance from player center: approximately 100-150px
- Visual style: Circular indicators (see `assets/note_targets/`)

### Player Position
The player character is positioned at the center of the gameplay area:
- **Position**: x=960, y=540 (center of screen, center of gameplay square)
- **Visual**: Heart icon representing the player
- Player remains stationary while notes/enemies move toward them

### Gameplay Flow
1. Enemies/beats spawn at designated spawn points (including offscreen and behind UI)
2. Objects travel toward the note targets surrounding the player
3. As objects move from spawn points to gameplay area, they transition from behind UI to visible in the main gameplay area
4. Player timing inputs when enemies/beats reach the note targets

## UI Area Content Guidelines

### Score and Meta Info UI Area (Left)
- Game title/logo: "Last Night at the Masquerade" (bottom left)
- Score display
- Combo counter
- Current multiplier
- Additional meta information (defined in other specs)
- Spawn indicators for C4-D4 range (offscreen left) may appear as hints behind this area

### Endgame Info UI Area (Right)
- Veilshifts counter
- Power-up status
- Health/lives display
- Additional endgame statistics (defined in other specs)
- Spawn indicators for F#4-G#4 range (offscreen right) may appear as hints behind this area

## Implementation Notes

### Godot Configuration
- Set project display settings to 1920x1080 base resolution
- Enable "Aspect: Keep" mode to maintain 16:9 ratio on resize
- Configure viewport stretch mode as needed (e.g., `canvas_items`)
- Use viewport scaling to ensure all positions and UI elements maintain relative positioning when resized
- Consider using `get_viewport().size` to calculate positions relative to current viewport dimensions rather than hardcoding pixel values

### Scene Structure Recommendations
```
GameScene (CanvasLayer z=0)
├── BackgroundSpawnLayer (z=-100)
│   ├── SpawnPoints (Node2D container)
│   │   ├── SpawnPoint_D4
│   │   ├── SpawnPoint_CSharp4
│   │   └── ... (all spawn points)
│   └── OffscreenSpawnRegion
├── GameplayLayer (z=0)
│   ├── GameplayArea (1080x1080 centered)
│   │   ├── Player
│   │   ├── NoteTargets
│   │   └── ActiveObjects
│   └── BackgroundEffects
└── UILayer (CanvasLayer z=100)
    ├── LeftUI (420x1080)
    │   └── ScoreAndMetaInfo
    └── RightUI (420x1080)
        └── EndgameInfo
```

### Z-Index Management
- Use CanvasLayer nodes for major z-index separation
- Within layers, use Node2D z_index property for fine-tuning
- Ensure UI CanvasLayers have `layer` property set to higher values to render on top

## Visual Reference
See attached reference image: `specs/spec_ref_images/screen-layout-reference.png`

## Related Specifications
- Gameplay mechanics: `gameplay-overview.md`
- Rhythm/timing system: `rhythm-architecture.md`
- UI components: (to be defined)
- Enemy/beat spawning: (to be defined)
