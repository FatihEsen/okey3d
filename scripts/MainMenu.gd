extends Control

@onready var btn_offline: Button = $VBoxContainer/btn_offline
@onready var btn_host: Button = $VBoxContainer/btn_host
@onready var btn_join: Button = $VBoxContainer/btn_join
@onready var btn_exit: Button = $VBoxContainer/btn_exit

@onready var join_dialog: Window = $JoinDialog
@onready var ip_field: LineEdit = $JoinDialog/ip_field
@onready var port_field: LineEdit = $JoinDialog/port_field
@onready var btn_join_confirm: Button = $JoinDialog/btn_join_confirm

const GAME_SCENE_PATH := "res://scenes/GameScene.tscn"
const LOBBY_SCENE_PATH := "res://scenes/Lobby.tscn"

func _ready() -> void:
	btn_offline.pressed.connect(_on_offline_pressed)
	btn_host.pressed.connect(_on_host_pressed)
	btn_join.pressed.connect(_on_join_pressed)
	btn_exit.pressed.connect(_on_exit_pressed)
	btn_join_confirm.pressed.connect(_on_join_confirm_pressed)

	ip_field.text = "127.0.0.1"
	port_field.text = str(MultiplayerManager.DEFAULT_PORT)

func _on_offline_pressed() -> void:
	MultiplayerManager.stop_network()
	GameState.reset_state()
	GameState.game_phase = "lobby"
	_change_scene(GAME_SCENE_PATH)

func _on_host_pressed() -> void:
	MultiplayerManager.stop_network()
	MultiplayerManager.create_server(MultiplayerManager.DEFAULT_PORT)
	GameState.reset_state()
	GameState.game_phase = "lobby"
	_change_scene(LOBBY_SCENE_PATH)

func _on_join_pressed() -> void:
	join_dialog.popup_centered()

func _on_join_confirm_pressed() -> void:
	var ip := ip_field.text.strip_edges()
	var port := int(port_field.text)
	if ip == "":
		ip = "127.0.0.1"
	MultiplayerManager.stop_network()
	MultiplayerManager.create_client(ip, port)
	GameState.reset_state()
	GameState.game_phase = "lobby"
	join_dialog.hide()
	_change_scene(LOBBY_SCENE_PATH)

func _on_exit_pressed() -> void:
	get_tree().quit()

func _change_scene(path: String) -> void:
	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("Failed to change scene to %s: %s" % [path, err])

