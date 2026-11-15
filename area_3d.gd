extends Area3D

@export var target_node: Node3D 
# Перетащите сюда узел RulesUI из панели сцены прямо в инспекторе!
@export var rules_ui: CanvasLayer 

var original_transform: Transform3D
var is_picked_up: bool = false

func _ready() -> void:
	if not target_node:
		target_node = get_parent()
	
	if target_node:
		original_transform = target_node.global_transform
	
	# Скрываем правила при старте игры, когда листок лежит на столе
	if rules_ui:
		rules_ui.visible = false

func toggle_inspect() -> void:
	var current_camera = get_viewport().get_camera_3d()
	
	if not current_camera or not target_node:
		print("Помилка: не знайдено камеру або вузол листка!")
		return

	is_picked_up = !is_picked_up
	
	# Передаємо камері стан огляду та посилання на себе (self)
	if current_camera.has_method("set_inspecting"):
		current_camera.set_inspecting(is_picked_up, self)

	# Включаем или выключаем видимость интерфейса с правилами
	if rules_ui:
		rules_ui.visible = is_picked_up

	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	if is_picked_up:
		# Фіксуємо планшет прямо перед камерою в зафіксованому положенні
		var target_pos = current_camera.global_position - current_camera.global_transform.basis.z * 0.5 + Vector3(0, 0.05, 0)
		var target_rot = current_camera.global_rotation + Vector3(deg_to_rad(90), 0, 0)
		
		tween.tween_property(target_node, "global_position", target_pos, 0.4)
		tween.parallel().tween_property(target_node, "global_rotation", target_rot, 0.4)
		
		print("Листок піднято до екрана, правила показано")
	else:
		# Повертаємо назад на стіл
		tween.tween_property(target_node, "global_transform", original_transform, 0.4)
		
		print("Листок покладено на стіл, правила сховано")
