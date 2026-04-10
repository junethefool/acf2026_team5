extends CanvasLayer

@export var player:CharacterBody3D

func _ready():
	add_to_group("fade")

func fade_out(duration):
	var tween = create_tween()
	var box = get_child(0)
	tween.tween_property(box,"modulate:a",1,duration)
	await tween.finished
	
func fade_in(duration):
	var tween = create_tween()
	var box = get_child(0)
	tween.tween_property(box,"modulate:a",0,duration)
	await tween.finished

func fade(duration,wait):
	var statesave = player.state
	player.state = 6
	await fade_out(duration)
	await get_tree().create_timer(wait).timeout
	await fade_in(duration)
	player.state = statesave
