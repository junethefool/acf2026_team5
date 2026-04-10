extends AnimatableBody3D

@onready var interactable: Interactable = $Interactable
@export var fiddle: AnimatableBody3D
@export var crow: AnimatableBody3D
@export var seelie: AnimatableBody3D
@export var unicorn: AnimatableBody3D
@export var player: CharacterBody3D
var gone = false

func _ready() -> void:
	interactable.Interact.connect(on_interact)
	Dialogic.signal_event.connect(on_dialogic_signal)
	for room_transition in get_tree().get_nodes_in_group("room_transitions"):
		room_transition.room_transition.connect(_on_room_transition)

func on_interact():
	print("you did it, dumbass")
	Dialogic.start("flower observation")
	
func on_dialogic_signal(message):
	if message == "give fiddle":
		for child in fiddle.get_children():
			if child is Sprite3D:
				child.visible = false
			if child is CollisionShape3D:
				child.disabled = true
		player.inventory.push_front(fiddle)
	elif message == "leaving":
		get_tree().get_first_node_in_group("fade").fade(0.5,0.5)
		var duration = 0.5
		var wait = 0.5
		await get_tree().create_timer(duration).timeout
		for child in get_children():
			if child is Sprite3D:
				child.visible = false
			if child is CollisionShape3D:
				child.disabled = true
		gone = true
		Dialogic.VAR.went_and_returned = 1
		await get_tree().create_timer(wait + duration).timeout
	elif message == "party":
		get_tree().get_first_node_in_group("fade").fade(0.5,0.5)
		var duration = 0.5
		var wait = 0.5
		await get_tree().create_timer(duration).timeout
		crow.global_position = $crow_position.global_position
		seelie.global_position = $seelie_position.global_position
		unicorn.global_position = $unicorn_position.global_position
		player.global_position = $player_position.global_position
		global_position = $faun_position.global_position
		await get_tree().create_timer(wait + duration).timeout
		Dialogic.start("faun")
		

func _on_room_transition():
	if gone == true:
		for child in get_children():
			if child is Sprite3D:
				child.visible = true
			if child is CollisionShape3D:
				child.disabled = false
		gone = false
