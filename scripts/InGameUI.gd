extends CanvasLayer

@onready var score_label  := find_child("ScoreLabel", true, false)
@onready var turn_label   := find_child("TurnLabel", true, false)
@onready var msg_label    := find_child("MessageLabel", true, false)
@onready var btn_draw     := find_child("BtnDraw", true, false)
@onready var btn_discard  := find_child("BtnDiscard", true, false)
@onready var btn_seri_diz := find_child("BtnSeriDiz", true, false)
@onready var btn_cift_diz := find_child("BtnCiftDiz", true, false)
@onready var btn_seri_ac  := find_child("BtnSeriAc", true, false)
@onready var btn_cift_ac  := find_child("BtnCiftAc", true, false)

var table: GameTable      = null
var local_rack: RackObject = null
var msg_timer: Timer      = null
var remaining_label: Label = null

func _ready() -> void:
	msg_timer = Timer.new()
	msg_timer.one_shot = true
	msg_timer.wait_time = 3.0
	msg_timer.timeout.connect(_hide_message)
	add_child(msg_timer)
	
	# Kalan taş sayısı için label ekleyelim
	remaining_label = Label.new()
	remaining_label.text = "Kalan Taş:"
	remaining_label.add_theme_font_size_override("font_size", 22)
	remaining_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	remaining_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	remaining_label.position = Vector2(-250, 20) # Sağ üstten biraz içeride
	add_child(remaining_label)
	
	$MessagePanel.modulate.a = 0
	
	# Sinyalleri bağla (Eğer tscn'de koptuysa kodla garantiye alalım)
	if btn_draw:    btn_draw.pressed.connect(_on_btn_draw_pressed)
	if btn_discard: btn_discard.pressed.connect(_on_btn_discard_pressed)
	if btn_seri_diz: btn_seri_diz.pressed.connect(_on_btn_seri_diz_pressed)
	if btn_cift_diz: btn_cift_diz.pressed.connect(_on_btn_cift_diz_pressed)
	if btn_seri_ac:  btn_seri_ac.pressed.connect(_on_btn_seri_ac_pressed)
	if btn_cift_ac:  btn_cift_ac.pressed.connect(_on_btn_cift_ac_pressed)

	call_deferred("_setup")

func _setup() -> void:
	table = get_tree().get_root().find_child("Table", true, false)
	if not table: 
		print("ERROR: Table not found in UI!")
		return

	if table.racks.size() > 0:
		local_rack = table.racks[0]
		if not local_rack.is_connected("logic_updated", _refresh_score):
			local_rack.connect("logic_updated", _refresh_score)
		_refresh_score()

	if not table.is_connected("turn_changed", _on_turn_changed):
		table.connect("turn_changed",  _on_turn_changed)
	if not table.is_connected("tile_selected", _on_tile_selected):
		table.connect("tile_selected", _on_tile_selected)
	if not table.is_connected("game_message", _show_message):
		table.connect("game_message",  _show_message)
	if not table.is_connected("game_over", _on_game_over):
		table.connect("game_over", _on_game_over)
	
	print("UI: Setup complete. Current player: ", table.current_player)
	_on_turn_changed(table.current_player)

# ─── Skor ────────────────────────────────────────────────────────────────────
func _process(_delta: float) -> void:
	if table and table.deck_manager and remaining_label:
		remaining_label.text = "Kalan Taş: %d" % table.deck_manager.remaining_tiles.size()

func _refresh_score() -> void:
	if not table or not score_label: return
	var s = table.get_local_rack_score()
	var threshold = GameState.get_opening_threshold()
	score_label.text = "Seri: %d / %d   |   Çift: %d / 5" % [s.series, threshold, s.pairs]

# ─── Sıra ────────────────────────────────────────────────────────────────────
func _on_turn_changed(player_id: int) -> void:
	if not table: return
	var is_mine = (player_id == table.local_player_id)
	print("UI: Turn changed to ", player_id, " (Mine: ", is_mine, ")")

	# Table/racks henüz hazır değilken _setup çalıştıysa local_rack null kalabilir.
	# Her turda tekrar doğru rack'i yakalayalım.
	if table.racks.size() > table.local_player_id:
		local_rack = table.racks[table.local_player_id]

	if turn_label:
		if is_mine:
			turn_label.text    = "▶ Sıra: Sen"
			turn_label.modulate = Color(0.3, 1.0, 0.4)
		else:
			turn_label.text    = "Sıra: Oyuncu %d" % (player_id + 1)
			turn_label.modulate = Color(1.0, 0.65, 0.3)

	if btn_draw:    btn_draw.disabled    = not is_mine
	if btn_discard: btn_discard.disabled = (not is_mine or table.selected_tile == null)
	
	_update_action_buttons(is_mine)

func _update_action_buttons(is_mine: bool) -> void:
	if not table: return
	var can_act = is_mine
	if btn_seri_ac: btn_seri_ac.disabled = not can_act
	if btn_cift_ac: btn_cift_ac.disabled = not can_act

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

# ─── Oyun Sonu ──────────────────────────────────────────────────────────────
func _on_game_over(scores: Dictionary) -> void:
	var bg = Panel.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.modulate = Color(0, 0, 0, 0.7)
	add_child(bg)
	
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_child(vbox)
	panel.add_child(margin)
	
	var header = Label.new()
	header.text = "OYUN BİTTİ"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 32)
	header.modulate = Color(1, 0.8, 0.2)
	vbox.add_child(header)
	
	var sep = HSeparator.new()
	vbox.add_child(sep)
	
	for i in range(4):
		var lbl = Label.new()
		var is_me = (table and i == table.local_player_id)
		lbl.text = "Oyuncu %d %s: Seri Puanı: %d / Çift: %d" % [i+1, "(Sen)" if is_me else "", scores[i].series, scores[i].pairs]
		if is_me: lbl.modulate = Color(0.4, 1.0, 0.4)
		lbl.add_theme_font_size_override("font_size", 20)
		vbox.add_child(lbl)
		
	var sep2 = HSeparator.new()
	vbox.add_child(sep2)
	
	var btn_exit = Button.new()
	btn_exit.text = "Ana Menüye Dön"
	btn_exit.add_theme_font_size_override("font_size", 24)
	btn_exit.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))
	vbox.add_child(btn_exit)


# ─── Butonlar ────────────────────────────────────────────────────────────────
func _on_btn_draw_pressed() -> void:
	print("UI: Draw pressed")
	if table: table.draw_from_deck()

func _on_btn_discard_pressed() -> void:
	print("UI: Discard pressed")
	if table: table.discard_selected()

func _on_btn_seri_diz_pressed() -> void:
	if not local_rack and table and table.racks.size() > table.local_player_id:
		local_rack = table.racks[table.local_player_id]
	if local_rack: local_rack.arrange_by_series()

func _on_btn_cift_diz_pressed() -> void:
	if not local_rack and table and table.racks.size() > table.local_player_id:
		local_rack = table.racks[table.local_player_id]
	if local_rack: local_rack.arrange_by_pairs()

func _on_btn_seri_ac_pressed() -> void:
	if table: table.open_local_series()

func _on_btn_cift_ac_pressed() -> void:
	if table: table.open_local_pairs()
