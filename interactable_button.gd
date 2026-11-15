extends Area3D

@export var button_type: String = "ПРАВДА" 
@export var target_node: Node3D 
@export var click_sound: AudioStream 

var original_y: float
@onready var audio_player: AudioStreamPlayer3D = $AudioButttonT3D if has_node("AudioButttonT3D") else $AudioButttonF3D

func _ready():
	if not target_node:
		target_node = get_parent()
		
	if target_node:
		original_y = target_node.position.y
		
	# Автоматически находим любой доступный плеер внутри Area3D, если имена отличаются
	if not audio_player:
		for child in get_children():
			if child is AudioStreamPlayer3D:
				audio_player = child
				break

func press():
	if not target_node:
		return
		
	print("Вызвана функция: ", button_type)
	
	# Воспроизводим звук
	if audio_player:
		if click_sound:
			audio_player.stream = click_sound
		audio_player.stop()
		audio_player.play()
	var is_truth = (button_type == "ПРАВДА")
	get_tree().call_group("level_manager", "check_answer", is_truth)
	
	var tween = create_tween()
	tween.tween_property(target_node, "position:y", original_y - 0.05, 0.1)
	tween.tween_property(target_node, "position:y", original_y, 0.1)
