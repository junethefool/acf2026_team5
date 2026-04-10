extends AnimatableBody3D

@onready var interactable: Interactable = $Interactable
@export var crow: AnimatableBody3D
@export var berries: AnimatableBody3D

func _ready() -> void:
	interactable.Interact.connect(on_interact)
	Dialogic.signal_event.connect(on_dialogic_signal)

func on_interact():
	print("you did it, dumbass")
	Dialogic.start("seelie")
	
func on_dialogic_signal(message):
	if message == "crow":
		get_tree().get_first_node_in_group("fade").fade(0.5,0.5)
		var duration = 0.5
		var wait = 0.5
		await get_tree().create_timer(duration).timeout
		crow.global_position = $next_to_seelie.global_position
		Dialogic.start("seelie")
		await get_tree().create_timer(wait + duration).timeout
	elif message == "crow takes berries":
		#get_tree().get_first_node_in_group("player").inventory.push_front(berries)
		
		get_tree().get_first_node_in_group("fade").fade(0.5,0.5)
		var duration = 0.5
		var wait = 0.5
		await get_tree().create_timer(duration).timeout
		crow.global_position = $final_position.global_position
		get_tree().get_first_node_in_group("player").global_position = $player_position.global_position
		Dialogic.start("crow")
		await get_tree().create_timer(wait + duration).timeout
