extends CharacterBody3D

@export var movement_speed: float = 5.0
@export var camera_rotation_speed: float = 2.0

@export var camera_distance: float = 5.0
@export var camera_height: float = 5.0

@export var animated_sprite: AnimatedSprite3D



@export var camera: Camera3D

var _camera_yaw: float = 0.0


func _physics_process(delta: float) -> void:
	_camera_yaw -= Input.get_axis("cam_left", "cam_right") * camera_rotation_speed * delta

	if camera:
		camera.global_position = global_position + Vector3(
			sin(_camera_yaw) * camera_distance,
			camera_height,
			cos(_camera_yaw) * camera_distance
		)
		camera.look_at(global_position + Vector3.UP, Vector3.UP)

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := Vector3(input_dir.x, 0.0, input_dir.y).rotated(Vector3.UP, _camera_yaw)

	if not is_on_floor():
		velocity.y += get_gravity().y * delta

	velocity.x = direction.x * movement_speed
	velocity.z = direction.z * movement_speed
	move_and_slide()

	# --- Animation ---
	if animated_sprite:
		if input_dir.x < 0:
			animated_sprite.flip_h = true
		elif input_dir.x > 0:
			animated_sprite.flip_h = false
		if input_dir.length() > 0.1:
			animated_sprite.play("walk")
		else:
			animated_sprite.play("idle")
	
