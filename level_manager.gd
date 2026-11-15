extends Node

@export var dialogue_layer: CanvasLayer
@export var dialogue_label: RichTextLabel
@export var room_light: Light3D
@export var dialogue_audio_player: AudioStreamPlayer3D

# Окремі звуки для Інспектора та Піддослідного
@export var inspector_sound: AudioStream
@export var suspect_sound: AudioStream

@export var light_hum_sound: AudioStream      # Постійний гул лампи
@export var light_spark_sound: AudioStream    # Короткі іскри / потріскування
@export var light_hum_player: AudioStreamPlayer3D
@export var light_spark_player: AudioStreamPlayer3D

var current_level: int = 1
var max_levels: int = 4
var is_level_active: bool = false
var is_measurement_finished: bool = false
var total_jumps_planned: int = 0
var jumps_done: int = 0
var timer: float = 0.0

var player_mistakes: int = 0
var dialogue_queue: Array[String] = []

var intro_played: bool = false
var is_speaking: bool = false

var timer_min: float = 1.5
var timer_max: float = 3.0
var light_script_timer: SceneTreeTimer = null

func _ready() -> void:
	if not is_in_group("level_manager"):
		add_to_group("level_manager")

	if dialogue_layer:
		dialogue_layer.visible = false

# Програвання голосу: звук піддослідного нижчий за тон інспектора
func play_voice_sound(is_inspector: bool = true, duration: float = 1.8) -> void:
	if not dialogue_audio_player:
		return
		
	# Зміна звукового файлу при наявності окремих ресурсів
	if is_inspector and inspector_sound:
		dialogue_audio_player.stream = inspector_sound
	elif not is_inspector and suspect_sound:
		dialogue_audio_player.stream = suspect_sound
		
	if not dialogue_audio_player.stream:
		return

	# Інспектор — вищий/строгий тон (1.1 - 1.3), Піддослідний — глухий/низький тон (0.55 - 0.75)
	if is_inspector:
		dialogue_audio_player.pitch_scale = randf_range(1.1, 1.3)
	else:
		dialogue_audio_player.pitch_scale = randf_range(0.55, 0.75)
		
	dialogue_audio_player.play()
	
	get_tree().create_timer(duration).timeout.connect(func():
		if dialogue_audio_player and dialogue_audio_player.playing:
			dialogue_audio_player.stop()
	)

# Ефект друкарської машинки
func type_text(full_text: String, is_inspector: bool, on_complete: Callable) -> void:
	if not dialogue_layer or not dialogue_label:
		on_complete.call()
		return

	dialogue_layer.visible = true
	dialogue_label.text = full_text
	dialogue_label.visible_ratio = 0.0
	
	var char_count = full_text.length()
	var type_duration = clamp(char_count * 0.035, 0.8, 4.0)
	
	play_voice_sound(is_inspector, type_duration)
	
	var tween = create_tween()
	tween.tween_property(dialogue_label, "visible_ratio", 1.0, type_duration)
	
	tween.finished.connect(func():
		get_tree().create_timer(1.5).timeout.connect(func():
			on_complete.call()
		)
	)

func start_game_sequence() -> void:
	print("Гра почалася, чекаємо вступного дзвінка...")
	play_hum(true)
	await get_tree().create_timer(5.0).timeout
	get_tree().call_group("phone", "start_ringing")

func answer_phone() -> void:
	if is_speaking or is_level_active:
		return

	if not intro_played:
		intro_played = true
		is_speaking = true
		
		dialogue_queue = [
			"Інспектор: 'Операторе? Чуєте мене? Чудово. Вітаю на новому робочому місці.'",
			"Інспектор: 'Перед вами піддослідний. Ваше завдання — визначити, чи говорить він правду.'",
			"Інспектор: 'Перш за все, увімкніть осцилограф на столі.'",
			"Інспектор: 'Також на столі лежить пам'ятка. Уважно ознайомтеся з правилами.'",
			"Інспектор: 'З кожним рівнем система працюватиме нестабільно. Будьте уважні.'",
			"Інспектор: 'Коли вивчите інструкцію і будете готові почати перевірку — просто знову підніміть трубку.'"
		]
		
		show_intro_dialogue_chunk()
		return

	if current_level <= max_levels:
		play_level_briefing()

func show_intro_dialogue_chunk() -> void:
	if dialogue_queue.size() > 0:
		var current_text = dialogue_queue.pop_front()
		type_text(current_text, true, func():
			show_intro_dialogue_chunk()
		)
	else:
		if dialogue_layer:
			dialogue_layer.visible = false
		is_speaking = false
		get_tree().call_group("phone", "hang_up")

func play_level_briefing() -> void:
	is_speaking = true
	var briefing_text = ""
	
	match current_level:
		1: briefing_text = "Інспектор: 'Піддослідний №1 на позиції. Починаємо калібровку та перевірку.'"
		2: briefing_text = "Інспектор: 'Піддослідний №2 готовий. Датчики показують прискорений пульс, будьте уважні.'"
		3: briefing_text = "Інспектор: 'Піддослідний №3. У будівлі проблеми з електромережею, світло може збоїти.'"
		4: briefing_text = "Інспектор: 'Останній піддослідний на сьогодні. Система вкрай нестабільна. Закінчуємо це.'"

	type_text(briefing_text, true, func():
		if dialogue_layer:
			dialogue_layer.visible = false
		is_speaking = false
		get_tree().call_group("phone", "hang_up")
		start_level()
	)

func start_level() -> void:
	if current_level > max_levels:
		trigger_game_ending()
		return

	is_level_active = true
	is_measurement_finished = false
	jumps_done = 0
	total_jumps_planned = randi_range(0, 4)
	
	var line_speed = 150.0

	match current_level:
		1:
			timer_min = 1.0
			timer_max = 2.0
			line_speed = 80.0
			if room_light: room_light.light_energy = 1.0
		2:
			timer_min = 0.5
			timer_max = 1.0
			line_speed = 140.0
			if room_light: room_light.light_energy = 1.0
		3:
			timer_min = 0.2
			timer_max = 0.5
			line_speed = 220.0
			start_level_3_light_sequence()
		4:
			timer_min = 0.1
			timer_max = 0.3
			line_speed = 350.0
			start_level_3_light_sequence()

	get_tree().call_group("graph", "set_level_speed", line_speed)
	get_tree().call_group("graph", "start_scan_ui")

	print("Рівень ", current_level, ". Заплановано стрибків: ", total_jumps_planned)
	show_suspect_phrase()
	timer = randf_range(timer_min, timer_max)

func start_level_3_light_sequence() -> void:
	if not room_light: return
	room_light.light_energy = 1.0
	play_hum(true) # Вмикаємо фоновий гул лампи на початку
	
	light_script_timer = get_tree().create_timer(5.0)
	light_script_timer.timeout.connect(func():
		if not is_level_active: return
		room_light.light_energy = 0.0
		play_spark() # Звук іскри/клацання при різкому вимкненні
		play_hum(false) # Вимикаємо гул у темряві
		
		light_script_timer = get_tree().create_timer(7.0)
		light_script_timer.timeout.connect(func():
			if not is_level_active: return
			room_light.light_energy = 1.0
			play_spark() # Звук іскри при увімкненні
			play_hum(true) # Знову гуде
			run_periodic_flicker_loop()
		)
	)

func run_periodic_flicker_loop() -> void:
	if not is_level_active or not room_light: return
	room_light.light_energy = 1.0
	play_hum(true)
	
	light_script_timer = get_tree().create_timer(10.0)
	light_script_timer.timeout.connect(func():
		if not is_level_active: return
		room_light.light_energy = 0.0
		play_spark()
		play_hum(false)
		
		light_script_timer = get_tree().create_timer(3.0)
		light_script_timer.timeout.connect(func():
			if is_level_active:
				run_periodic_flicker_loop()
		)
	)

# Додаткове випадкове миготіння в процесі (_update_lighting) зі звуком іскор
func _update_lighting(delta: float) -> void:
	if is_level_active and current_level >= 3 and room_light and room_light.light_energy > 0.5:
		if randf() < 0.02: # зменшив шанс, щоб іскри звучали дозовано
			room_light.light_energy = randf_range(0.3, 1.0)
			play_spark() # Короткий звук збою під час мерехтіння

	if is_level_active:
		timer -= delta
		if timer <= 0:
			if jumps_done < total_jumps_planned:
				get_tree().call_group("graph", "trigger_jump")
				jumps_done += 1
				timer = randf_range(timer_min, timer_max)
			else:
				if not is_measurement_finished:
					finish_measurement()

# --- ДОПОМІЖНІ ФУНКЦІЇ ДЛЯ КЕРУВАННЯ ЗВУКОМ СВІТЛА ---
func play_hum(play: bool) -> void:
	if not light_hum_player: return
	if light_hum_sound and light_hum_player.stream != light_hum_sound:
		light_hum_player.stream = light_hum_sound
		
	if play:
		if not light_hum_player.playing:
			light_hum_player.play()
	else:
		if light_hum_player.playing:
			light_hum_player.stop()

func play_spark() -> void:
	if not light_spark_player or not light_spark_sound: return
	light_spark_player.stream = light_spark_sound
	light_spark_player.play()

func show_suspect_phrase() -> void:
	var suspect_text = ""
	match current_level:
		1: suspect_text = "Підозрюваний: 'Я вже все пояснив. Скільки ще можна повторювати? Я нічого не робив.'"
		2: suspect_text = "Підозрюваний: 'Ви... ви вже ставили мені це запитання. Скільки часу я тут перебуваю?'"
		3: suspect_text = "Підозрюваний: 'Ви повинні мені повірити. Інспектор... він не той, за кого себе видає.'"
		4: suspect_text = "Підозрюваний: 'Він сказав, що наступним буду я... Але ж тепер ваша черга, правда?'"

	var full_phrase = "[indent][Рівень " + str(current_level) + "/4]\n" + suspect_text + "[/indent]"
	
	type_text(full_phrase, false, func():
		if dialogue_layer and is_level_active:
			dialogue_layer.visible = false
	)

func _process(delta: float) -> void:
	if is_level_active and current_level >= 3 and room_light and room_light.light_energy > 0.5:
		if randf() < 0.05:
			room_light.light_energy = randf_range(0.3, 1.0)

	if is_level_active:
		timer -= delta
		if timer <= 0:
			if jumps_done < total_jumps_planned:
				get_tree().call_group("graph", "trigger_jump")
				jumps_done += 1
				timer = randf_range(timer_min, timer_max)
			else:
				if not is_measurement_finished:
					finish_measurement()

func finish_measurement() -> void:
	is_measurement_finished = true
	get_tree().call_group("graph", "set_level_speed", 80.0)
	get_tree().call_group("graph", "show_analysis_complete")
	print("Замір завершено! Очікування вибору гравця.")

func flash_red_light() -> void:
	if not room_light: return
	
	var original_color = room_light.light_color
	room_light.light_color = Color(1.0, 0.1, 0.1)
	
	var tween = create_tween()
	tween.tween_property(room_light, "light_color", original_color, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func check_answer(player_chose_truth: bool) -> void:
	if not is_level_active: return
		
	get_tree().call_group("graph", "reset_scan_ui")
	if room_light: room_light.light_energy = 1.0

	var actual_truth = (total_jumps_planned <= 2)
	is_level_active = false
	is_speaking = true

	var is_correct = (player_chose_truth == actual_truth)
	
	if not is_correct:
		player_mistakes += 1
		flash_red_light()

	match current_level:
		1:
			if is_correct:
				dialogue_queue = [
					"Інспектор: 'Чудово. Ви правильно вирахували піддослідного.'",
					"Інспектор: 'Підніміть трубку, коли будете готові до наступного завдання.'"
				]
			else:
				dialogue_queue = [
					"Інспектор: 'Помилка, операторе! Датчики показували зовсім інше.'",
					"Інспектор: 'Будьте уважнішими. Підніміть трубку, коли зберетеся з думками.'"
				]
		2:
			if is_correct:
				dialogue_queue = [
					"Інспектор: 'Точна відповідь. Прискорений пульс вас не заплутав.'",
					"Інспектор: 'Підніміть трубку, коли буде змога продовжити.'"
				]
			else:
				dialogue_queue = [
					"Інспектор: 'Невірно. Ви піддалися хаосу та неправильно зчитали ривки.'",
					"Інспектор: 'Не поспішайте. Підніміть трубку для наступного виклику.'"
				]
		3:
			if is_correct:
				dialogue_queue = [
					"Інспектор: 'Вірно. Світловий збій не завадив вам зробити правильний висновок.'",
					"Інспектор: 'Готуйтеся. Підніміть трубку для фінального виклику.'"
				]
			else:
				dialogue_queue = [
					"Інспектор: 'Помилка! Ви дозволили миготінню та словами піддослідного збити вас.'",
					"Інспектор: 'Це стає небезпечно. Підніміть трубку, коли будете готові.'"
				]
		4:
			if is_correct:
				dialogue_queue = [
					"Інспектор: 'Чудово, це була правильна відповідь. Закінчуємо зміну.'"
				]
			else:
				dialogue_queue = [
					"Інспектор: 'Критична помилка на фінальному етапі... Очікуйте на підсумки.'"
				]

	show_inspector_feedback()

func show_inspector_feedback() -> void:
	if dialogue_queue.size() > 0:
		var current_text = dialogue_queue.pop_front()
		type_text(current_text, true, func():
			show_inspector_feedback()
		)
	else:
		if dialogue_layer: dialogue_layer.visible = false
		is_speaking = false
		current_level += 1
		get_tree().call_group("phone", "hang_up")
		
		if current_level > max_levels:
			trigger_game_ending()

func trigger_game_ending() -> void:
	is_level_active = false
	is_speaking = true

	# Зупиняємо гул лампи при фіналі, якщо він грав
	play_hum(false)

	# --- ТУТ ЗМІНЮЄМО УМОВУ ---
	# Якщо помилок 0 або 1 — добра кінцівка. Якщо більше 1 (2, 3 і т.д.) — погана.
	if player_mistakes <= 1:
		dialogue_queue = [
			"Інспектор: 'Операторе... перевірку завершено.'",
			"Інспектор: 'Ви припустилися мінімальної кількості помилок. Результат прийнятний.'",
			"Інспектор: 'Зафіксовано успішне проходження зміни. Доступ до виходу дозволено.'",
			"Інспектор: 'Дякую за службу, операторе. Ви можете залишити приміщення.'",
			"Інспектор: 'І ще одне... Не повертайтеся сюди.'"
		]
	else:
		dialogue_queue = [
			"Інспектор: 'Операторе... за результатами перевірки виявлено занадто багато помилок.'",
			"Інспектор: 'Ви більше не можете виконувати свої обов'язки. Відповідно до протоколу...'",
			"Піддослідний: 'Тепер ти розумієш? Тут ніхто нікого не перевіряє.'",
			"Інспектор (кричить): 'ПІДГОТУВАТИ НОВОГО ПІДДОСЛІДНОГО!'"
		]

	run_ending_sequence()

func run_ending_sequence() -> void:
	if dialogue_queue.size() > 0:
		var current_text = dialogue_queue.pop_front()
		var is_insp = not current_text.begins_with("Піддослідний")
		
		type_text(current_text, is_insp, func():
			run_ending_sequence()
		)
	else:
		# Очищаємо діалогове вікно перед фінальним ефектом
		if dialogue_layer:
			dialogue_layer.visible = false
			
		# --- ВИКЛИКАЄМО НОВИЙ CONTROLLER КІНЦІВОК ---
		if player_mistakes <= 1:
			get_tree().call_group("ending_controller", "trigger_good_ending")
		else:
			get_tree().call_group("ending_controller", "trigger_bad_ending")
func _input(event: InputEvent) -> void:
	# Нажмите клавишу F1 на клавиатуре для проверки ДОВОЙ концовки
	if event.is_action_pressed("ui_f1") or (event is InputEventKey and event.pressed and event.keycode == KEY_F1):
		print("ТЕСТ: Принудительный запуск доброй концовки")
		player_mistakes = 0 # Сбрасываем ошибки до нормы
		trigger_game_ending()

	# Нажмите клавишу F2 на клавиатуре для проверки ПЛОХОЙ концовки
	if event.is_action_pressed("ui_f2") or (event is InputEventKey and event.pressed and event.keycode == KEY_F2):
		print("ТЕСТ: Принудительный запуск плохой концовки")
		player_mistakes = 5 # Накручиваем ошибки для срабатывания плохой концовки
		trigger_game_ending()
func load_progress(data: Dictionary) -> void:
	current_level = clampi(
		int(data.get("current_level", 1)),
		1,
		max_levels + 1
	)

	player_mistakes = int(data.get("mistakes", 0))
	intro_played = bool(data.get("intro_played", false))

	# Сбрасываем временное состояние текущего измерения
	is_level_active = false
	is_measurement_finished = false
	is_speaking = false

	jumps_done = 0
	total_jumps_planned = 0
	timer = 0.0

	dialogue_queue.clear()

	print("Прогресс восстановлен!")
	print("Уровень: ", current_level)
	print("Ошибки: ", player_mistakes)


# Полный сброс новой игры
func reset_progress() -> void:
	current_level = 1
	player_mistakes = 0
	intro_played = false

	is_level_active = false
	is_measurement_finished = false
	is_speaking = false

	jumps_done = 0
	total_jumps_planned = 0
	timer = 0.0

	dialogue_queue.clear()
