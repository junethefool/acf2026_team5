@tool
extends Node3D

@export_category("Map Basics")
@export var grid_id: String = ""
@export var grid_size: Vector2i = Vector2i(50, 50)
@export var earth_scene: PackedScene
@export var earth_height_min: float = 0.0
@export var earth_height_max: float = 0.5

@export_category("Spring (grass) visual parameters")
@export var grass_scene: PackedScene
@export var randomize_grass_rotation: bool = true
@export var spring_offset_min: float = 0.0
@export var spring_offset_max: float = 1.0
@export var spring_scale_min: float = 0.8
@export var spring_scale_max: float = 1.2

@export_category("Winter (snow) visual parameters")
@export var snow_scene: PackedScene
@export var randomize_snow_rotation: bool = true
@export var winter_offset_min: float = 0.0
@export var winter_offset_max: float = 1.0
@export var winter_scale_min: float = 0.8
@export var winter_scale_max: float = 1.2

@export_category("Other parameters")
@export var tween_duration: float = 2.0
@export var noise_frequency: float = 0.08
@export var collision_y_offset: float = 0.0

@export_category("Editor Tools")
@export_tool_button("Randomize Snow") var _btn_randomize_snow = _randomize_snow
@export_tool_button("Randomize Grass") var _btn_randomize_grass = _randomize_grass
@export_tool_button("Regenerate Grid") var _btn_regenerate = _regenerate


var _earth_mm: MultiMesh
var _grass_mm: MultiMesh
var _snow_mm: MultiMesh

var _earth_heights: PackedFloat32Array
var _current_spring: PackedFloat32Array
var _target_spring: PackedFloat32Array
var _base_spring: PackedFloat32Array
var _current_winter: PackedFloat32Array
var _target_winter: PackedFloat32Array
var _base_winter: PackedFloat32Array
var _snow_rotations: PackedFloat32Array
var _grass_rotations: PackedFloat32Array

var _world_x: PackedFloat32Array
var _world_z: PackedFloat32Array

var _is_animating: bool = false
var _total_tiles: int = 0
var _gen_x: int = 0
var _gen_z: int = 0
var _snow_level_offset: float = 0.0
var _spring_level_offset: float = 0.0


func _ready() -> void:
	_clear_generated_children()
	_total_tiles = grid_size.x * grid_size.y

	if not earth_scene or not grass_scene or not snow_scene:
		return

	var earth_mesh := _extract_mesh(earth_scene)
	var grass_mesh := _extract_mesh(grass_scene)
	var snow_mesh := _extract_mesh(snow_scene)

	_setup_multimeshes(earth_mesh, grass_mesh, snow_mesh)
	_generate_grid()

	if not Engine.is_editor_hint():
		GameManager.register_grid(self)


func _exit_tree() -> void:
	if not Engine.is_editor_hint():
		GameManager.unregister_grid(self)


func _clear_generated_children() -> void:
	for child_name in ["EarthTiles", "GrassTiles", "SnowTiles"]:
		var existing := get_node_or_null(child_name)
		if existing:
			remove_child(existing)
			existing.free()


func _extract_mesh(scene: PackedScene) -> Mesh:
	var instance := scene.instantiate()
	var mesh := _find_mesh_recursive(instance)
	instance.queue_free()
	return mesh


func _find_mesh_recursive(node: Node) -> Mesh:
	if node is MeshInstance3D:
		return (node as MeshInstance3D).mesh
	for child in node.get_children():
		var result := _find_mesh_recursive(child)
		if result:
			return result
	return null


func _setup_multimeshes(earth_mesh: Mesh, grass_mesh: Mesh, snow_mesh: Mesh) -> void:
	_earth_mm = _create_multimesh(earth_mesh, "EarthTiles")
	_grass_mm = _create_multimesh(grass_mesh, "GrassTiles")
	_snow_mm = _create_multimesh(snow_mesh, "SnowTiles")


func _create_multimesh(mesh: Mesh, node_name: String) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = _total_tiles

	var mmi := MultiMeshInstance3D.new()
	mmi.name = node_name
	mmi.multimesh = mm
	add_child(mmi)

	return mm


func _generate_grid() -> void:
	_earth_heights = PackedFloat32Array()
	_earth_heights.resize(_total_tiles)
	_current_spring = PackedFloat32Array()
	_current_spring.resize(_total_tiles)
	_target_spring = PackedFloat32Array()
	_target_spring.resize(_total_tiles)
	_base_spring = PackedFloat32Array()
	_base_spring.resize(_total_tiles)
	_current_winter = PackedFloat32Array()
	_current_winter.resize(_total_tiles)
	_target_winter = PackedFloat32Array()
	_target_winter.resize(_total_tiles)
	_base_winter = PackedFloat32Array()
	_base_winter.resize(_total_tiles)
	_world_x = PackedFloat32Array()
	_world_x.resize(_total_tiles)
	_world_z = PackedFloat32Array()
	_world_z.resize(_total_tiles)
	_snow_rotations = PackedFloat32Array()
	_snow_rotations.resize(_total_tiles)
	_grass_rotations = PackedFloat32Array()
	_grass_rotations.resize(_total_tiles)

	var earth_noise := FastNoiseLite.new()
	earth_noise.seed = randi()
	earth_noise.frequency = 0.05

	var spring_noise := FastNoiseLite.new()
	spring_noise.seed = randi()
	spring_noise.frequency = noise_frequency

	var winter_noise := FastNoiseLite.new()
	winter_noise.seed = randi()
	winter_noise.frequency = noise_frequency

	_gen_x = grid_size.x
	_gen_z = grid_size.y

	var half_x := _gen_x / 2.0
	var half_z := _gen_z / 2.0

	for x in _gen_x:
		for z in _gen_z:
			var i := x * _gen_z + z
			var wx := x - half_x + 0.5
			var wz := z - half_z + 0.5
			_world_x[i] = wx
			_world_z[i] = wz

			var noise_val := earth_noise.get_noise_2d(float(x), float(z))
			_earth_heights[i] = remap(noise_val, -1.0, 1.0, earth_height_min, earth_height_max)

			var sv := remap(spring_noise.get_noise_2d(float(x), float(z)), -1.0, 1.0, 0.0, 1.0)
			var wv := remap(winter_noise.get_noise_2d(float(x), float(z)), -1.0, 1.0, 0.0, 1.0)

			_base_spring[i] = sv
			_current_spring[i] = sv
			_target_spring[i] = sv
			_base_winter[i] = wv
			_current_winter[i] = wv
			_target_winter[i] = wv

			_snow_rotations[i] = randf() * TAU if randomize_snow_rotation else 0.0
			_grass_rotations[i] = randf() * TAU if randomize_grass_rotation else 0.0

			_earth_mm.set_instance_transform(i, _compute_earth_transform(i))
			_grass_mm.set_instance_transform(i, _compute_overlay_transform(i, sv, spring_offset_min, spring_offset_max, spring_scale_min, spring_scale_max, _grass_rotations[i]))
			_snow_mm.set_instance_transform(i, _compute_overlay_transform(i, wv, winter_offset_min, winter_offset_max, winter_scale_min, winter_scale_max, _snow_rotations[i]))


func restore_state(spring_vals: PackedFloat32Array, winter_vals: PackedFloat32Array, snow_offset: float = 0.0, spring_offset: float = 0.0) -> void:
	_snow_level_offset = snow_offset
	_spring_level_offset = spring_offset
	for i in _total_tiles:
		_base_spring[i] = spring_vals[i]
		_base_winter[i] = winter_vals[i]
		var sv := clampf(spring_vals[i] + spring_offset, 0.0, 1.0)
		var wv := clampf(winter_vals[i] + snow_offset, 0.0, 1.0)
		_current_spring[i] = sv
		_target_spring[i] = sv
		_current_winter[i] = wv
		_target_winter[i] = wv
		_grass_mm.set_instance_transform(i, _compute_overlay_transform(i, sv, spring_offset_min, spring_offset_max, spring_scale_min, spring_scale_max, _grass_rotations[i]))
		_snow_mm.set_instance_transform(i, _compute_overlay_transform(i, wv, winter_offset_min, winter_offset_max, winter_scale_min, winter_scale_max, _snow_rotations[i]))


func _compute_earth_transform(i: int) -> Transform3D:
	return Transform3D(Basis.IDENTITY, Vector3(_world_x[i], _earth_heights[i], _world_z[i]))


func _compute_overlay_transform(i: int, value: float, off_min: float, off_max: float, sc_min: float, sc_max: float, rotation_y: float = 0.0) -> Transform3D:
	var s := lerpf(sc_min, sc_max, value)
	var y_offset := lerpf(off_min, off_max, value)
	var base := Basis().rotated(Vector3.UP, rotation_y).scaled(Vector3(s, s, s))
	var origin := Vector3(_world_x[i], _earth_heights[i] + y_offset, _world_z[i])
	return Transform3D(base, origin)


func _setup_collision() -> void:
	var static_body := StaticBody3D.new()
	static_body.name = "TerrainCollision"
	add_child(static_body)

	var col_shape := CollisionShape3D.new()
	static_body.add_child(col_shape)

	var collision_data := PackedFloat32Array()
	collision_data.resize(_total_tiles)
	for i in _total_tiles:
		collision_data[i] = _earth_heights[i] + collision_y_offset

	var hm_shape := HeightMapShape3D.new()
	hm_shape.map_width = grid_size.x
	hm_shape.map_depth = grid_size.y
	hm_shape.map_data = collision_data
	col_shape.shape = hm_shape

	static_body.position = Vector3(0.5, 0.0, 0.5)


# --- Runtime-only systems ---

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not _is_animating:
		return

	var speed := delta / tween_duration
	var still_animating := false

	for i in _total_tiles:
		var spring_changed := false
		var winter_changed := false

		if _current_spring[i] != _target_spring[i]:
			_current_spring[i] = move_toward(_current_spring[i], _target_spring[i], speed)
			spring_changed = true
			if _current_spring[i] != _target_spring[i]:
				still_animating = true

		if _current_winter[i] != _target_winter[i]:
			_current_winter[i] = move_toward(_current_winter[i], _target_winter[i], speed)
			winter_changed = true
			if _current_winter[i] != _target_winter[i]:
				still_animating = true

		if spring_changed:
			_grass_mm.set_instance_transform(i, _compute_overlay_transform(
				i, _current_spring[i],
				spring_offset_min, spring_offset_max,
				spring_scale_min, spring_scale_max,
				_grass_rotations[i]
			))
		if winter_changed:
			_snow_mm.set_instance_transform(i, _compute_overlay_transform(
				i, _current_winter[i],
				winter_offset_min, winter_offset_max,
				winter_scale_min, winter_scale_max,
				_snow_rotations[i]
			))

	_is_animating = still_animating


func set_spring_value(x: int, z: int, value: float) -> void:
	var i := x * _gen_z + z
	_target_spring[i] = clampf(value, 0.0, 1.0)
	if _target_spring[i] != _current_spring[i]:
		_is_animating = true


func set_winter_value(x: int, z: int, value: float) -> void:
	var i := x * _gen_z + z
	_target_winter[i] = clampf(value, 0.0, 1.0)
	if _target_winter[i] != _current_winter[i]:
		_is_animating = true


func set_snow_level(offset: float) -> void:
	_snow_level_offset = offset
	for i in _total_tiles:
		_target_winter[i] = clampf(_base_winter[i] + offset, 0.0, 1.0)
		if _target_winter[i] != _current_winter[i]:
			_is_animating = true


func set_spring_level(offset: float) -> void:
	_spring_level_offset = offset
	for i in _total_tiles:
		_target_spring[i] = clampf(_base_spring[i] + offset, 0.0, 1.0)
		if _target_spring[i] != _current_spring[i]:
			_is_animating = true


func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if event.is_action_pressed("randomize_tiles"):
		randomize_all()


# --- Editor button callbacks ---

func _randomize_snow() -> void:
	if _total_tiles == 0:
		return
	var noise := FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = noise_frequency
	for x in _gen_x:
		for z in _gen_z:
			var i := x * _gen_z + z
			var wv := remap(noise.get_noise_2d(float(x), float(z)), -1.0, 1.0, 0.0, 1.0)
			_base_winter[i] = wv
			_current_winter[i] = wv
			_target_winter[i] = wv
			_snow_mm.set_instance_transform(i, _compute_overlay_transform(
				i, wv,
				winter_offset_min, winter_offset_max,
				winter_scale_min, winter_scale_max,
				_snow_rotations[i]
			))


func _randomize_grass() -> void:
	if _total_tiles == 0:
		return
	var noise := FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = noise_frequency
	for x in _gen_x:
		for z in _gen_z:
			var i := x * _gen_z + z
			var sv := remap(noise.get_noise_2d(float(x), float(z)), -1.0, 1.0, 0.0, 1.0)
			_base_spring[i] = sv
			_current_spring[i] = sv
			_target_spring[i] = sv
			_grass_mm.set_instance_transform(i, _compute_overlay_transform(
				i, sv,
				spring_offset_min, spring_offset_max,
				spring_scale_min, spring_scale_max,
				_grass_rotations[i]
			))


func _regenerate() -> void:
	_clear_generated_children()
	_total_tiles = grid_size.x * grid_size.y
	if not earth_scene or not grass_scene or not snow_scene:
		return
	var earth_mesh := _extract_mesh(earth_scene)
	var grass_mesh := _extract_mesh(grass_scene)
	var snow_mesh := _extract_mesh(snow_scene)
	_setup_multimeshes(earth_mesh, grass_mesh, snow_mesh)
	_generate_grid()


func randomize_all() -> void:
	_randomize_snow()
	_randomize_grass()
	if not Engine.is_editor_hint():
		_is_animating = true
