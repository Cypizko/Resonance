extends Node

@export var room_light: Light3D
@export var back_light: Light3D # Свет сзади силуэта (SpotLight3D3)
@export var main_top_light: Light3D # Верхний свет (SpotLight3D4)
@export var player_camera: Camera3D

@export var fade_rect: ColorRect # ColorRect внутри CanvasLayer для затемнения
@export var ending_ui_label: Label # Метка для текста концовки

# Аудио плееры для финалов
@export var ending_audio_player: AudioStreamPlayer
@export var bad_ending_sound: AudioStream # Звук удара / электрического сбоя
@export var tv_glitch_sound: AudioStream

# Дополнительно: аудио плеер гула лампы / фонового шума в комнате, чтобы выключать его
@export var lamp_audio_player: AudioStreamPlayer3D 

# Ссылка на SubViewport или элементы телевизора для выключения
@export var tv_sub_viewport: SubViewport

func _ready() -> void:
	if not is_in_group("ending_controller"):
		add_to_group("ending_controller")
	
	if fade_rect:
		fade_rect.color.a = 0.0
	if ending_ui_label:
		ending_ui_label.visible = false

# --- ДОБРА КІНЦІВКА ---
func trigger_good_ending() -> void:
	print3D_or_print("Запуск доброї кінцівки...")
	
	var tween = create_tween().set_parallel(true)
	# Плавне затухання світла в кімнаті
	if room_light:
		tween.tween_property(room_light, "light_energy", 0.2, 3.0)
	if main_top_light:
		tween.tween_property(main_top_light, "light_energy", 0.1, 3.0)
		
	# Плавне вимкнення екрана монітора (замість modulate используем alpha у TextureRect, если нужно, либо отключаем обновление)
	if tv_sub_viewport:
		tv_sub_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED

	# Чекаємо 3 секунди і робимо повне затемнення екрана
	await get_tree().create_timer(3.0).timeout
	
	var fade_tween = create_tween()
	if fade_rect:
		fade_tween.tween_property(fade_rect, "color:a", 1.0, 2.0)
		
	fade_tween.finished.connect(show_good_ui)

func show_good_ui() -> void:
	if ending_ui_label:
		ending_ui_label.visible = true
		ending_ui_label.text = "ЗМІНУ ЗАВЕРШЕНО\nОПЕРАТОРА ДОПУЩЕНО ДО ЗВІЛЬНЕННЯ"
		
		# Ждем 5 секунд, выключаем звуки и возвращаемся в меню
		await get_tree().create_timer(5.0).timeout
		return_to_menu()

# --- ПОГАНА КІНЦІВКА ---
func trigger_bad_ending() -> void:
	print3D_or_print("Запуск поганої кінцівки!")
	
	# 1. Звук удару / електрики
	if ending_audio_player and bad_ending_sound:
		ending_audio_player.stream = bad_ending_sound
		ending_audio_player.play()
		
	# 2. Тряска камери
	shake_camera(0.5, 0.4)
	
	# 3. Резкий злам світла: підсвічування за силуетом стає червоним і яскравим
	var tween = create_tween().set_parallel(true)
	if back_light:
		tween.tween_property(back_light, "light_color", Color.RED, 0.1)
		tween.tween_property(back_light, "light_energy", 6.0, 0.1)
		
	# 4. Стробоскоп основного світла
	start_light_strobe()
	
	# 5. Вимикаємо екран монітора
	if tv_sub_viewport:
		tv_sub_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED

	await get_tree().create_timer(1.5).timeout
	
	# 6. Повне погасання і різкий перехід у чорний
	if room_light: room_light.light_energy = 0.0
	if back_light: back_light.light_energy = 0.0
	if main_top_light: main_top_light.light_energy = 0.0
	
	if fade_rect:
		fade_rect.color.a = 1.0
		
	show_bad_ui()

func show_bad_ui() -> void:
	if ending_ui_label:
		ending_ui_label.visible = true
		ending_ui_label.text = "ПЕРЕВІРКУ НЕ ПРОЙДЕНО\nОПЕРАТОРА ВИЗНАНО НЕПРИДАТНИМ\nПІДГОТУВАТИ НОВОГО ПІДДОСЛІДНОГО"
		
		# Ждем 5 секунд, выключаем звуки и возвращаемся в меню
		await get_tree().create_timer(5.0).timeout
		return_to_menu()

# Допоміжна функція тряски камери
func shake_camera(duration: float, intensity: float) -> void:
	if not player_camera: return
	var timer = 0.0
	var original_pos = player_camera.position
	while timer < duration:
		player_camera.position = original_pos + Vector3(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity),
			0
		)
		timer += get_process_delta_time()
		await get_tree().process_frame
	player_camera.position = original_pos

func start_light_strobe() -> void:
	for i in range(6):
		if main_top_light: main_top_light.visible = false
		if room_light: room_light.visible = false
		await get_tree().create_timer(randf_range(0.04, 0.1)).timeout
		if main_top_light: main_top_light.visible = true
		if room_light: room_light.visible = true
		await get_tree().create_timer(randf_range(0.04, 0.1)).timeout

func print3D_or_print(text: String) -> void:
	print(text)

func return_to_menu() -> void:
	print("Возвращение в главное меню...")

	# Останавливаем звуки концовки
	if ending_audio_player:
		ending_audio_player.stop()

	if lamp_audio_player:
		lamp_audio_player.stop()

	# Скрываем текст концовки
	if ending_ui_label:
		ending_ui_label.visible = false

	# Возвращаем стандартное состояние игры
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	# Переходим на отдельную сцену главного меню
	var error = get_tree().change_scene_to_file("res://main_menu.tscn")

	if error != OK:
		push_error("Не удалось открыть главное меню! Код ошибки: " + str(error))
