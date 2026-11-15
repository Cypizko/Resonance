extends Node

var is_level_active = false
var total_jumps_planned = 0
var jumps_done = 0
var timer = 0.0

func start_level():
	is_level_active = true
	jumps_done = 0
	total_jumps_planned = randi_range(0, 4)
	print("Уровень начался! Запланировано скачков: ", total_jumps_planned)
	
	if total_jumps_planned >= 3:
		print("СПОЙЛЕР ДЛЯ ТЕСТОВ: Чувак пиздит (готовь красную кнопку).")
	else:
		print("СПОЙЛЕР ДЛЯ ТЕСТОВ: Чувак говорит правду (готовь зеленую кнопку).")
		
	# Задаем время до первого удара
	timer = randf_range(1.0, 2.5)

func _process(delta):
	if is_level_active and jumps_done < total_jumps_planned:
		timer -= delta
		if timer <= 0:
			get_tree().call_group("graph", "trigger_jump")
			jumps_done += 1
			print("Скачок ", jumps_done, " из ", total_jumps_planned)
			timer = randf_range(1.5, 3.0) # Время до следующего прыжка

func check_answer(player_chose_truth: bool):
	if not is_level_active:
		print("Уровень еще не запущен, не клацай кнопки просто так!")
		return
		
	var actual_truth = total_jumps_planned < 3
	if player_chose_truth == actual_truth:
		print("Красава, ты угадал! Уровень успешно пройден.")
	else:
		print("Проеб! Ты ошибся, он тебя наебал.")
		
	is_level_active = false
	
