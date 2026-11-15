extends Control

@export var camera: Camera3D
@export var table_position: Marker3D
@export var black_screen: ColorRect
@export var hud: CanvasLayer

func _ready() -> void:
	# При запуске уровня сразу включаем интро-анимацию
	run_intro_sequence()

# Вступительная анимация (полет камеры к столу)
func run_intro_sequence() -> void:
	if hud:
		hud.visible = false
		
	if black_screen:
		black_screen.visible = true
		black_screen.color.a = 1.0
		
		var tween = create_tween().set_parallel(true)
		tween.tween_property(black_screen, "color:a", 0.0, 3.0).set_ease(Tween.EASE_OUT)
		
		# Если камера задана, плавно двигаем её к столу
		# (В самой сцене node_3d.tscn камера изначально может стоять на точке старта меню)
		if camera and table_position:
			tween.tween_property(camera, "global_position", table_position.global_position, 4.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tween.tween_property(camera, "global_rotation", table_position.global_rotation, 4.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
		get_tree().create_timer(4.0).timeout.connect(func():
			if hud:
				hud.visible = true
			get_tree().call_group("level_manager", "start_game_sequence")
		)

# Обработка Escape во время игры (возврат в меню или пауза)
func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		# Возвращаемся в главное меню по Escape
		get_tree().paused = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_tree().change_scene_to_file("res://main_menu.tscn")
