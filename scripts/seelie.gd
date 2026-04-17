extends AnimatableBody3D

@onready var interactable: Interactable = $Interactable
@export var crow: AnimatableBody3D


func _ready() -> void:
	interactable.Interact.connect(on_interact)
	Dialogic.signal_event.connect(on_dialogic_signal)
	$Area3D.body_entered.connect(on_body_entered)

func on_interact():
	print("you did it, dumbass")
	Dialogic.start("seelie")
	
func on_dialogic_signal(message):
	if message == "crow":
		get_tree().get_first_node_in_group("fade").fade(0.5,0.5)
		var duration = 0.5
		var wait = 0.5
		await get_tree().create_timer(duration).timeout
		crow.global_position = $crow.global_position
		await get_tree().create_timer(wait + duration).timeout
		Dialogic.start("seelie")
		
	elif message == "crow takes berries":
		#get_tree().get_first_node_in_group("player").inventory.push_front(berries)
		
		get_tree().get_first_node_in_group("fade").fade(0.5,0.5)
		var duration = 0.5
		var wait = 0.5
		await get_tree().create_timer(duration).timeout
		crow.global_position = $final_position.global_position
		get_tree().get_first_node_in_group("player").global_position = $player_position.global_position
		await get_tree().create_timer(wait + duration).timeout
		Dialogic.start("crow")
	
	elif message == "come here":
		get_tree().get_first_node_in_group("fade").fade(0.5,0.5)
		var duration = 0.5
		var wait = 0.5
		await get_tree().create_timer(duration).timeout
		get_tree().get_first_node_in_group("player").global_position = $talk.global_position
		await get_tree().create_timer(wait + duration).timeout
		Dialogic.start("seelie")
func on_body_entered(body):
	if Dialogic.VAR.first_talk == false and body is CharacterBody3D:
		
		Dialogic.start("seelie")
