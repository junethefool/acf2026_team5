extends AudioStreamPlayer

func _ready():
	Dialogic.signal_event.connect(on_signal)
	
func on_signal(message):
	if message == "party":
		stream_paused = true
	if message == "dance end":
		stream_paused = false
