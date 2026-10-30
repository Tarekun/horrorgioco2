## Tests for the scarcity resource: the default values, swapping presets, and
## pickups and enemies reading from it.

extends GutTest

const ENEMY_SCENE: PackedScene = preload("res://scenes/enemies/enemy.tscn")
const ROUNDS: ItemData = preload("res://assets/data/items/pistol_ammo.tres")
const SHELLS: ItemData = preload("res://assets/data/items/shotgun_shells.tres")
const DRINK: ItemData = preload("res://assets/data/items/health_drink.tres")
const PIPE: ItemData = preload("res://assets/data/items/steel_pipe.tres")


func after_each() -> void:
	Scarcity.use(null)


func test_the_game_uses_the_default_resource() -> void:
	assert_eq(Scarcity.current().resource_path, Scarcity.DEFAULT_PATH)


func test_the_default_has_the_spec_values() -> void:
	var scarcity: Scarcity = Scarcity.current()
	assert_eq(scarcity.pickup_amount(ROUNDS), 8)
	assert_eq(scarcity.pickup_amount(SHELLS), 4)
	assert_eq(scarcity.pickup_amount(DRINK), 1)
	assert_eq(scarcity.enemy_max_health, 100.0)
	assert_eq(scarcity.enemy_damage_min, 15.0)
	assert_eq(scarcity.enemy_damage_max, 25.0)
	assert_eq(scarcity.hit_chance_min, 0.05)
	assert_eq(scarcity.hit_chance_max, 0.95)


func test_every_listed_pickup_is_a_real_item() -> void:
	for id: StringName in Scarcity.current().pickup_amounts:
		assert_not_null(ItemCatalog.find(id), "%s is not an item" % id)


func test_unlisted_items_come_one_at_a_time() -> void:
	assert_eq(Scarcity.current().pickup_amount(PIPE), 1)
	assert_eq(Scarcity.current().pickup_amount(null), 0)


func test_use_swaps_the_resource_and_null_restores_the_default() -> void:
	var preset := Scarcity.new()
	Scarcity.use(preset)
	assert_eq(Scarcity.current(), preset)
	Scarcity.use(null)
	assert_eq(Scarcity.current().resource_path, Scarcity.DEFAULT_PATH)


func test_enemy_damage_rolls_within_the_range() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var scarcity: Scarcity = Scarcity.current()
	for i: int in 100:
		assert_between(scarcity.roll_enemy_damage(rng), 15.0, 25.0)


func test_the_hit_chance_is_clamped() -> void:
	var scarcity: Scarcity = Scarcity.current()
	assert_eq(scarcity.clamp_hit_chance(1.2), 0.95)
	assert_eq(scarcity.clamp_hit_chance(0.0), 0.05)
	assert_eq(scarcity.clamp_hit_chance(0.5), 0.5)


func test_enemies_take_their_health_from_it() -> void:
	var tough := Scarcity.new()
	tough.enemy_max_health = 150.0
	Scarcity.use(tough)
	var enemy := ENEMY_SCENE.instantiate() as Enemy
	add_child_autofree(enemy)
	assert_eq(enemy.health_component.max_health, 150.0)
	assert_eq(enemy.health_component.current_health, 150.0)


func test_enemies_take_their_damage_from_it() -> void:
	var fixed := Scarcity.new()
	fixed.enemy_damage_min = 40.0
	fixed.enemy_damage_max = 40.0
	Scarcity.use(fixed)
	var enemy := ENEMY_SCENE.instantiate() as Enemy
	add_child_autofree(enemy)
	enemy._start_attack()
	assert_eq(enemy.attack_hitbox.damage, 40.0)
