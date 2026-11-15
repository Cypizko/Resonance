extends Control

@export var camera: Camera3D
@export var table_position: Marker3D
@export var black_screen: ColorRect
@export var hud: CanvasLayer

var is_game_started = false

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if hud:
		hud.visible = false

func _on_button_exit_pressed():
	get_tree().quit()

func _on_button_play_pressed():
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
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
			
			# Ждем 4 секунды окончания полета и показываем HUD (если меню не открыто снова)
			get_tree().create_timer(4.0).timeout.connect(func():
				if hud and not visible:
					hud.visible = true
			)
	else:
		# Если это просто выход из паузы, возвращаем интерфейс сразу
		if hud:
			hud.visible = true

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if is_game_started:
			if visible:
				visible = false
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
				if hud:
					hud.visible = true
			else:
				visible = true
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				if hud:
					hud.visible = false
