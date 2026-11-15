extends Node

const SETTINGS_PATH = "user://settings.cfg"

var master_volume: float = 0.8
var mouse_sensitivity: float = 1.0


func _ready() -> void:
	load_settings()
	apply_volume()


# Общая громкость
func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	apply_volume()
	save_settings()


# Чувствительность мыши
func set_mouse_sensitivity(value: float) -> void:
	mouse_sensitivity = clampf(value, 0.1, 3.0)
	save_settings()


# Применение громкости
func apply_volume() -> void:
	var bus = AudioServer.get_bus_index("Master")

	if bus != -1:
		AudioServer.set_bus_volume_db(
			bus,
			linear_to_db(maxf(master_volume, 0.0001))
		)


# Сохранение параметров
func save_settings() -> void:
	var config = ConfigFile.new()

	config.set_value("Settings", "master_volume", master_volume)
	config.set_value("Settings", "mouse_sensitivity", mouse_sensitivity)

	var error = config.save(SETTINGS_PATH)

	if error != OK:
		print("Failed to save settings: ", error)


# Загрузка параметров
func load_settings() -> void:
	var config = ConfigFile.new()

	if config.load(SETTINGS_PATH) == OK:
		master_volume = clampf(
			float(config.get_value("Settings", "master_volume", 0.8)),
			0.0, 1.0
		)

		mouse_sensitivity = clampf(
			float(config.get_value("Settings", "mouse_sensitivity", 1.0)),
			0.1, 3.0
		)
