extends Node

var hands: Dictionary          = {}
var table_stones: Array        = []
var current_player_id: int     = 0
var okey: int                  = -1
var scores: Dictionary         = {}
var game_phase: String         = "lobby"

# ─── Oyun modu ────────────────────────────────────────────────────────────────
var game_mode: int             = Constants.GameMode.KATLAMASIZ
var last_opening_score: int    = 0   # Katlamalı için son açılan puan

const PLAYER_IDS               := [0, 1, 2, 3]

signal state_changed(state: Dictionary)

func _ready() -> void:
	reset_state()

func reset_state() -> void:
	hands.clear()
	table_stones.clear()
	scores.clear()
	for pid in PLAYER_IDS:
		hands[pid]  = []
		scores[pid] = 0
	current_player_id  = 0
	okey               = -1
	game_phase         = "lobby"
	last_opening_score = 0
	_emit_state()

## Aktif moda göre açma baraji döndür
func get_opening_threshold() -> int:
	match game_mode:
		Constants.GameMode.KATLAMASIZ:
			return Constants.MIN_OPENING_SUM
		Constants.GameMode.KATLAMALI:
			return last_opening_score + 1 if last_opening_score > 0 else Constants.MIN_OPENING_SUM
	return Constants.MIN_OPENING_SUM

## Birisi açınca çağır — katlamalı için skoru günceller
func register_opening(score: int) -> void:
	last_opening_score = score

func to_dict() -> Dictionary:
	return {
		"hands":             hands,
		"table_stones":      table_stones,
		"current_player_id": current_player_id,
		"okey":              okey,
		"scores":            scores,
		"game_phase":        game_phase,
		"game_mode":         game_mode,
		"last_opening":      last_opening_score,
	}

func from_dict(state: Dictionary) -> void:
	hands              = state.get("hands",             {})
	table_stones       = state.get("table_stones",      [])
	current_player_id  = state.get("current_player_id", 0)
	okey               = state.get("okey",              -1)
	scores             = state.get("scores",            {})
	game_phase         = state.get("game_phase",        "lobby")
	game_mode          = state.get("game_mode",         Constants.GameMode.KATLAMASIZ)
	last_opening_score = state.get("last_opening",      0)
	_emit_state()

func _emit_state() -> void:
	emit_signal("state_changed", to_dict())

func is_local_server() -> bool:
	if multiplayer.multiplayer_peer == null:
		return true
	return multiplayer.is_server()

func next_turn() -> void:
	var idx = PLAYER_IDS.find(current_player_id)
	if idx == -1: idx = 0
	idx = (idx + 1) % PLAYER_IDS.size()
	current_player_id = PLAYER_IDS[idx]
	_emit_state()
