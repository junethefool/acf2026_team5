extends CanvasLayer

var player: CharacterBody3D
var background: CanvasLayer

func _ready():
	call_deferred("ready2")
	
func ready2():
		player = get_tree().get_first_node_in_group("Player")
		background = get_tree().get_first_node_in_group("item_description")
		visible = false
		background.visible = false
		
func _process(delta: float) -> void:
	if player.state == 4:
		background.visible = true
		visible = true
		$description.text = player.inventory[0].description
	else:
		visible = false
		background.visible = false
