extends Node3D

@export var camera: Camera3D
@export var table_position: Marker3D
@export var black_screen: ColorRect
@export var hud: CanvasLayer
var continue_game: bool = false 
func _ready() -> void:
	continue_game = GlobalGameData.continue_requested
	GlobalGameData.continue_requested = false

	var level_manager = get_node_or_null("LevelManager")

	if level_manager:
		if continue_game:
			var save_data = GlobalGameData.load_game()
			
			if save_data.is_empty():
				continue_game = false
				level_manager.reset_progress()
			else:
				level_manager.load_progress(save_data)
		else:
			level_manager.reset_progress()
		run_intro_sequence()

func run_intro_sequence(start_new_game: bool = true) -> void:
	if hud:
		hud.visible = false
		
	if black_screen:
		black_screen.visible = true
		black_screen.color.a = 1.0
		
		var tween = create_tween().set_parallel(true)
		tween.tween_property(black_screen, "color:a", 0.0, 3.0).set_ease(Tween.EASE_OUT)
		
		if camera and table_position:
			tween.tween_property(camera, "global_position", table_position.global_position, 4.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tween.tween_property(camera, "global_rotation", table_position.global_rotation, 4.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
		get_tree().create_timer(4.0).timeout.connect(func():
			if hud:
				hud.visible = true

			var level_manager = get_node_or_null("LevelManager")

	# Если сохранение было сделано после последнего уровня
			if continue_game and level_manager \
			and level_manager.current_level > level_manager.max_levels:

				level_manager.trigger_game_ending()
			else:
				get_tree().call_group("level_manager", "start_game_sequence")
)

# По нажатию ESC сохраняем игру и возвращаемся в главное меню
func _input(event: InputEvent) -> void:
	if event is InputEventKey \
	and event.pressed \
	and not event.echo \
	and event.keycode == KEY_ESCAPE:

		var level_manager = get_node_or_null("LevelManager")

		if level_manager:
			GlobalGameData.save_game(
				level_manager.current_level,
				level_manager.player_mistakes,
				level_manager.intro_played
			)

		get_tree().paused = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

		get_tree().change_scene_to_file("res://main_menu.tscn")
