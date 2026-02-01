class_name UIStateManager
extends Node

## Manages UI state and updates for gameplay HUD.
## Tracks hits, misses, resonance, mask collection, and emits signals for UI updates.

## Emitted when a mask is collected (mask_index: 0-3)
signal mask_collected(mask_index: int)

## Emitted when resonance depletes below failure threshold
signal resonance_depleted()

## Emitted when the audio track completes playback
signal track_completed()

## Emitted when resonance display should update
signal resonance_updated(percentage: float, hits: int, total: int, accuracy: float)

## Emitted when mask unlock conditions should be checked
signal check_mask_unlocks(combo: int, score: int)

## Total number of notes in the level
var total_notes: int = 0

## Number of notes successfully hit (Perfect, Good, OK)
var hits: int = 0

## Number of notes missed
var misses: int = 0

## Mask collection state (4 masks total)
var masks_collected: Array[bool] = [false, false, false, false]

## Reference to the level's configuration
var level_config: LevelConfig = null


## Initialize the state manager with note count and level config
func initialize(note_count: int, config: LevelConfig = null) -> void:
	total_notes = note_count
	hits = 0
	misses = 0
	masks_collected = [false, false, false, false]
	level_config = config
	
	_emit_resonance_update()


## Reset all tracked statistics
func reset() -> void:
	hits = 0
	misses = 0
	masks_collected = [false, false, false, false]
	_emit_resonance_update()


## Update statistics based on a judgment rating
func update_judgment(rating: int, combo: int, score: int) -> void:
	# HitRating.Rating enum: PERFECT = 0, GREAT = 1, GOOD = 2, MISS = 3
	if rating == HitRating.Rating.MISS:  # MISS = 3
		misses += 1
	else:
		hits += 1
	
	_emit_resonance_update()
	_check_resonance()
	
	# Check if masks should be unlocked based on combo/score
	check_mask_unlocks.emit(combo, score)


## Attempt to collect a specific mask
func collect_mask(mask_index: int) -> void:
	if mask_index < 0 or mask_index >= 4:
		push_warning("UIStateManager: Invalid mask_index %d" % mask_index)
		return
	
	if masks_collected[mask_index]:
		return  # Already collected
	
	masks_collected[mask_index] = true
	mask_collected.emit(mask_index)


## Returns the current resonance percentage (100 = full health, 0 = failure)
## Scales from 100% at 0 misses to 0% at 25% miss threshold
func get_resonance_percentage() -> float:
	if total_notes == 0:
		return 100.0
	
	var threshold: float = 0.25  # 25% miss threshold
	if level_config != null:
		threshold = level_config.miss_threshold_percentage
	
	# Calculate miss ratio against total level notes
	var miss_ratio: float = float(misses) / float(total_notes)
	
	# Scale: 0% misses = 100% resonance, threshold misses = 0% resonance
	var resonance: float = 100.0 - ((miss_ratio / threshold) * 100.0)
	return clampf(resonance, 0.0, 100.0)


## Returns the accuracy percentage (hits out of notes played so far)
func get_accuracy_percentage() -> float:
	var notes_played: int = hits + misses
	if notes_played == 0:
		return 100.0
	
	return (float(hits) / float(notes_played)) * 100.0


## Returns true if all masks have been collected
func are_all_masks_collected() -> bool:
	return masks_collected.all(func(m: bool) -> bool: return m)


## Returns the number of masks currently collected
func get_masks_collected_count() -> int:
	var count: int = 0
	for collected: bool in masks_collected:
		if collected:
			count += 1
	return count


## Check if resonance has depleted below failure threshold
func _check_resonance() -> void:
	if total_notes == 0:
		return
	
	var threshold: float = 0.25  # Default threshold
	if level_config != null:
		threshold = level_config.miss_threshold_percentage
	
	var miss_ratio: float = float(misses) / float(total_notes)
	if miss_ratio >= threshold:
		resonance_depleted.emit()


## Emit resonance update signal with current stats
func _emit_resonance_update() -> void:
	var resonance_pct: float = get_resonance_percentage()
	var accuracy_pct: float = get_accuracy_percentage()
	resonance_updated.emit(resonance_pct, hits, total_notes, accuracy_pct)
