extends Area3D

signal room_transition

func _ready():
	body_entered.connect(_on_body_entered)
	add_to_group("room_transitions")
	
	 
func _on_body_entered(body):
	if not body is Area3D:
		pass
	if body.name == "PlayerCharacter":
		room_transition.emit()
	
	#if body.current_pick_up != null:
	#	body.state = 0
	#	for child in body.current_pick_up.get_children():
	#		if child is CollisionShape3D:
	#			child.disabled = false
	#	body.current_pick_up = null
	
	body.global_position = $Marker3D.global_position
