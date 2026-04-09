extends AnimatableBody3D
class_name NPC

@onready var interactable: Interactable = $Interactable
@export var berries: AnimatableBody3D

func _ready() -> void:
	interactable.Interact.connect(on_interact)
	

func on_interact():
	print("you did it, dumbass")
	Dialogic.start("bear asleep")

func _process(delta: float) -> void:
	if global_position.distance_to(berries.global_position) < 25 and berries.disabled == false:
		Dialogic.VAR.game_state = 6
		get_tree().get_first_node_in_group("fade").fade(0.5,0.5)
		var duration = 0.5
		var wait = 0.5
		await get_tree().create_timer(duration).timeout
		berries.queue_free()
		interactable.Interact.disconnect(on_interact)
		queue_free()
		await get_tree().create_timer(wait + duration).timeout
		
