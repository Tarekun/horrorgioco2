## Physics layer bit masks for combat, matching `layer_names/3d_physics/*` in
## project.godot. Use these instead of magic numbers.

class_name CombatLayers
extends RefCounted

const WORLD: int = 1 << 0
const PLAYER: int = 1 << 1
const ENEMY: int = 1 << 2
const PLAYER_HITBOX: int = 1 << 3
const ENEMY_HITBOX: int = 1 << 4
const PLAYER_HURTBOX: int = 1 << 5
const ENEMY_HURTBOX: int = 1 << 6
