# Last Night at the Masquerade

A rhythm game built in Godot 4.5.1.

## Overview

**Last Night at the Masquerade** is a rhythm game where players navigate a masked ball, hitting directional notes in sync with the music. Built for Global Game Jam 2026, this project showcases a MIDI-based timing architecture that treats the tempo map as the single source of truth, enabling gameplay regardless of tempo changes.

### Key Features

- **MIDI-Driven Timing** - Absolute timestamp scheduling with dynamic tempo support
- **4-Direction Note Gameplay** - Arrow-key-based rhythm mechanics with visual feedback
- **Modular Architecture** - Event-driven components with clear separation of concerns

## Getting Started

### Prerequisites

- [Godot 4.5](https://godotengine.org/download) or later
- Git (for cloning the repository)

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/GGJ2026.git
   cd GGJ2026
   ```

2. Open the project in Godot 4.5:
   - Launch Godot
   - Click "Import"
   - Navigate to the project folder and select `project.godot`
   - Click "Import & Edit"

3. Run the game:
   - Press **F5** or click the "Play" button in the editor
   - The game will start from `scenes/opening/opening.tscn`

### Quick Start for Testing

- **Test specific levels**: Open any level scene in `scenes/game_scene/levels/` and run it directly
- **Reset game state**: Delete `user://global_state.tres` to clear all progress

## Documentation

Comprehensive guides are available in the [`docs/`](docs/) directory:

- **[Creating Levels](docs/creating_levels.md)** - Complete guide for building new rhythm levels
- **[Level Configuration](docs/level_config.md)** - Setting up level parameters and MIDI mappings
- **[Beat Chart Debug Guide](docs/beat_chart_debug_guide.md)** - Troubleshooting timing and note spawning
- **[Gameplay Base Scene Setup](docs/gameplay_base_scene_setup.md)** - Core scene architecture

### Architecture Documentation

Technical specifications in the [`specs/`](specs/) directory:

- **[Rhythm Architecture](specs/rhythm-architecture.md)** - MIDI-based timing system design
- **[Note Spawning](specs/note-spawning.spec.md)** - Note spawn mechanics and scheduling
- **[Gameplay Interactions](specs/gameplay-interactions.spec.md)** - Combat and player mechanics
- **[Screen Layout](specs/screen-layout.spec.md)** - UI positioning and visual design
- **[Veilshifts](specs/veilshifts.spec.md)** - Special gameplay mechanics

## Project Structure

```
GGJ2026/
├── addons/
│   ├── beat_chart_generator/    # Charting tool plugin
│   └── godot_midi/              # MIDI parsing and playback
├── assets/                      # Game assets (sprites, audio, fonts)
├── docs/                        # Documentation and guides
├── scenes/
│   ├── game_scene/levels/       # Playable level scenes
│   ├── menus/                   # Menu screens
│   └── opening/                 # Main entry point
├── scripts/
│   ├── audio/                   # Music and sound controllers
│   ├── gameplay/                # Game mechanics and player logic
│   └── midi/                    # MIDI event routing and note scheduling
├── specs/                       # Technical specifications
└── resources/                   # Godot resources (themes, translations)
```

## Architecture Highlights

### State Management

The game uses a two-tier Resource-based state system (originally built from maaacks_game_template):

- **GlobalState** (autoload) - Persistent storage singleton managing all game state
- **GameState** - Static wrapper accessing `GlobalState.get_or_create_state()`
- **LevelState** - Per-level data (tutorial progress, custom properties)

Always access state through static methods on `GameState`, never directly instantiate:

```gdscript
var level_state: LevelState = GameState.get_level_state(scene_file_path)
level_state.tutorial_read = true
GlobalState.save()  # Always call after modifying state
```

### MIDI Timing System

The rhythm system uses:

- **MusicPlayer** - Synchronized MIDI and audio playback
- **MIDIEventRouter** - Parses MIDI events and routes to gameplay systems
- **NoteScheduler** - Schedules note spawns using absolute timestamps
- **Judge** - Evaluates player input timing accuracy
- **PlayerInput** - Processes arrow key inputs
- **Referee** - Manages scoring and combo tracking

**Critical**: Direction naming refers to the **spawn side** (which corresponds to the input key):
- "left" = spawns from LEFT, player presses LEFT arrow
- "right" = spawns from RIGHT, player presses RIGHT arrow
- "up" = spawns from TOP, player presses UP arrow
- "down" = spawns from BOTTOM, player presses DOWN arrow

## Development

### Code Conventions

This project follows strict GDScript conventions:

- **Static typing required**: `var player_id: int = 0`, `func get_score() -> int:`
- **Named constants** over magic numbers: `const MAX_HEALTH: int = 100`
- **Snake_case** for functions/variables, **PascalCase** for classes
- **Tabs for indentation** (not spaces)
- **Early returns** over nested conditionals

### Adding New Levels

1. Duplicate an existing level in `scenes/game_scene/levels/`
2. Create a `LevelConfig` resource with MIDI file and track references
3. Update the level's `next_level_path` export
4. Add the level to the menu system
5. Test by running from `scenes/opening/opening.tscn`

See [Creating Levels](docs/creating_levels.md) for detailed instructions.

## Contributing

This project was created for Global Game Jam 2026. Contributions are welcome! Please:

1. Follow the existing code conventions (see [copilot-instructions.md](.github/copilot-instructions.md))
2. Test your changes thoroughly
3. Update documentation if adding new features
4. Keep commits focused and descriptive

## Credits

### Development
- Built with [Godot Engine 4.5](https://godotengine.org/)
- [Maaack's Game Template](https://github.com/Maaack/Godot-Game-Template) - Scene loading and UI framework
- [Godot MIDI Plugin](https://github.com/AdamOBrien/godot-midi) - MIDI parsing and playback

### Assets
- See [ATTRIBUTION.md](ATTRIBUTION.md) for full asset credits
- Logo and masks used for Last Night at the Masquerade

### Special Thanks
- Global Game Jam 2026 organizers and participants & the Vancouver Island Game Developers group.

## License

This project is licensed under the MIT License - see the [LICENSE.txt](LICENSE.txt) file for details.

## Additional Resources

- **Migration Guide**: [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md) - Upgrading from previous template versions
- **Beat Chart Generator**: [addons/beat_chart_generator/README.md](addons/beat_chart_generator/README.md)

---

**Built with ❤️ for Global Game Jam 2026**
