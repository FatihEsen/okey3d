extends Control

@onready var status_label: Label = $VBoxContainer/status_label
@onready var btn_start: Button = $VBoxContainer/btn_start
@onready var btn_back: Button = $VBoxContainer/btn_back

const GAME_SCENE_PATH := "res://scenes/GameScene.tscn"

func _ready() -> void:
	btn_start.pressed.connect(_on_start_pressed)
	btn_back.pressed.connect(_on_back_pressed)

	if Multiplayer.multiplayer_peer == null:
		status_label.text = "Offline / Local oyun"
		btn_start.disabled = false
	elif Multiplayer.is_server():
		status_label.text = "Host - oyuncular bekleniyor..."
		btn_start.disabled = false
	else:
		status_label.text = "Client - host'u bekliyor..."
		btn_start.disabled = true

func _on_start_pressed() -> void:
	if GameState.is_local_server():
		get_tree().change_scene_to_file(GAME_SCENE_PATH)

func _on_back_pressed() -> void:
	MultiplayerManager.stop_network()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

