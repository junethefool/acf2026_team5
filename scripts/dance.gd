extends Sprite3D

var dancing = false
@export var bpm: float
var timer: float
var bounce_direction = Vector3(0,1,0)
var active_bounce = false
var bounce_speed: float
var active_spin = false
var start_position: Vector3
func _ready():
	Dialogic.signal_event.connect(on_dialogic_signal)
	timer = 60/bpm
	start_position = global_position
func _physics_process(delta: float) -> void:
	#if Input.is_action_just_pressed("dance"):
	#	dancing = !dancing
	
	if dancing == true and active_bounce == false:
		active_bounce = true
		bounce()
		
	if dancing == true and active_spin == false:
		active_spin = true
		spin()
		
	if active_bounce == true:
		translate(bounce_direction*bounce_speed*delta)
	
	
func on_dialogic_signal(message):
	if message == "dance":
		dancing = true
	if message == "dance_end":
		dancing = false

func bounce():
	var max_speed = 2
	bounce_speed = max_speed
	var tween = create_tween()
	tween.tween_property(self,"bounce_speed",0, timer)
	await tween.finished
	bounce_direction *= -1
	var tween2 = create_tween()
	tween2.tween_property(self,"bounce_speed",max_speed, timer)
	await tween2.finished
	bounce_direction *= -1
	active_bounce = false
	global_position.y = start_position.y

func spin():
	await get_tree().create_timer(timer*2).timeout
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(self,"rotation:y", TAU, timer)
	await tween.finished
	await get_tree().create_timer(timer*2).timeout
	var tween2 = create_tween()
	tween2.set_ease(Tween.EASE_IN_OUT)
	tween2.set_trans(Tween.TRANS_SINE)
	tween2.tween_property(self,"rotation:y", -TAU, timer)
	await tween2.finished
	active_spin = false
	
