extends NPC

@export var player: CharacterBody3D
@export var hair: AnimatableBody3D

func _ready() -> void:
	interactable.Interact.connect(on_interact)
	Dialogic.signal_event.connect(on_dialogic_signal)

func on_interact():
	Dialogic.start("unicorn")
	
func on_dialogic_signal(message):
	if message == "give hair":
		player.inventory.push_front(hair)
