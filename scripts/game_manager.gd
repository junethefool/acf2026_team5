extends Node

const SAVE_PATH = "user://savegame.scn"
const TILE_SAVE_PATH = "user://tilegrid.dat"

var is_loading: bool = false
var player: CharacterBody3D

var _tile_grids: Dictionary = {}
var _snow_level: float = 0.0
var _spring_level: float = 0.0


func register_grid(grid: Node) -> void:
	if grid.grid_id.is_empty():
		push_warning("GameManager: TileGrid has no grid_id set, skipping registration")
		return
	if _tile_grids.has(grid.grid_id):
		push_warning("GameManager: Duplicate grid_id '%s' — overwriting" % grid.grid_id)
	_tile_grids[grid.grid_id] = grid


func unregister_grid(grid: Node) -> void:
	if grid.grid_id.is_empty():
		return
	_tile_grids.erase(grid.grid_id)


func get_grid(grid_id: String) -> Node:
	return _tile_grids.get(grid_id)


func set_grid_snow(grid_id: String, value: float) -> void:
	var grid = _tile_grids.get(grid_id)
	if not grid:
		push_warning("GameManager: No grid found with id '%s'" % grid_id)
		return
	grid.set_snow_level(value)


func adjust_all_grids_snow(delta: float) -> void:
	_snow_level = clampf(_snow_level + delta, -1.0, 1.0)
	for grid in _tile_grids.values():
		grid.set_snow_level(_snow_level)


func adjust_all_grids_spring(delta: float) -> void:
	_spring_level = clampf(_spring_level + delta, -1.0, 1.0)
	for grid in _tile_grids.values():
		grid.set_spring_level(_spring_level)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("snow_level_add"):
		adjust_all_grids_snow(0.2)
	elif event.is_action_pressed("snow_level_subtract"):
		adjust_all_grids_snow(-0.2)


func set_grid_spring(grid_id: String, value: float) -> void:
	var grid = _tile_grids.get(grid_id)
	if not grid:
		push_warning("GameManager: No grid found with id '%s'" % grid_id)
		return
	grid.set_spring_level(value)

func adjust_grid_snow(grid_id: String, delta: float) -> void:
	var grid = _tile_grids.get(grid_id)
	if not grid:
		push_warning("GameManager: No grid found with id '%s'" % grid_id)
		return
	grid.set_snow_level(grid.snow_level + delta)

func adjust_grid_spring(grid_id: String, delta: float) -> void:
	var grid = _tile_grids.get(grid_id)
	if not grid:
		push_warning("GameManager: No grid found with id '%s'" % grid_id)
		return
	grid.set_spring_level(grid.spring_level + delta)

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)
func new_game():
	is_loading = false
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/root_scene.tscn")

func load_game():
	if not has_save():
		return
	is_loading = true
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/root_scene.tscn")

func go_to_main_menu():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func save_game():
	var game_state = get_tree().root.find_child("GameState", true, false)
	if not game_state:
		push_error("GameManager: GameState node not found")
		return false

	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("prepare_save"):
		player.prepare_save()

	# PackedScene.pack() only saves nodes whose owner == root being packed.
	# Since these nodes were placed in the editor, their owner is TestMap, not GameState.
	# We must reassign ownership before packing.
	_set_owner_recursive(game_state, game_state)

	var packed = PackedScene.new()
	var result = packed.pack(game_state)
	if result != OK:
		push_error("GameManager: Failed to pack GameState: " + str(result))
		return false

	result = ResourceSaver.save(packed, SAVE_PATH)
	if result != OK:
		push_error("GameManager: Failed to save to disk: " + str(result))
		return false

	print("GameManager: Game saved to " + SAVE_PATH)
	_save_tile_state()
	return true

func _save_tile_state() -> void:
	if _tile_grids.is_empty():
		return
	var data: Dictionary = {}
	for grid_id in _tile_grids:
		var tg = _tile_grids[grid_id]
		data[grid_id] = {
			"spring": tg._base_spring,
			"winter": tg._base_winter,
			"snow_offset": tg._snow_level_offset,
			"spring_offset": tg._spring_level_offset,
		}
	var file := FileAccess.open(TILE_SAVE_PATH, FileAccess.WRITE)
	file.store_var(data)
	file.close()

func _set_owner_recursive(node: Node, new_owner: Node):
	for child in node.get_children():
		child.owner = new_owner
		_set_owner_recursive(child, new_owner)

func apply_load(test_map: Node):
	if not is_loading:
		return

	var old_state = test_map.find_child("GameState", false, false)
	if old_state:
		test_map.remove_child(old_state)
		old_state.queue_free()

	var saved = ResourceLoader.load(SAVE_PATH)
	if not saved:
		push_error("GameManager: Failed to load save file")
		is_loading = false
		return

	var loaded = saved.instantiate()
	loaded.name = "GameState"
	test_map.add_child(loaded)

	is_loading = false
	print("GameManager: Game loaded from " + SAVE_PATH)
	_apply_tile_state(test_map)

func _apply_tile_state(test_map: Node) -> void:
	if not FileAccess.file_exists(TILE_SAVE_PATH):
		return
	var file := FileAccess.open(TILE_SAVE_PATH, FileAccess.READ)
	var data = file.get_var()
	file.close()
	if data is Dictionary:
		for grid_id in data:
			var grid = _tile_grids.get(grid_id)
			if not grid:
				push_warning("GameManager: Saved grid_id '%s' not found in scene" % grid_id)
				continue
			var entry: Dictionary = data[grid_id]
			grid.restore_state(
				entry["spring"],
				entry["winter"],
				entry.get("snow_offset", 0.0),
				entry.get("spring_offset", 0.0),
			)
