extends Node3D

@export_category("Map Basics")
@export var grid_size: Vector2i = Vector2i(50, 50)
@export var earth_scene: PackedScene
@export var earth_height_min: float = 0.0
@export var earth_height_max: float = 0.5

@export_category("Spring (grass) visual parameters")
@export var snow_scene: PackedScene
@export var randomize_grass_rotation: bool = true
@export var spring_offset_min: float = 0.0
@export var spring_offset_max: float = 1.0
@export var spring_scale_min: float = 0.8
@export var spring_scale_max: float = 1.2

@export_category("Winter (snow) visual parameters")
@export var grass_scene: PackedScene
@export var randomize_snow_rotation: bool = true
@export var winter_offset_min: float = 0.0
@export var winter_offset_max: float = 1.0
@export var winter_scale_min: float = 0.8
@export var winter_scale_max: float = 1.2


@export_category("other parameters")
@export var tween_duration: float = 2.0
@export var noise_frequency: float = 0.08
@export var collision_y_offset: float = 0.0


var _earth_mm: MultiMesh
var _grass_mm: MultiMesh
var _snow_mm: MultiMesh

var _earth_heights: PackedFloat32Array
var _current_spring: PackedFloat32Array
var _target_spring: PackedFloat32Array
var _current_winter: PackedFloat32Array
var _target_winter: PackedFloat32Array
var _snow_rotations: PackedFloat32Array
var _grass_rotations: PackedFloat32Array

var _world_x: PackedFloat32Array
var _world_z: PackedFloat32Array

var _is_animating: bool = false
var _total_tiles: int = 0


func _ready() -> void:
	_total_tiles = grid_size.x * grid_size.y

	var earth_mesh := _extract_mesh(earth_scene)
	var grass_mesh := _extract_mesh(grass_scene)
	var snow_mesh := _extract_mesh(snow_scene)

	_setup_multimeshes(earth_mesh, grass_mesh, snow_mesh)
	_generate_grid()
	_setup_collision()


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
	_current_winter = PackedFloat32Array()
	_current_winter.resize(_total_tiles)
	_target_winter = PackedFloat32Array()
	_target_winter.resize(_total_tiles)
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

	var half_x := grid_size.x / 2.0
	var half_z := grid_size.y / 2.0

	for x in grid_size.x:
		for z in grid_size.y:
			var i := x * grid_size.y + z
			var wx := x - half_x + 0.5
			var wz := z - half_z + 0.5
			_world_x[i] = wx
			_world_z[i] = wz


			var noise_val := earth_noise.get_noise_2d(float(x), float(z))
			_earth_heights[i] = remap(noise_val, -1.0, 1.0, earth_height_min, earth_height_max)


			_current_spring[i] = 0.0
			_target_spring[i] = 0.0
			_current_winter[i] = 1.0
			_target_winter[i] = 1.0


			_snow_rotations[i] = randf() * TAU if randomize_snow_rotation else 0.0
			_grass_rotations[i] = randf() * TAU if randomize_grass_rotation else 0.0


			_earth_mm.set_instance_transform(i, _compute_earth_transform(i))
			_grass_mm.set_instance_transform(i, _compute_overlay_transform(i, 0.0, spring_offset_min, spring_offset_max, spring_scale_min, spring_scale_max, 0.0))
			_snow_mm.set_instance_transform(i, _compute_overlay_transform(i, 1.0, winter_offset_min, winter_offset_max, winter_scale_min, winter_scale_max, _snow_rotations[i]))


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


func _process(delta: float) -> void:
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
	var i := x * grid_size.y + z
	_target_spring[i] = clampf(value, 0.0, 1.0)
	if _target_spring[i] != _current_spring[i]:
		_is_animating = true


func set_winter_value(x: int, z: int, value: float) -> void:
	var i := x * grid_size.y + z
	_target_winter[i] = clampf(value, 0.0, 1.0)
	if _target_winter[i] != _current_winter[i]:
		_is_animating = true


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("randomize_tiles"):
		randomize_all()


func randomize_all() -> void:
	var spring_noise := FastNoiseLite.new()
	spring_noise.seed = randi()
	spring_noise.frequency = noise_frequency

	var winter_noise := FastNoiseLite.new()
	winter_noise.seed = randi()
	winter_noise.frequency = noise_frequency

	for x in grid_size.x:
		for z in grid_size.y:
			var sv := remap(spring_noise.get_noise_2d(float(x), float(z)), -1.0, 1.0, 0.0, 1.0)
			var wv := remap(winter_noise.get_noise_2d(float(x), float(z)), -1.0, 1.0, 0.0, 1.0)
			set_spring_value(x, z, sv)
			set_winter_value(x, z, wv)
