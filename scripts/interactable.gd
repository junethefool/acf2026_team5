extends Node
class_name Interactable

signal Interact
#These are for if we want to show UI when entering an interactable Range
signal InteractEnter
signal InteractLeave

@export var interaction_range: Area3D

var can_interact: bool = false

func _ready() -> void:
	interaction_range.area_entered.connect(on_area_entered)
	interaction_range.area_exited.connect(on_area_exited)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("activate") && can_interact == true and get_tree().get_first_node_in_group("player").state == 0:
		Interact.emit()
		
func on_area_entered(other_area: Area3D):
	if not other_area is PlayerRange:
		pass
	InteractEnter.emit()
	can_interact = true


func on_area_exited(other_area: Area3D):
	if not other_area is PlayerRange:
		pass
	InteractLeave.emit()
	can_interact = false
