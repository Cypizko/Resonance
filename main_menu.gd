extends Control

@export var camera: Camera3D
@export var table_position: Marker3D
@export var black_screen: ColorRect
@export var hud: CanvasLayer
@export var music_player: AudioStreamPlayer
@export var hover_sound: AudioStream
@export var ui_audio_player: AudioStreamPlayer
var is_game_started = false

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if hud:
		hud.visible = false
	# Дозволяємо меню обробляти ввід, навіть коли гра знаходиться на паузі
	process_mode = Node.PROCESS_MODE_ALWAYS
func _on_button_mouse_entered():
	if $ButtonClickPlayer:
		$ButtonClickPlayer.stop()
		$ButtonClickPlayer.play()
func _on_button_exit_pressed():
	get_tree().quit()
	
func _on_button_play_pressed():
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	get_tree().paused = false
	
	if music_player:
		music_player.stop() 
		
	if not is_game_started:
		is_game_started = true
		
		if black_screen:
			black_screen.visible = true
			black_screen.color.a = 1.0
			
			var tween = create_tween().set_parallel(true)
			tween.tween_property(black_screen, "color:a", 0.0, 3.0).set_ease(Tween.EASE_OUT)
			
			if camera and table_position:
				tween.tween_property(camera, "global_position", table_position.global_position, 4.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
				tween.tween_property(camera, "global_rotation", table_position.global_rotation, 4.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			
			# Чекаємо 4 секунди завершення польоту камери
			get_tree().create_timer(4.0).timeout.connect(func():
				if hud and not visible:
					hud.visible = true
				
				# === ПЕРЕДАЄМО СИГНАЛ В LEVEL_MANAGER ЩОБ ПОЧАТИ ВХІДНІЙ ТАЙМЕР ДЗВІНКА ===
				get_tree().call_group("level_manager", "start_game_sequence")
			)
	else:
		if music_player:
			music_player.stop()
		if hud:
			hud.visible = true

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if is_game_started:
			if visible:
				# Закриваємо меню (продовжуємо гру)
				visible = false
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
				get_tree().paused = false # Знімаємо з паузи
				if music_player:
					music_player.stop()
				if hud:
					hud.visible = true
			else:
				# Відкриваємо меню (ставимо гру на паузу)
				visible = true
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				get_tree().paused = true # Вмикаємо паузу для всієї гри
				if music_player and music_player.stream:
					music_player.play()
				if hud:
					hud.visible = false
