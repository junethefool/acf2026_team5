extends Area3D

signal room_transition

func _ready():
	body_entered.connect(_on_body_entered)
	add_to_group("room_transitions")
	
	 
func _on_body_entered(body):
	if body.name == "PlayerCharacter":
		room_transition.emit()
		var statesave = body.state
		body.state = 6
		var fade = get_tree().get_first_node_in_group("fade")
		var duration = 0.5
		var wait = 0.5
		fade.fade(duration,wait)
		await get_tree().create_timer(duration).timeout
		body.global_position = $Marker3D.global_position
		await get_tree().create_timer(wait + duration).timeout
		body.state = statesave
	#if body.current_pick_up != null:
	#	body.state = 0
	#	for child in body.current_pick_up.get_children():
	#		if child is CollisionShape3D:
	#			child.disabled = false
	#	body.current_pick_up = null
	
	
