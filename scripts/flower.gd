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
		var duration = 2
		var wait = 0.5
		await get_tree().create_timer(duration).timeout
		for child in get_children():
			if child is Sprite3D:
				child.texture = allgrownup
				global_position.y += 1
		GameManager.adjust_all_grids_spring(1)
		GameManager.adjust_all_grids_snow(-1)
		await get_tree().create_timer(wait + duration).timeout
