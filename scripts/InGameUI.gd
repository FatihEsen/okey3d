extends CanvasLayer

@onready var score_label  := $ScorePanel/Margin/ScoreLabel
@onready var turn_label   := $TurnPanel/Margin/TurnLabel
@onready var msg_label    := $MessagePanel/Margin/MessageLabel
@onready var btn_draw     := $BottomBar/HBoxContainer/BtnDraw
@onready var btn_discard  := $BottomBar/HBoxContainer/BtnDiscard
@onready var btn_seri_diz := $BottomBar/HBoxContainer/BtnSeriDiz
@onready var btn_cift_diz := $BottomBar/HBoxContainer/BtnCiftDiz
@onready var btn_seri_ac  := $BottomBar/HBoxContainer/BtnSeriAc
@onready var btn_cift_ac  := $BottomBar/HBoxContainer/BtnCiftAc

var table: GameTable      = null
var local_rack: RackObject = null
var msg_timer: Timer      = null

func _ready() -> void:
	msg_timer = Timer.new()
	msg_timer.one_shot = true
	msg_timer.wait_time = 3.0
	msg_timer.timeout.connect(_hide_message)
	add_child(msg_timer)
	
	$MessagePanel.modulate.a = 0
	
	call_deferred("_setup")

func _setup() -> void:
	table = get_tree().get_root().find_child("Table", true, false)
	if not table: return

	if table.racks.size() > 0:
		local_rack = table.racks[0]
		local_rack.connect("logic_updated", _refresh_score)
		_refresh_score()

	table.connect("turn_changed",  _on_turn_changed)
	table.connect("tile_selected", _on_tile_selected)
	table.connect("game_message",  _show_message)
	
	_on_turn_changed(table.current_player)

# ─── Skor ────────────────────────────────────────────────────────────────────
func _refresh_score() -> void:
	if not table or not score_label: return
	var s = table.get_local_rack_score()
	var threshold = GameState.get_opening_threshold()
	score_label.text = "Seri: %d / %d   |   Çift: %d / 5" % [s.series, threshold, s.pairs]

# ─── Sıra ────────────────────────────────────────────────────────────────────
func _on_turn_changed(player_id: int) -> void:
	if not table: return
	var is_mine = (player_id == table.local_player_id)

	if turn_label:
		if is_mine:
			turn_label.text    = "▶ Sıra: Sen"
			turn_label.modulate = Color(0.3, 1.0, 0.4)
		else:
			turn_label.text    = "Sıra: Oyuncu %d" % (player_id + 1)
			turn_label.modulate = Color(1.0, 0.65, 0.3)

	if btn_draw:    btn_draw.disabled    = not is_mine
	if btn_discard: btn_discard.disabled = true
	
	# Seri Ac / Cift Ac butonlari sadece kendi sirasinda (ve tas cektikten sonra) aktif olmali
	# Ancak baslangicta 22 tasi varsa direkt acabilir/atabilir.
	_update_action_buttons(is_mine)

func _update_action_buttons(is_mine: bool) -> void:
	if not table: return
	var can_act = is_mine # && (table.has_drawn_this_turn || table.racks[0].held_tiles.size() == 22)
	btn_seri_ac.disabled = not can_act
	btn_cift_ac.disabled = not can_act

# ─── Taş seçildi ─────────────────────────────────────────────────────────────
func _on_tile_selected(_tile) -> void:
	if btn_discard:
		btn_discard.disabled = (table.current_player != table.local_player_id)

# ─── Mesajlar ────────────────────────────────────────────────────────────────
func _show_message(msg: String, error: bool) -> void:
	msg_label.text = msg
	msg_label.modulate = Color(1, 0.3, 0.3) if error else Color(1, 1, 1)
	
	var tw = create_tween()
	tw.tween_property($MessagePanel, "modulate:a", 1.0, 0.3)
	msg_timer.start()

func _hide_message() -> void:
	var tw = create_tween()
	tw.tween_property($MessagePanel, "modulate:a", 0.0, 0.5)

# ─── Butonlar ────────────────────────────────────────────────────────────────
func _on_btn_draw_pressed() -> void:
	if table: table.draw_from_deck()

func _on_btn_discard_pressed() -> void:
	if table: table.discard_selected()

func _on_btn_seri_diz_pressed() -> void:
	if local_rack: local_rack.arrange_by_series()

func _on_btn_cift_diz_pressed() -> void:
	if local_rack: local_rack.arrange_by_pairs()

func _on_btn_seri_ac_pressed() -> void:
	if table: table.open_local_series()

func _on_btn_cift_ac_pressed() -> void:
	if table: table.open_local_pairs()
