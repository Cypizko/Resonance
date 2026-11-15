extends Area3D

@export var button_type: String = "ПРАВДА" # Тут в инспекторе напишешь ПРАВДА или ЛОЖЬ
@export var target_node: Node3D # Сюда перетащи саму модельку кнопки (меш), которая должна двигаться

var original_y: float
var is_pressing: bool = false

func _ready():
	# Если ты не назначил меш вручную, скрипт возьмет родителя, как у тебя в примере
	if not target_node:
		target_node = get_parent()
		
	if target_node:
		original_y = target_node.position.y

# Эту функцию тебе нужно вызывать из твоего скрипта взаимодействия (луча), 
# точно так же, как ты вызываешь toggle_inspect() для листка.
func press():
	# Если кнопка уже нажимается или нет модельки, ничего не делаем
	if is_pressing or not target_node:
		return
		
	is_pressing = true
	print("Вызвана функция: ", button_type)
	
	var tween = create_tween()
	# В 3D расстояния маленькие, поэтому опускаем на 0.05 единиц, а не на пиксели
	tween.tween_property(target_node, "position:y", original_y - 0.05, 0.1)
	tween.tween_property(target_node, "position:y", original_y, 0.1)
	
	# Ждем, пока анимация закончится, чтобы нельзя было заспамить клики
	await tween.finished
	is_pressing = false
