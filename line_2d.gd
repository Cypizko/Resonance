extends Line2D

var speed = 150.0
var base_y = 256.0
var is_lying = false
var jump_count = 0
var is_currently_spiking = false
var lie_timer = 0.0

func _process(delta):
	for i in range(get_point_count()):
		var current_pos = get_point_position(i)
		current_pos.x -= speed * delta
		set_point_position(i, current_pos)
		
	if get_point_count() > 0 and get_point_position(0).x < 0:
		remove_point(0)
		
	var right_edge = 512.0
	var noise = randf_range(-10.0, 10.0)
	
	if Input.is_key_pressed(KEY_SPACE) and lie_timer <= 0.0:
		lie_timer = randf_range(0.15, 0.4)
		
	if lie_timer > 0.0:
		lie_timer -= delta
		is_lying = true
	else:
		is_lying = false
	
	if is_lying:
		var jump = randf_range(160.0, 220.0)
		if randi() % 2 == 0:
			noise = jump
		else:
			noise = -jump
	else:
		if randf() < 0.03:
			var fake_jump = randf_range(70.0, 120.0)
			if randi() % 2 == 0:
				noise = fake_jump
			else:
				noise = -fake_jump
				
	if abs(noise) >= 150.0:
		if not is_currently_spiking:
			jump_count += 1
			print("Зафиксирован скачок за линию! Всего: ", jump_count)
			is_currently_spiking = true
	else:
		is_currently_spiking = false
				
	add_point(Vector2(right_edge, base_y + noise))
	
func trigger_jump():
	lie_timer = randf_range(0.2, 0.5)
