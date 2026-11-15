extends Area3D

@onready var anim_player = $AnimationPlayer # Поменяй путь, если плеер лежит глубже

func press():
	print("Телефон нажат, запускаем шарманку!")
	if anim_player:
		anim_player.play("lift") # Впиши точное название
	get_tree().call_group("level", "start_level")
