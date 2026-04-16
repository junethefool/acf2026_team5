extends Node

var player: CharacterBody3D
var background: CanvasLayer
var text: CanvasLayer

func _ready() -> void:
	call_deferred("ready2")
	player = get_tree().get_first_node_in_group("player")
func ready2():
	background = find_child("background")
	text = find_child("text")
	background.visible = false
	text.visible = false
	
func _process(_delta: float) -> void:
	if player.state == 4:
		text.get_child(0).text = player.inventory[0].description
		text.visible = true
		background.visible = true
	else:
		background.visible = false
		text.visible = false
		
