extends AnimatableBody3D

var pickupable = true
var spawn: Vector3
var locked = false
func _ready():
	call_deferred("_ready2")
	print(name)
func _ready2():
	spawn = global_position
	for room_transition in get_tree().get_nodes_in_group("room_transitions"):
		room_transition.room_transition.connect(_on_room_transition)
		
func _on_room_transition():
	if $CollisionShape3D.disabled == false and locked != true:
		global_position = spawn
