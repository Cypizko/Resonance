extends Node

@export var dialogue_layer: CanvasLayer 
@export var dialogue_label: RichTextLabel 
@export var room_light: Light3D # Лампа (SpotLight3D)

var current_level: int = 1
var max_levels: int = 4
var is_level_active = false
var total_jumps_planned = 0
var jumps_done = 0
var timer = 0.0

var player_mistakes = 0
var dialogue_queue: Array[String] = []
var is_waiting_for_start_confirmation = false

var timer_min = 1.5
var timer_max = 3.0
var light_script_timer: SceneTreeTimer = null

func _ready() -> void:
	if not is_in_group("level_manager"):
		add_to_group("level_manager")

	if dialogue_layer:
		dialogue_layer.visible = false

func start_game_sequence():
	print("Гра почалася, чекаємо дзвінок...")
	# Запускаємо дзвінок через 10 секунд після старту гри, як ви і хотіли
	await get_tree().create_timer(10.0).timeout
	start_intro_call()

# 1. Дзвінок на початку гри (Вступ)
func start_intro_call():
	# Вызываем метод start_ringing у всех объектов в группе "phone"
	get_tree().call_group("phone", "start_ringing")

# 2. Гравець клікає на телефон
func answer_phone():
	if is_waiting_for_start_confirmation:
		is_waiting_for_start_confirmation = false
		
		if dialogue_layer:
			dialogue_layer.visible = false
			
		print("Гру розпочато! Рівень 1.")
		start_level()
		return

	# Вступительная разговор с инспектором
	dialogue_queue = [
		"Інспектор: 'Операторе? Чуєте мене? Чудово. Вітаю на новому робочому місці.'",
		"Інспектор: 'Перед вами піддослідний. Ваше завдання — визначити, чи говорить він правду.'",
		"Інспектор: 'На столі лежить пам'ятка. Уважно ознайомтеся з правилами, перш ніж розпочати роботу.'",
		"Інспектор: 'З кожним рівнем система працюватиме нестабільно. Будьте уважні.'",
		"Інспектор: 'Якщо готові почати зміну — візьміть трубку ще раз.'"
	]
	
	show_intro_dialogue_chunk(5.0)

func show_intro_dialogue_chunk(delay: float):
	if dialogue_queue.size() > 0:
		var current_text = dialogue_queue.pop_front()
		if dialogue_layer and dialogue_label:
			dialogue_layer.visible = true
			dialogue_label.text = "[indent]" + current_text + "[/indent]"
		
		get_tree().create_timer(delay).timeout.connect(func():
			if dialogue_queue.size() > 0:
				show_intro_dialogue_chunk(delay)
			else:
				if dialogue_layer:
					dialogue_layer.visible = false
				is_waiting_for_start_confirmation = true
		)

# Запуск поточного рівня
func start_level():
	if current_level > max_levels:
		trigger_game_ending()
		return

	is_level_active = true
	jumps_done = 0
	total_jumps_planned = randi_range(0, 4)
	
	var line_speed = 150.0

	match current_level:
		1:
			timer_min = 1.0
			timer_max = 2.0
			line_speed = 80.0   # Було 150.0 — тепер значно спокійніше
			if room_light: room_light.light_energy = 1.0
		2:
			timer_min = 0.5
			timer_max = 1.0
			line_speed = 140.0  # Було 280.0
			if room_light: room_light.light_energy = 1.0
		3:
			timer_min = 0.2
			timer_max = 0.5
			line_speed = 220.0  # Було 450.0
			start_level_3_light_sequence()
		4:
			timer_min = 0.1
			timer_max = 0.3
			line_speed = 350.0  # Було 700.0
			start_level_3_light_sequence()

	get_tree().call_group("graph", "set_level_speed", line_speed)

	print("Рівень ", current_level, ". Заплановано стрибків: ", total_jumps_planned)
	show_suspect_phrase()
	timer = randf_range(timer_min, timer_max)

func start_level_3_light_sequence():
	if not room_light: return
	room_light.light_energy = 1.0
	
	light_script_timer = get_tree().create_timer(5.0)
	light_script_timer.timeout.connect(func():
		if not is_level_active: return
		room_light.light_energy = 0.0
		
		light_script_timer = get_tree().create_timer(7.0)
		light_script_timer.timeout.connect(func():
			if not is_level_active: return
			room_light.light_energy = 1.0
			run_periodic_flicker_loop()
		)
	)

func run_periodic_flicker_loop():
	if not is_level_active or not room_light: return
	room_light.light_energy = 1.0
	
	light_script_timer = get_tree().create_timer(10.0)
	light_script_timer.timeout.connect(func():
		if not is_level_active: return
		room_light.light_energy = 0.0
		
		light_script_timer = get_tree().create_timer(3.0)
		light_script_timer.timeout.connect(func():
			if is_level_active:
				run_periodic_flicker_loop()
		)
	)

func show_suspect_phrase():
	var suspect_text = ""
	match current_level:
		1: suspect_text = "Підозрюваний: 'Я вже все пояснив. Скільки ще можна повторювати? Я нічого не робив.'"
		2: suspect_text = "Підозрюваний: 'Ви... ви вже ставили мені це запитання. Скільки часу я тут перебуваю?'"
		3: suspect_text = "Підозрюваний: 'Ви повинні мені повірити. Інспектор... він не той, за кого себе видає.'"
		4: suspect_text = "Підозрюваний: 'Він сказав, що наступним буду я... Але ж тепер ваша черга, правда?'"

	if dialogue_layer and dialogue_label:
		dialogue_layer.visible = true
		dialogue_label.text = "[indent][Рівень " + str(current_level) + "/4]\n" + suspect_text + "[/indent]"
		
	get_tree().create_timer(4.0).timeout.connect(func():
		if dialogue_layer and is_level_active:
			dialogue_layer.visible = false 
	)

func _process(delta):
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
				get_tree().call_group("graph", "set_level_speed", 100.0)
				timer = 2.0

func check_answer(player_chose_truth: bool):
	if not is_level_active: return
		
	if room_light: room_light.light_energy = 1.0

	var actual_truth = (total_jumps_planned <= 2)
	is_level_active = false
	if dialogue_layer: dialogue_layer.visible = true

	var is_correct = (player_chose_truth == actual_truth)
	if not is_correct: player_mistakes += 1

	match current_level:
		1:
			dialogue_queue = [
				"Інспектор: 'Першу перевірку завершено. Непогано, операторе. Бачу, ви швидко освоїлися.'",
				"Інспектор: 'Наступний піддослідний уже готовий. Продовжуємо.'"
			]
		2:
			dialogue_queue = [
				"Інспектор: 'Дивно... У журналі зазначено, що цей піддослідний прибув лише сьогодні.'",
				"Інспектор: 'Не звертайте уваги. Будівля стара, іноді документи губляться.'",
				"Інспектор: 'Продовжуйте роботу, операторе.'"
			]
		3:
			dialogue_queue = [
				"Інспектор: 'Операторе, не підтримуйте розмов із піддослідними.'",
				"Інспектор: 'Вони часто намагаються впливати на ваше рішення.'",
				"Інспектор: 'І ще одне... Якщо почуєте стукіт у склі, не реагуйте. Це не входить до ваших обов'язків.'"
			]
		4:
			dialogue_queue = [
				"Інспектор: 'Операторе, у нас виникли невеликі проблеми зі зв'язком.'",
				"Інспектор: 'Мені повідомили, що в коридорі зафіксовано рух. Хоча... там нікого не повинно бути.'",
				"Інспектор: 'Не відволікайтеся. Залишилося підбити підсумки.'"
			]

	show_inspector_feedback(4.0)

func show_inspector_feedback(delay: float):
	if dialogue_queue.size() > 0:
		var current_text = dialogue_queue.pop_front()
		if dialogue_label:
			dialogue_label.text = "[indent]" + current_text + "[/indent]"
		
		get_tree().create_timer(delay).timeout.connect(func():
			show_inspector_feedback(delay)
		)
	else:
		if dialogue_layer: dialogue_layer.visible = false
		current_level += 1
		start_level()

func trigger_game_ending():
	is_level_active = false
	if dialogue_layer: dialogue_layer.visible = true

	if player_mistakes <= 2:
		dialogue_queue = [
			"Інспектор: 'Операторе... перевірку завершено.'",
			"Інспектор: 'Ви припустилися незначної кількості помилок. Результат прийнятний.'",
			"Інспектор: 'Зафіксовано успішне проходження зміни. Доступ до виходу дозволено.'",
			"Інспектор: 'Дякую за службу, операторе. Ви можете залишити приміщення.'",
			"Інспектор: 'І ще одне... Не повертайтеся сюди.'"
		]
	else:
		dialogue_queue = [
			"Інспектор: 'Операторе... за результатами перевірки виявлено критичну кількість помилок.'",
			"Інспектор: 'Ви більше не можете виконувати свої обов'язки. Відповідно до протоколу...'",
			"Піддослідний: 'Тепер ти розумієш? Тут ніхто нікого не перевіряє.'",
			"Інспектор (кричить): 'ПІДГОТУВАТИ НОВОГО ПІДДОСЛІДНОГО!'"
		]

	run_ending_sequence(4.5)

func run_ending_sequence(delay: float):
	if dialogue_queue.size() > 0:
		var current_text = dialogue_queue.pop_front()
		if dialogue_label:
			dialogue_label.text = "[indent]" + current_text + "[/indent]"
		
		get_tree().create_timer(delay).timeout.connect(func():
			run_ending_sequence(delay)
		)
	else:
		if dialogue_label:
			if player_mistakes <= 2:
				dialogue_label.text = "[indent]ЗМІНУ ЗАВЕРШЕНО\nКІНЕЦЬ № 1 — ДОПУЩЕНИЙ ДО ЗВІЛЬНЕННЯ[/indent]"
			else:
				dialogue_label.text = "[indent]ПЕРЕВІРКУ НЕ ПРОЙДЕНО\nКІНЕЦЬ № 2 — ПЕРЕДВЕДЕНИЙ ДО ОБ'ЄКТА[/indent]"
		if room_light:
			room_light.light_energy = 0.0
