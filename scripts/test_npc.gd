extends AnimatableBody3D
class_name NPC

@onready var interactable: Interactable = $Interactable


func _ready() -> void:
	interactable.Interact.connect(on_interact)


func on_interact():
	print("you did it, dumbass")
