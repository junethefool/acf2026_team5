extends Area3D

signal items_received
var needed_item_list = ["bucket", "knife", "shovel"]
var present_item_list: Array = []
var difference = []
@export var filled: bool = false

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	call_deferred("_ready2")
	
func _ready2():
	if filled:
		items_received.emit()
		return
	for body in get_overlapping_bodies():
		present_item_list.append(str(body.name))
		difference = needed_item_list.duplicate()
		for item in present_item_list:
			difference.erase(item)
		if difference.is_empty():
			filled = true
			items_received.emit()
			Dialogic.VAR.shed_missing = 0
		else:
			Dialogic.VAR.shed_missing = 1
func _on_body_entered(body):
	if not body is AnimatableBody3D:
		pass
	if needed_item_list.find(body.name) != -1:
		present_item_list.append(str(body.name))
		difference = needed_item_list.duplicate()
		for item in present_item_list:
			difference.erase(item)
		if difference.is_empty():
			filled = true
			items_received.emit()
			Dialogic.VAR.shed_missing = 0
		else:
			Dialogic.VAR.shed_missing = 1
func _on_body_exited(body):
	if not body is AnimatableBody3D:
		pass
	if needed_item_list.find(body.name) != -1:
		present_item_list.erase(str(body.name))
		difference = needed_item_list.duplicate()
		for item in present_item_list:
			difference.erase(item)
		if !difference.is_empty():
			Dialogic.VAR.shed_missing = 1
		else:
			Dialogic.VAR.shed_missing = 0
