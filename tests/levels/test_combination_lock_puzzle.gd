## Tests for the combination lock puzzle: solving, the reward and saving.

extends GutTest

const DOOR_SCENE: PackedScene = preload("res://scenes/levels/door.tscn")
const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")

var _puzzle: CombinationLockPuzzle


func before_each() -> void:
	_puzzle = CombinationLockPuzzle.new()
	_puzzle.code = "0447"
	add_child_autofree(_puzzle)


func after_each() -> void:
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	SaveSystem.reset()


func _make_player() -> Player:
	var player := PLAYER_SCENE.instantiate() as Player
	add_child_autofree(player)
	return player


func test_starts_unsolved_as_an_interactable() -> void:
	assert_false(_puzzle.is_solved)
	assert_true(_puzzle.is_in_group(Interactable.GROUP))
	assert_eq(_puzzle.wheel_count(), 4)
	assert_eq(_puzzle.get_prompt(), "Open")


func test_interact_opens_the_screen_and_answers_nothing() -> void:
	watch_signals(_puzzle)
	assert_eq(_puzzle.interact(_make_player()), "")
	assert_signal_emitted(_puzzle, "interacted")


func test_matches_the_code_digit_by_digit() -> void:
	assert_true(_puzzle.matches([0, 4, 4, 7]))
	assert_false(_puzzle.matches([0, 4, 4, 8]))
	assert_false(_puzzle.matches([0, 4, 7]))


func test_solving_marks_it_solved_and_emits() -> void:
	watch_signals(_puzzle)
	var player: Player = _make_player()
	_puzzle.solve(player)
	assert_true(_puzzle.is_solved)
	assert_signal_emitted(_puzzle, "solved")


func test_solving_grants_the_reward_item() -> void:
	var key := ItemData.new()
	key.id = &"key_basement"
	key.display_name = "Basement key"
	_puzzle.reward_item = key
	var player: Player = _make_player()
	assert_eq(_puzzle.solve(player), "The lock clicks open. Found Basement key.")
	assert_true(player.inventory.has(key))


func test_solving_unlocks_the_reward_door() -> void:
	var door := DOOR_SCENE.instantiate() as Door
	door.is_locked = true
	add_child_autofree(door)
	_puzzle.reward_door = door
	_puzzle.solve(_make_player())
	assert_false(door.is_locked)


func test_once_solved_interact_answers_already_solved() -> void:
	_puzzle.already_solved_message = "The cabinet stands open."
	var player: Player = _make_player()
	_puzzle.solve(player)
	assert_eq(_puzzle.interact(player), "The cabinet stands open.")


func test_solving_again_grants_nothing_twice() -> void:
	var key := ItemData.new()
	key.id = &"key_basement"
	key.display_name = "Basement key"
	_puzzle.reward_item = key
	var player: Player = _make_player()
	_puzzle.solve(player)
	_puzzle.solve(player)
	assert_eq(player.inventory.count(key), 1)


func test_solving_records_the_state() -> void:
	_puzzle.puzzle_id = &"puzzle_key_cabinet"
	_puzzle.solve(_make_player())
	assert_eq(SaveSystem.world.get_state(&"puzzle_key_cabinet"), {"is_solved": true})


func test_loading_a_solved_state_does_not_grant_the_reward_again() -> void:
	var key := ItemData.new()
	key.id = &"key_basement"
	_puzzle.reward_item = key
	_puzzle.load_state({"is_solved": true})
	assert_true(_puzzle.is_solved)
	var player: Player = _make_player()
	assert_false(player.inventory.has(key))


func test_the_id_defaults_to_the_path_in_its_level() -> void:
	var level := Node3D.new()
	var puzzle := CombinationLockPuzzle.new()
	puzzle.name = "KeyCabinet"
	level.add_child(puzzle)
	puzzle.owner = level
	add_child_autofree(level)
	assert_eq(puzzle.puzzle_id, &"KeyCabinet")
