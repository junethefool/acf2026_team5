extends Sprite3D

func _ready():
	Dialogic.signal_event.connect(on_dialogic_signal)
	
func on_dialogic_signal(message):
	if message == "dance_end":
		visible = true
