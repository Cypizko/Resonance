extends Area3D

# Ссылки на три аудио-плеера (убедитесь, что они есть как дочерние узлы)
@onready var ring_player: AudioStreamPlayer3D = $SoundRing
@onready var pickup_player: AudioStreamPlayer3D = $SoundPickup
@onready var hangup_player: AudioStreamPlayer3D = $SoundHangup

var original_position: Vector3
var original_rotation: Vector3
var is_picked_up: bool = false

func _ready() -> void:
	if not is_in_group("phone"):
		add_to_group("phone")
	
	# Запоминаем исходное положение телефона на столе
	original_position = position
	original_rotation = rotation

# Вызывается из level_manager.gd для начала звонка
func start_ringing():
	if ring_player and ring_player.stream and not is_picked_up:
		if not ring_player.playing:
			ring_player.play()
	print("Телефон дзвонить...")

# Когда игрок кликает на телефон
func press():
	print("Телефон натиснуто!")
	
	# 1. Останавливаем звонок
	if ring_player and ring_player.playing:
		ring_player.stop()
		
	# 2. Воспроизводим звук поднятия трубки
	if pickup_player and pickup_player.stream:
		pickup_player.play()
		
	# 3. Плавный подъем трубки через Tween (замена AnimationPlayer)
	is_picked_up = !is_picked_up
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	if is_picked_up:
		# Сдвигаем трубку немного вверх и к игроку (можете настроить цифры под себя)
		tween.tween_property(self, "position", original_position + Vector3(0, 0.08, 0.05), 0.25)
		tween.parallel().tween_property(self, "rotation", original_rotation + Vector3(deg_to_rad(-20), 0, 0), 0.25)
	
	# 4. Сообщаем LevelManager, что трубку взяли
	get_tree().call_group("level_manager", "answer_phone")

# Функция на случай, если нужно положить трубку обратно
func hang_up():
	is_picked_up = false
	if hangup_player and hangup_player.stream:
		hangup_player.play()
		
	var tween = create_tween()
	tween.tween_property(self, "position", original_position, 0.25)
	tween.parallel().tween_property(self, "rotation", original_rotation, 0.25)
