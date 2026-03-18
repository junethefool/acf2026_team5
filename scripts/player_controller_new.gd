extends CharacterBody3D

@export var movement_speed: float = 5.0
@export var camera_rotation_speed: float = 2.0

@export var camera_distance: float = 5.0
@export var camera_height: float = 5.0

@export var animated_sprite: AnimatedSprite3D

@export var camera: Camera3D

var _camera_yaw: float = 0.0

enum {neutral,pick_up,hold,place_down}
var state = neutral


var last_direction: Vector3

var current_pick_up: Node

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
	last_direction = direction

	match state:
		neutral:
			
			if not is_on_floor():
				velocity.y += get_gravity().y * delta

			velocity.x = direction.x * movement_speed
			velocity.z = direction.z * movement_speed
			move_and_slide()
			
			#doing this every frame to later add a UI element indicating the current target
			var object_list = $Area3D.get_overlapping_bodies()
			object_list = object_list.filter(func (object): return object.get("pickupable") == true)
			object_list.sort_custom(func(a,b): return global_position.distance_to(a.global_position) < global_position.distance_to(b.global_position))
			var pick_up_target = Node
			if !object_list.is_empty():
				pick_up_target = object_list[0]
			else:
				pick_up_target = null
			if Input.is_action_pressed("pick_up") and pick_up_target != null:
				state = pick_up
				current_pick_up = pick_up_target
		pick_up:
			current_pick_up.global_position = current_pick_up.global_position.lerp(self.global_position,6*delta)
			var height_vector: Vector3 = self.global_position - current_pick_up.global_position
			height_vector.x = current_pick_up.global_position.x
			height_vector.z = current_pick_up.global_position.z
			height_vector.y = movement_speed * 0.4
			current_pick_up.global_position = current_pick_up.global_position.lerp(height_vector,15*delta)
			
			
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
	
