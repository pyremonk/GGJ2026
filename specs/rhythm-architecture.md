# **Rhythm Game Architecture — Godot 4.5 (MIDI + Audio Driven)**

## 1. Core Principles
- Use a **MIDI file + audio track** as the authoritative timing sources.  
- Treat the MIDI tempo map as the **single source of truth** for beat timing.  
- Schedule gameplay events **ahead of time** using absolute timestamps.  
- Never rely on physics, collisions, or framerate for timing.  
- Keep components **modular**, **event‑driven**, and **single‑responsibility**.

---

## 2. Project Structure (High‑Level)
Copilot should generate and maintain code that fits this structure:

```
/scripts
    /audio
        MusicPlayer.gd
        LatencyCalibration.gd
    /midi
        MIDIEventRouter.gd
        NoteScheduler.gd
    /gameplay
        Judge.gd
        PlayerInput.gd
        Referee.gd
    /ui
        NoteDisplay.gd
        FeedbackDisplay.gd
```

---

## 3. Component Responsibilities

### **MusicPlayer**
- Loads and plays:
  - An audio track (e.g., OGG)
  - A MIDI file (parsed via plugin)
- Starts both in sync.
- Exposes:
  - `music_time_ms` — from audio playback position  
  - `midi_time_ms` — from MIDI playback position  
- Handles tempo changes automatically using the MIDI tempo map.
- Emits signals for:
  - `playback_started`
  - `playback_stopped`

---

### **MIDIEventRouter**
- Parses MIDI tracks and maps them to gameplay meaning.
- Supports:
  - Lane notes  
  - VFX triggers  
  - Special mechanics  
  - Hold notes (note-on + note-off)  
- Converts MIDI ticks → milliseconds using the tempo map.
- Emits structured events:
  - `note_event(lane, hit_time_ms)`
  - `vfx_event(id, time_ms)`
  - `mechanic_event(type, time_ms)`

---

### **NoteScheduler**
- Receives events from the router.
- Computes spawn times using:
  ```
  spawn_time_ms = hit_time_ms - travel_duration_ms
  ```
- Queues notes for spawning at the correct moment.
- Emits:
  - `spawn_note_instance(lane, hit_time_ms)`

---

### **PlayerInput**
- Listens for player key/button presses.
- Emits:
  - `input_pressed(action_name, input_time_ms)`

---

### **Judge**
- Receives:
  - Player input events  
  - Scheduled note hit times  
- Computes timing accuracy:
  - Perfect  
  - Good  
  - Miss  
- Uses configurable hit windows (in ms).
- Applies latency compensation:
  ```
  adjusted_input_time = input_time_ms + latency_offset_ms
  ```
- Emits:
  - `judge_success(note, rating)`
  - `judge_miss(note)`

---

### **Referee**
- Central coordinator.
- Listens to:
  - Judge results  
  - Scheduler events  
  - MusicPlayer state  
- Updates:
  - Score  
  - Combo  
  - Health  
  - Section transitions  
- Emits:
  - `score_changed`
  - `combo_changed`
  - `health_changed`
  - `section_changed`

---

### **Display Layer**
- Purely visual.  
- Never performs gameplay logic.  
- Subscribes to:
  - NoteScheduler (spawn notes)  
  - Judge (hit/miss feedback)  
  - Referee (score/combo/health)  
- Components:
  - NoteDisplay  
  - FeedbackDisplay  
  - HUD elements  

---

## 4. Latency Calibration
Copilot should generate a calibration scene with:

- A metronome click  
- Player taps along  
- System measures:
  ```
  latency_offset_ms = average(input_time_ms - click_time_ms)
  ```
- Store this offset in a global settings resource.
- All hit windows must apply this offset.

---

## 5. MIDI Track Conventions
Copilot should assume the following defaults unless overridden:

| MIDI Track | Purpose |
|-----------|---------|
| 1 | Lane 1 notes |
| 2 | Lane 2 notes |
| 3 | Lane 3 notes |
| 4 | Lane 4 notes |
| 5 | VFX triggers |
| 6 | Special mechanics |
| 7 | Scripted events |

Notes may also be mapped by pitch ranges if needed.

---

## 6. Code Style Expectations
Copilot should:

- Use **Godot 4.5 GDScript**.  
- Prefer **signals** over direct references.  
- Keep classes small and single‑purpose.  
- Use clear naming:
  - `hit_time_ms`
  - `spawn_time_ms`
  - `latency_offset_ms`
  - `lane_index`
- Avoid embedding chart logic in gameplay scripts.  
- Keep MIDI parsing isolated in the router.

### Indentation
- Use tabs for indentation, not spaces.

### Type System
- Always use explicit static types. Never rely on type inference.
- Variables: `var player_id: int = 0`
- Function returns: `func get_player_id() -> int:`
- Constants: `const MOVE_SPEED: float = 5.0`
- Replace all magic numbers and strings with named constants.

### Node References
- Use `@onready` with explicit type annotations and node path syntax.
- Example: `@onready var collision_shape: CollisionShape3D = $CollisionShape3D`
- Always specify the full type name (e.g., `CollisionShape3D`, never inferred types).
- This ensures type safety, performance (nodes are cached), and self-documenting code.

### Naming Conventions
- `snake_case` for functions and variables: `var player_position`, `func calculate_damage()`
- `PascalCase` for classes and types: `class PlayerController`, `enum GameState`
- Prefix private functions with underscore: `func _process_input() -> void:`

## 7. Code Organization

### Variable Declaration Order
1. Signals
2. Const declarations
3. @export variables
4. @onready variables
5. Regular var declarations

### Function Declaration Order
1. Built-in lifecycle functions (_ready, _process, _physics_process, etc.)
2. Private functions (prefixed with underscore)
3. Public functions

## 8. Control Flow

- Use null checks and early returns instead of nested conditionals.
- Use guard clauses to exit early.
- Example:
  ```gdscript
  # Bad: Nested conditionals
  func process_player(player: Node) -> void:
      if player != null:
          if player.is_alive():
              if player.has_weapon():
                  player.attack()
  
  # Good: Early returns
  func process_player(player: Node) -> void:
      if player == null:
          return
      if not player.is_alive():
          return
      if not player.has_weapon():
          return
      player.attack()
  ```

## 9. Error Handling

- Use explicit error handling. Never fail silently.
- Print errors or emit signals when issues occur.
- Example:
  ```gdscript
  func load_config(path: String) -> bool:
      if not FileAccess.file_exists(path):
          push_error("Config file not found: " + path)
          return false
      # Load config...
      return true
  ```

## 10. Data Structures

### Typed Classes vs Dictionaries
- Always use typed classes (`Resource` or `RefCounted`) instead of untyped dictionaries for data structures.
- Provides type safety, IDE autocomplete, and proper type inference.
- Use for: data transfer objects, configuration objects, state containers.

#### Data Transfer Objects
- Use `Resource` or `RefCounted` classes instead of dictionaries to pass data between nodes.
- Extend `Resource` for serialization/saving, or `RefCounted` for lightweight data objects.
- Example:
  ```gdscript
  class_name PlayerData
  extends Resource
  
  var player_name: String = ""
  var health: int = 100
  var position: Vector3 = Vector3.ZERO
  
  func _init(name: String = "", hp: int = 100, pos: Vector3 = Vector3.ZERO) -> void:
      player_name = name
      health = hp
      position = pos
  ```
- Usage:
  ```gdscript
  # Bad: Untyped dictionary
  func get_player_info() -> Dictionary:
      return {"name": "Player", "health": 100, "position": Vector3.ZERO}
  
  # Good: Typed class
  func get_player_info() -> PlayerData:
      return PlayerData.new("Player", 100, Vector3.ZERO)
  ```

### Abstract Base Classes
- Use `@abstract` for base classes that define shared behavior but cannot be directly instantiated.
- Abstract classes must extend a Godot type (Node, CharacterBody3D, etc.) and are for inheritance only.
- Example:
  ```gdscript
  @abstract
  class_name Character
  extends CharacterBody3D
  
  @export var health: int = 100
  @export var speed: float = 5.0
  @export var acc: float = 2.5  ## acceleration
  @export var dec: float = 5.0  ## deceleration
  ```
- Extend in child classes:
  ```gdscript
  class_name Player
  extends Character
  
  @export var stamina: float = 100.0
  ```

## 11. Code Architecture

### Composition Over Inheritance
- Use composition and component-based architecture instead of deep inheritance hierarchies.
- Attach scripts as components to nodes rather than creating complex base classes.
- Keep inheritance chains shallow (1-2 levels maximum).

### Loose Coupling
- Avoid tight coupling between systems and scripts.
- Use signals and event buses for communication between unrelated systems.
- Pass dependencies explicitly through function parameters or autoloads.
- Minimize direct node references. Use node paths or signals instead.

### Modularity
- Keep scripts focused on a single responsibility.
- Split large functionality into separate scripts/components.
- Organize code:
  - `systems/` - Cross-cutting concerns and managers
  - `autoloads/` - Global services used by multiple systems

## 12. Code Patterns

### Event Bus Signals
- Use public signals (no underscore prefix) in event bus systems.
- Provide wrapper functions to emit signals. Never emit signals directly from external code.
- Cache values as private variables with getter functions when needed.
- Example:
  ```gdscript
  signal player_moved(position: Vector3)
  var _current_player_position: Vector3 = Vector3.ZERO
  
  func emit_player_moved(position: Vector3) -> void:
      _current_player_position = position
      player_moved.emit(position)
  
  func get_player_position() -> Vector3:
      return _current_player_position
  ```
- This provides encapsulation, validation hooks, and a clear API surface.

## 13. Documentation

### Code Comments
- Avoid excessive documentation.
- Use self-documenting variable and function names.
- Only comment non-obvious logic or complex algorithms.

### Markdown Files
- Do not generate documentation (.md) files unless explicitly requested.

### UID Files
- Never manually create or edit Godot .uid files (`*.tscn.uid`, `*.gd.uid`, etc.).
- The Godot editor automatically manages these files.
- Manual editing causes conflicts and inconsistent asset metadata.

---

## 14. What Copilot Should Generate Automatically
When writing code in this project, Copilot should:

- Create signal‑driven components matching this architecture.  
- Generate helper functions for:
  - Tick → ms conversion  
  - Hit window evaluation  
  - Latency compensation  
- Produce clean, modular scripts that plug into the system.  
- Avoid monolithic “god classes.”  
- Use dependency injection via exported variables or signals.

---

## 15. What Copilot Should Avoid
- Do not embed timing logic in UI scripts.  
- Do not compute beat timing from BPM manually when MIDI tempo map exists.  
- Do not rely on `_physics_process` for timing‑critical logic.  
- Do not mix audio playback logic with MIDI parsing logic.  
- Do not hardcode lane mappings inside gameplay scripts.

---