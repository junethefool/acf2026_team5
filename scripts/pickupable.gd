extends AnimatableBody3D

var pickupable = true
@export var spawn: Vector3 = Vector3.ZERO
@export var locked: bool = false
@export_multiline var description: String
func _ready():
	call_deferred("_ready2")
	print(name)
func _ready2():
	if spawn == Vector3.ZERO:
		spawn = global_position
	for room_transition in get_tree().get_nodes_in_group("room_transitions"):
		room_transition.room_transition.connect(_on_room_transition)
		
func _on_room_transition():
	if $CollisionShape3D.disabled == false and locked != true:
		global_position = spawn
