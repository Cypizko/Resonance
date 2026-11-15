extends Control

@export var music_player: AudioStreamPlayer
@export var continue_button: Button # Ссылка на кнопку Continue (можно перетащить в инспекторе)
@onready var menu_buttons = $MenuButtons
@onready var settings_panel = $SettingsPanel

@onready var settings_button = $MenuButtons/ButtonOptions
@onready var back_button = $SettingsPanel/SettingsContent/BackButton

@onready var volume_slider: HSlider = $SettingsPanel/SettingsContent/VolumeSlider
@onready var sensitivity_slider: HSlider = $SettingsPanel/SettingsContent/SensitivitySlider

@onready var volume_value: Label = $SettingsPanel/SettingsContent/VolumeValue
@onready var sensitivity_value: Label = $SettingsPanel/SettingsContent/SensitivityValue

func _ready() -> void:
	# Настройки
	settings_panel.visible = false

	volume_slider.set_value_no_signal(SettingsManager.master_volume)
	sensitivity_slider.set_value_no_signal(SettingsManager.mouse_sensitivity)

	_update_settings_labels()

	settings_button.pressed.connect(_on_settings_pressed)
	back_button.pressed.connect(_on_settings_back_pressed)

	volume_slider.value_changed.connect(_on_volume_changed)
	sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
	
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Проверяем, есть ли файл сохранения. Если нет — скрываем кнопку Continue
	if continue_button:
		continue_button.visible = FileAccess.file_exists("user://savegame.cfg")

func _on_button_mouse_entered():
	if $ButtonClickPlayer:
		$ButtonClickPlayer.stop()
		$ButtonClickPlayer.play()

func _on_button_exit_pressed():
	get_tree().quit()

# КНОПКА NEW GAME (Удаляет старый сейв, чтобы начать с чистой страницы)
func _on_button_new_game_pressed() -> void:
	if FileAccess.file_exists("user://savegame.cfg"):
		DirAccess.remove_absolute(
			ProjectSettings.globalize_path("user://savegame.cfg")
		)

	GlobalGameData.continue_requested = false

	get_tree().paused = false
	get_tree().change_scene_to_file("res://node_3d.tscn")

# КНОПКА CONTINUE (Просто загружает уровень, который подтянет сейв)
func _on_button_play_pressed() -> void:
	GlobalGameData.continue_requested = true

	get_tree().paused = false
	get_tree().change_scene_to_file("res://node_3d.tscn")
	
# Открытие настроек
func _on_settings_pressed() -> void:
	menu_buttons.visible = false
	settings_panel.visible = true


# Возврат в меню
func _on_settings_back_pressed() -> void:
	settings_panel.visible = false
	menu_buttons.visible = true


# Общая громкость
func _on_volume_changed(value: float) -> void:
	SettingsManager.set_master_volume(value)
	volume_value.text = str(roundi(value * 100)) + "%"


# Чувствительность мыши
func _on_sensitivity_changed(value: float) -> void:
	SettingsManager.set_mouse_sensitivity(value)
	sensitivity_value.text = "%.2fx" % value


# Обновление подписей при открытии настроек
func _update_settings_labels() -> void:
	volume_value.text = str(roundi(SettingsManager.master_volume * 100)) + "%"
	sensitivity_value.text = "%.2fx" % SettingsManager.mouse_sensitivity


func _on_button_new_game_mouse_entered() -> void:
	pass # Replace with function body.


func _on_button_entered() -> void:
	pass # Replace with function body.
