extends Area3D

@export var screen_mesh: MeshInstance3D
@export var sub_viewport: SubViewport

@export var power_sound: AudioStream        # Довгий звук увімкнення
@export var ambient_hum_sound: AudioStream # Фоновий гул працюючого монітора

# Змінюємо на false, щоб телевізор був вимкнений при старті
var is_on: bool = false

@onready var audio_player: AudioStreamPlayer3D = $AudioTVPlayer3D      # Плеер для увімкнення
@onready var loop_audio_player: AudioStreamPlayer3D = $AudioTVLoop3D  # Плеер для гудіння

var label_tv: Label = null

func _ready():
	print("--- Ініціалізація телевізора ---")
	
	# 1. Додаємо вузол до групи "graph", щоб LevelManager міг надсилати сигнали
	if not is_in_group("graph"):
		add_to_group("graph")
		
	# 2. Знаходимо LabelTV у SubViewport та ховаємо його на старті
	if sub_viewport and sub_viewport.has_node("LabelTV"):
		label_tv = sub_viewport.get_node("LabelTV") as Label
		if label_tv:
			label_tv.visible = false
			
	if audio_player:
		print("Знайдено audio_player: ", audio_player.name)
		if power_sound:
			audio_player.stream = power_sound
	else:
		print("ПОМИЛКА: Не знайдено вузол AudioTVPlayer3D!")
		
	if loop_audio_player:
		print("Знайдено loop_audio_player: ", loop_audio_player.name)
		if ambient_hum_sound:
			loop_audio_player.stream = ambient_hum_sound
	else:
		print("ПОМИЛКА: Не знайдено вузол AudioTVLoop3D!")

	# === ВИСТАВЛЯЄМО ВИМКНЕНИЙ СТАН ПРИ СТАРТІ ===
	if screen_mesh:
		screen_mesh.visible = false
		
	if sub_viewport:
		sub_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		
	# Ставимо звук увімкнення на паузу з самого початку, щоб він був готовий до розігріву
	if audio_player:
		audio_player.stream_paused = true

func press():
	is_on = not is_on
	print("Монітор змінить стан на: ", "УВІМКНЕНО" if is_on else "ВИМКНЕНО")
	
	# Керуємо довгим звуком увімкнення (пауза / продовження)
	if audio_player:
		if is_on:
			audio_player.stream_paused = false
			if not audio_player.playing:
				audio_player.play()
			print("Звук увімкнення знято з паузи / запущено")
		else:
			audio_player.stream_paused = true
			print("Звук увімкнення поставлено на паузу")
	
	# Керуємо фоновим звуком
	if is_on:
		if loop_audio_player and not loop_audio_player.playing:
			loop_audio_player.play()
		print("Фоновий гул увімкнено")
	else:
		if loop_audio_player:
			loop_audio_player.stop()
		print("Фоновий гул зупинено")
	
	# Екран та в'юпорт
	if screen_mesh:
		screen_mesh.visible = is_on
		
	if sub_viewport:
		if is_on:
			sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		else:
			sub_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED

func start_ambient_sound():
	if loop_audio_player:
		if not loop_audio_player.playing:
			loop_audio_player.play()

func stop_ambient_sound():
	if loop_audio_player:
		loop_audio_player.stop()

# === ФУНКЦІЇ КЕРУВАННЯ ТЕКСТОМ (Викликаються з LevelManager через групу "graph") ===

func start_scan_ui():
	if label_tv:
		label_tv.visible = true
		label_tv.text = "[ СКАНУВАННЯ... ]"
		label_tv.modulate = Color(1.0, 0.7, 0.1) # Помаранчевий колір під час сканування

func show_analysis_complete():
	if label_tv:
		label_tv.visible = true
		label_tv.text = "[ АНАЛІЗ ЗАВЕРШЕНО ]"
		label_tv.modulate = Color(0.0, 3.0, 0.2) # Яскраво-зелений із сяйвом (HDR)

func reset_scan_ui():
	if label_tv:
		label_tv.visible = false

# === ПЕРЕДАЧА СИГНАЛІВ ДО СКРИПТА ГРАФІКА Line2D ===

func trigger_jump():
	if sub_viewport:
		for child in sub_viewport.get_children():
			if child.has_method("trigger_jump"):
				child.trigger_jump()

func set_level_speed(new_speed: float):
	if sub_viewport:
		for child in sub_viewport.get_children():
			if child.has_method("set_level_speed"):
				child.set_level_speed(new_speed)
