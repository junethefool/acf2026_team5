extends CanvasLayer

func _ready():
	add_to_group("fade")

func fade_out(duration):
	var tween = create_tween()
	tween.tween_property($ColorRect,"modulate:a",1,duration)
	await tween.finished
	
func fade_in(duration):
	var tween = create_tween()
	tween.tween_property($ColorRect,"modulate:a",0,duration)
	await tween.finished

func fade(duration,wait):
	await fade_out(duration)
	await get_tree().create_timer(wait).timeout
	await fade_in(duration)
