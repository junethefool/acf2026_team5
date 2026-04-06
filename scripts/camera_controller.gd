extends Node3D

@export var camera_distance: float = 10.0
@export var camera_height: float = 8.0


var _camera: Camera3D
var _player: Node3D

func _ready():
	_camera = Camera3D.new()
	_camera.fov = 30.0
	_camera.current = true
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.043, 0.039, 0.064, 1)
	_camera.environment = env
	add_child(_camera)
	call_deferred("_find_player")

func _find_player():
	_player = get_tree().get_first_node_in_group("player")

func _process(_delta: float) -> void:
	if not _player:
		_find_player()
		if not _player:
			return


	_camera.global_position = _player.global_position + Vector3(
		0,
		camera_height,
		camera_distance
	)
	_camera.look_at(_player.global_position + Vector3.UP, Vector3.UP)
	_camera.rotation.z = 0.0
