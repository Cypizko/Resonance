extends Node

const SAVE_PATH = "user://savegame.cfg"

var is_game_active: bool = false
var continue_requested: bool = false


# Сохранение прогресса
func save_game(current_level: int, mistakes: int, intro_played: bool) -> void:
	var config = ConfigFile.new()

	config.set_value("GameData", "current_level", current_level)
	config.set_value("GameData", "mistakes", mistakes)
	config.set_value("GameData", "intro_played", intro_played)

	var err = config.save(SAVE_PATH)

	if err != OK:
		print("Помилка збереження!")


# Загрузка прогресса
func load_game() -> Dictionary:
	var config = ConfigFile.new()
	var err = config.load(SAVE_PATH)

	if err != OK:
		return {}

	return {
		"current_level": config.get_value("GameData", "current_level", 1),
		"mistakes": config.get_value("GameData", "mistakes", 0),
		"intro_played": config.get_value("GameData", "intro_played", false)
	}
