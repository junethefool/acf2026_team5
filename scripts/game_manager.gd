extends Node

const SAVE_PATH = "user://savegame.scn"
const TILE_SAVE_PATH = "user://tilegrid.dat"

var is_loading: bool = false
var player: CharacterBody3D

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
	var tg = get_tree().root.find_child("TileGrid", true, false)
	if not tg:
		return
	var file := FileAccess.open(TILE_SAVE_PATH, FileAccess.WRITE)
	file.store_var(tg._current_spring)
	file.store_var(tg._current_winter)
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
	var tg = test_map.find_child("TileGrid", true, false)
	if not tg:
		return
	var file := FileAccess.open(TILE_SAVE_PATH, FileAccess.READ)
	var spring_vals: PackedFloat32Array = file.get_var()
	var winter_vals: PackedFloat32Array = file.get_var()
	file.close()
	tg.restore_state(spring_vals, winter_vals)
