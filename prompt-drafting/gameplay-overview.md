## Game Overview
Blast Tempo is a vertical scroller shoot'em up & rhythm game where players defend themselves against oncoming enemies by maneuvering a ship from left to right to dodge enemy projectiles and collect power-ups with an added bonus that their ship's weapon power and shield strength improves based on how they time their movement to the music.

Movement takes place on a configurable vertical grid with 5 columns & 9 rows with the player navigating to the left or right on the bottom row and enemies and their projectiles traveling along the grid starting from top and moving toward the player with their movement from position to position on the grid aligning to the beat.

### Primary Gameplay Loop
- Open game.
- Select "Start".
- Select a level.
- Play through the level.
	- If failure, display level end UI with "Game Over" message and options to retry the level or return to the level selection screen.
	- If success, display level end UI with "You Win" message and the same options as above.
		- If a new high-score is achieved for the level, ask the user to enter their name to save their score when they retry the level or return to the level selection screen.
			- Also provide an option to skip/cancel saving their high-score when leaving the level.
- If retry, restart the level.
- If return to level selection, return to the level selection screen.

### Secondary Loops
- Simple 3 row high-score table for each level that is viewed on the level selection screen. 
	- When a player completes a level and their score is better than a position on the high-score table of the level, they are asked for their name. Their name and score overwrites the row they have exceeded.
- Scoring
	- The score is updated when...
		- ...an enemy is defeated, add its scorePoints attribute value.
		- ...an enemy passes the player, subtract its scorePoints attribute value.
		- ...the player collects a power-up item, add its scorePoints attribute value.

### Data Models
- Player
	- baseHealth
		- Default is 100. Editable in editor.
	- currentHealth
		- Starts level with baseHealth value.
		- If currentHealth reaches 0 or below, the player has failed the level.
	- Weapon
		- Defines the Weapon that the player's ship uses.
		- Player weapons shoot projectiles from the player's ship toward the top of the screen.
	- sprite
	- area 2D
- Enemy
	- baseHealth
		- Default is 10. Editable in editor.
	- currentHealth
		- Enters level with baseHealth value.
		- If currentHealth reaches 0 or below, the enemy is destroyed.
	- scorePoints
		- Default is 50. Is added or subtracted from the player's level score.
	- Weapon
		- Defines the Weapon that the enemy uses.
		- Enemy weapons shoot projectiles from the enemy toward the bottom of the screen.
	- sprite
	- area 2D
- Power-Up
	- scorePoints
	- sprite
	- area 2D
- Weapon
	- baseAttackPower
		- Default is 10. Editable in editor.
	- attackFrequency
		- Every quarter-beat
		- Every half-beat
		- Every beat
		- Every 2nd beat
		- Every 3rd beat
		- Every 4th beat
	- lowPowerProjectile
		- If the player's last movement was outside the beat window:
			- The player's weapon will discharge this projectile which is half the attack power of the baseAttackPower value.
		- If the player's last movement was within the "super" beat window:
			- The enemy's weapon will discharge this projectile at half the attack power of the baseAttackPower.
	- regularPowerProjectile
		- If the player's last movement was within the beat window, but not within the "super" beat window:
			- The player & enemy weapons will discharge this projectile and deal the baseAttackPower.
	- superPowerProjectile
		- If the player's last movement was within the "super" beat window:
			- The player's weapon will discharge this projectile which is double the attack power of the baseAttackPower value.
		- If the player's last movement was outside the beat window:
			- The enemy's weapon will discharge this projectile at double the attack power of the baseAttackPower.
- Projectile
	- sprite
		- This is the sprite that will be used for the projectile.
	- area 2D

## Feedback Systems
- Visual cues
	- When a Projectile is discharged, it reaches the top or bottom row of the grid by the start of the next beat.
- Audio cues
- UI updates
	- A score is displayed in the level UI.
	- The player's health is displayed in the level UI as a health bar.

### Controls & Input Model
- Input devices & mapping
	- Keyboard
		- A & left arrow: Move left by one space.
		- D & right arrow: Move left by one space.
		- Esc & P: Opens the pause/level menu.
	- Mouse
		- Left mouse button to click on UI elements.
- Timing sensitivity (especially for rhythm games)
- Expected input frequency
	- Players will be tapping/hitting to move left and right in percussive movements rather than tap-and-hold.

## Non-Goals
- No procedural generation
- No online multiplayer
- No physics‑based puzzles
- No real‑time 3D rendering