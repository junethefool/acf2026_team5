extends AnimatableBody3D

@onready var interactable: Interactable = $Interactable
@export var allgrownup: Texture2D

func _ready() -> void:
	interactable.Interact.connect(on_interact)
	Dialogic.signal_event.connect(on_dialogic_signal)

func on_interact():
	print("you did it, dumbass")
	Dialogic.start("flower observation")
	
func on_dialogic_signal(message):
	if message == "dance end":
		for child in get_children():
			if child is Sprite3D:
				child.texture = allgrownup
		GameManager.adjust_all_grids_spring(1)
