extends CharacterBody3D

@export var movement_speed: float = 5.0

@export var animated_sprite: AnimatedSprite3D

enum {neutral,pick_up,hold,place_down,inventory_stationary, inventory_rotating,wait}
var state = neutral


var last_direction: Vector3

var current_pick_up: Node

var inventory: Array
@export var inventory_names: PackedStringArray = []

func _ready() -> void:
	Dialogic.timeline_started.connect(_on_timeline_start)
	Dialogic.timeline_ended.connect(_on_timeline_end)
	call_deferred("_rebuild_inventory")

func _on_timeline_start():
	state = wait
func _on_timeline_end():
	state = neutral
	

func _rebuild_inventory():
	if inventory_names.is_empty():
		return
	var game_state = get_parent()
	for item_name in inventory_names:
		var node = game_state.find_child(item_name, true, false)
		if node:
			inventory.append(node)
			for child in node.get_children():
				if child is Sprite3D:
					child.visible = false
				if child is CollisionShape3D:
					child.disabled = true
	state = neutral
	inventory_names = PackedStringArray()

func prepare_save():
	inventory_names = PackedStringArray()
	for item in inventory:
		inventory_names.append(item.name)


func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := Vector3(input_dir.x, 0.0, input_dir.y)
	

	match state:
		neutral:
			var check_vector = Vector3(input_dir.x, 0.0, input_dir.y)
			if check_vector.length() > 0.5:
				last_direction = Vector3(input_dir.x, 0.0, input_dir.y)
			
			if not is_on_floor():
				velocity.y += get_gravity().y * delta

			velocity.x = direction.x * movement_speed
			velocity.z = direction.z * movement_speed
			move_and_slide()
			
			#doing this every frame to later add a UI element indicating the current target
			var object_list = $PlayerRange.get_overlapping_bodies()
			object_list = object_list.filter(func (object): return object.get("pickupable") == true)
			object_list.sort_custom(func(a,b): return global_position.distance_to(a.global_position) < global_position.distance_to(b.global_position))
			var pick_up_target = Node
			if !object_list.is_empty():
				pick_up_target = object_list[0]
			else:
				pick_up_target = null
			if Input.is_action_just_pressed("pick_up") and pick_up_target != null:
				current_pick_up = pick_up_target
				for child in current_pick_up.get_children():
					if child is CollisionShape3D:
						child.disabled = true
				await get_tree().physics_frame
				await get_tree().physics_frame
				state = pick_up
				
			if !Input.is_action_just_pressed("pick_up") and Input.is_action_just_pressed("inventory") and !inventory.is_empty():
				for item in inventory:
					for child in item.get_children():
						if child is Sprite3D:
							child.visible = true
				state = inventory_stationary
			
		pick_up:
			current_pick_up.global_position = current_pick_up.global_position.lerp(self.global_position,9*delta)
			var height_vector: Vector3 = self.global_position - current_pick_up.global_position
			height_vector.x = current_pick_up.global_position.x
			height_vector.z = current_pick_up.global_position.z
			height_vector.y = movement_speed * 0.35
			current_pick_up.global_position = current_pick_up.global_position.lerp(height_vector,15*delta)
			
			if abs(global_position.y - current_pick_up.global_position.y) > movement_speed * 0.25- 0.1 and global_position.distance_to(current_pick_up.global_position) <  movement_speed * 0.25 + 1.5:
				state = hold

				
		hold:
			var check_vector = Vector3(input_dir.x, 0.0, input_dir.y)
			if check_vector.length() > 0.5:
				last_direction = Vector3(input_dir.x, 0.0, input_dir.y)
			
			if not is_on_floor():
				velocity.y += get_gravity().y * delta

			velocity.x = direction.x * movement_speed
			velocity.z = direction.z * movement_speed
			move_and_slide()
			
			current_pick_up.global_position = global_position
			current_pick_up.global_position.y += movement_speed * 0.25
			
			if Input.is_action_just_pressed("pick_up") and !Input.is_action_just_pressed("inventory"):
				state = place_down
				
			if !Input.is_action_just_pressed("pick_up") and Input.is_action_just_pressed("inventory"):
				inventory.push_front(current_pick_up)
				for child in current_pick_up.get_children():
					if child is Sprite3D:
						child.visible = false
				state = neutral
				print(inventory[0])
		place_down:
			var move_vector: Vector3 = Vector3.ZERO
			move_vector.x = last_direction.x*2 + global_position.x
			move_vector.z = last_direction.z*2 + global_position.z
			move_vector.y = current_pick_up.global_position.y
			current_pick_up.global_position = current_pick_up.global_position.lerp(move_vector,5*delta)
			var height_vector: Vector3 = Vector3.ZERO
			height_vector.x = current_pick_up.global_position.x
			height_vector.z = current_pick_up.global_position.z
			height_vector.y = 0
			current_pick_up.global_position = current_pick_up.global_position.lerp(height_vector,9*delta)
			
			if abs(0 - current_pick_up.global_position.y) < 0.1:
				current_pick_up.global_position.y = 0
				state = neutral
				for child in current_pick_up.get_children():
					if child is CollisionShape3D:
						child.disabled = false
				current_pick_up = null
		
		inventory_stationary:
			
			inventory[0].global_position = global_position
			inventory[0].global_position.y = movement_speed * 0.25
			
			var pivot = Vector3(global_position.x,global_position.y + movement_speed * 0.25,global_position.z - movement_speed * 0.1)
			var offset =  inventory[0].global_position - pivot 
			for item in inventory:
				var new_offset = offset.rotated(Vector3.UP, 2 * PI / inventory.size() * inventory.find(item))
				item.global_position = new_offset + pivot
			
			if Input.is_action_just_pressed("move_right"):
				inventory.push_front(inventory.pop_back())
			if Input.is_action_just_pressed("move_left"):
				inventory.append(inventory.pop_front())
			if Input.is_action_just_pressed("pick_up") and !Input.is_action_just_pressed("inventory"):
				current_pick_up = inventory.pop_front()
				for item in inventory:
					for child in item.get_children():
						if child is Sprite3D:
							child.visible = false
				state = hold
				
			if !Input.is_action_just_pressed("pick_up") and Input.is_action_just_pressed("inventory"):
				for item in inventory:
					for child in item.get_children():
						if child is Sprite3D:
							child.visible = false
				state = neutral
			
	# --- Animation ---
	if animated_sprite:
		if state == 0 or state == 2:
			if abs(input_dir.y) > 0.1 or abs(input_dir.x) > 0.1:
				if input_dir.y < 0:
					if input_dir.x < -0.3:
						animated_sprite.play("player_left")
					elif input_dir.x > 0.3:
						animated_sprite.play("player_right")
					else:
						animated_sprite.play("player_back")
				else:
					if input_dir.x < -0.3:
						animated_sprite.play("player_left")
					elif input_dir.x > 0.3:
						animated_sprite.play("player_right")
					else:
						animated_sprite.play("player_front")
			
#		if input_dir.length() > 0.1:
#			animated_sprite.play("walk")
#		else:
#			animated_sprite.play("idle")
#	
