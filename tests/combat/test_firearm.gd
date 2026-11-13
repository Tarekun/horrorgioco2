## Tests for the Firearm resource: the defaults are the pistol of the Weapon
## stats table of the gameplay spec, and apply_to() copies the chance values
## into a HitChance so the same rule serves every firearm.

extends GutTest


func test_defaults_are_the_pistol_of_the_spec_table() -> void:
	var firearm := Firearm.new()
	assert_eq(firearm.display_name, "Pistol")
	assert_eq(firearm.damage, 20.0)
	assert_eq(firearm.near_chance, 0.90)
	assert_eq(firearm.near_distance, 4.0)
	assert_eq(firearm.far_chance, 0.35)
	assert_eq(firearm.far_distance, 20.0)
	assert_eq(firearm.max_range, 25.0)
	assert_eq(firearm.steady_min, 0.75)
	assert_eq(firearm.steady_time, 0.8)
	assert_eq(firearm.recoil, 0.15)
	assert_eq(firearm.shot_interval, 0.35)
	assert_eq(firearm.magazine_size, 10)
	assert_eq(firearm.reload_time, 1.4)
	assert_eq(firearm.noise_radius, 25.0)
	assert_null(firearm.ammo_item, "a bare Firearm carries no ammo; the resource sets it")


func test_apply_to_copies_the_chance_values_into_the_hit_chance() -> void:
	var firearm := Firearm.new()
	firearm.near_chance = 0.5
	firearm.near_distance = 3.0
	firearm.far_chance = 0.2
	firearm.far_distance = 12.0
	firearm.max_range = 15.0
	firearm.steady_min = 0.8
	firearm.steady_time = 0.6
	firearm.recoil = 0.3
	var hit_chance := HitChance.new(RandomNumberGenerator.new())
	firearm.apply_to(hit_chance)
	assert_eq(hit_chance.near_chance, 0.5)
	assert_eq(hit_chance.near_distance, 3.0)
	assert_eq(hit_chance.far_chance, 0.2)
	assert_eq(hit_chance.far_distance, 12.0)
	assert_eq(hit_chance.max_range, 15.0)
	assert_eq(hit_chance.steady_min, 0.8)
	assert_eq(hit_chance.steady_time, 0.6)
	assert_eq(hit_chance.recoil, 0.3)


func test_the_pistol_resource_in_the_data_folder_is_the_pistol() -> void:
	var firearm := load("res://assets/data/weapons/pistol.tres") as Firearm
	assert_true(firearm != null, "the pistol resource must load as a Firearm")
	if firearm == null:
		return
	assert_eq(firearm.display_name, "Pistol")
	assert_eq(firearm.damage, 20.0)
	assert_eq(firearm.max_range, 25.0)
	assert_eq(firearm.magazine_size, 10)
	assert_eq(firearm.reload_time, 1.4)
	assert_eq(firearm.noise_radius, 25.0)
	assert_true(firearm.ammo_item != null)
	if firearm.ammo_item != null:
		assert_eq(firearm.ammo_item.id, &"pistol_ammo")
