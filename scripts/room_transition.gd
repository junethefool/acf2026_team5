extends Area3D

signal room_transition

func _ready():
	body_entered.connect(_on_body_entered)
	add_to_group("room_transitions")
	
	 
func _on_body_entered(body: CharacterBody3D):
	
	if body.name == "PlayerCharacter":
		room_transition.emit()
	
	#if body.current_pick_up != null:
	#	body.state = 0
	#	for child in body.current_pick_up.get_children():
	#		if child is CollisionShape3D:
	#			child.disabled = false
	#	body.current_pick_up = null
	get_tree().get_first_node_in_group("fade").fade(2,3)
	await get_tree().create_timer(3)
	body.global_position = $Marker3D.global_position
