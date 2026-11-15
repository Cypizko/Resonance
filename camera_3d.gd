extends Camera3D

# Чутливість руху миші при огляді кімнати
@export var sensitivity: float = 0.003

# Посилання на наш промінь (RayCast3D)
@onready var interaction_ray: RayCast3D = $InteractionRay 

# Змінна стану: чи розглядаємо ми зараз предмет
var is_inspecting: bool = false

# Зберігаємо посилання на останній піднятий об'єкт, щоб знати, що опускати
var current_inspected_object: Node = null

func _ready() -> void:
	# Захоплюємо курсор у центр екрана
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	# 1. Якщо ми розглядаємо предмет — дозволяємо клікнути ще раз або натиснути ESC, щоб покласти його назад
	if is_inspecting:
		if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) \
		   or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
			
			# Якщо у нас є збережений об'єкт, викликаємо у нього метод вимкнення огляду
			if current_inspected_object and current_inspected_object.has_method("toggle_inspect"):
				current_inspected_object.toggle_inspect()
		return

	# 2. Звичайний режим: обробка руху миші для огляду кімнати
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * sensitivity)
		
		var current_rotation = rotation
		current_rotation.x -= event.relative.y * sensitivity
		current_rotation.x = clamp(current_rotation.x, deg_to_rad(-70), deg_to_rad(70))
		rotation = current_rotation

	# 3. Клік лівою кнопкою миші у звичайному режимі: намагаємося підняти предмет, на який дивиться прицел
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if interaction_ray and interaction_ray.is_colliding():
			var collider = interaction_ray.get_collider()
			
			if collider:
				if collider.has_method("toggle_inspect"):
					current_inspected_object = collider
					collider.toggle_inspect()
				elif collider.get_parent() and collider.get_parent().has_method("toggle_inspect"):
					current_inspected_object = collider.get_parent()
					current_inspected_object.toggle_inspect()

# Цю функцію викликає сам листок, коли змінює свій стан
func set_inspecting(inspecting: bool, obj: Node = null) -> void:
	is_inspecting = inspecting
	if not inspecting:
		current_inspected_object = null
