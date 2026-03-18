extends Node3D
class_name GameTable

@export var tile_scene: PackedScene
@export var rack_scene: PackedScene

var racks: Array[RackObject] = []
var active_tiles: Array[Node]    = []
var deck_pile_tiles: Array[Node] = []

# ─── Oyun durumu ──────────────────────────────────────────────────────────────
var current_player: int       = 0
var local_player_id: int      = 0
var game_started: bool        = false
var has_drawn_this_turn: bool = false
var selected_tile: TileObject = null

# Joker tile (gösterge + 1, aynı renk)
var okey_tile_data: OkeyTileData = null   # gerçek joker taşı verisi

# ─── Sinyal ───────────────────────────────────────────────────────────────────
signal turn_changed(player_id: int)
signal tile_discarded(data: OkeyTileData)
signal tile_selected(tile: TileObject)
signal game_message(msg: String, error: bool) # Bilgi/Hata mesajları için

# Masa durumu (açılmış taşlar)
var player_opened_sets: Array[Array] = [] 
var player_opened_pairs: Array[Array] = []

@onready var deck_manager = preload("res://scripts/DeckManager.gd").new()

# Discard positions (now per player, to the right of their rack)
var player_discard_tiles: Array[Array] = [] 
var top_discard_visual: TileObject = null 

func _ready() -> void:
	# Dizileri garantiye alalım
	player_opened_sets.clear()
	player_opened_pairs.clear()
	player_discard_tiles.clear()
	for i in range(4):
		player_opened_sets.append([])
		player_opened_pairs.append([])
		player_discard_tiles.append([])
		
	add_child(deck_manager)
	setup_racks()
	start_new_round()

# ─────────────────────────────────────────────────────────────────────────────
#  KURULUM
# ─────────────────────────────────────────────────────────────────────────────

func setup_racks() -> void:
	if not rack_scene: return
	for i in range(4):
		var pos_node = get_node_or_null("PlayerPositions/Pos" + str(i))
		if pos_node:
			var rack = rack_scene.instantiate() as RackObject
			add_child(rack)
			rack.global_transform = pos_node.global_transform
			racks.append(rack)

func start_new_round() -> void:
	# Mevcut tüm taş node'larını sahneden temizle
	for tile in active_tiles:
		if is_instance_valid(tile):
			tile.queue_free()
	active_tiles.clear()
	deck_pile_tiles.clear()
	
	for p_pile in player_discard_tiles:
		for t in p_pile: t.queue_free()
		p_pile.clear()
		
	top_discard_visual = null
	selected_tile      = null

	for rack in racks:
		rack.clear_tiles()

	deck_manager.create_deck()    # 106 taş: 2×(1-13 × 4 renk) + 2 sahte okey
	deck_manager.shuffle_deck()
	deck_manager.determine_okey() # Gösterge taşını seç

	# ── Gerçek joker verisini hesapla ──────────────────────────────────────
	_compute_okey_tile()

	# ── Gösterge taşını masaya koy ─────────────────────────────────────────
	spawn_okey_indicator()

	# ── Tüm oyunculara gerçek veri ile taş dağıt ──────────────────────────
	for id in range(4):
		var count = 22 if id == 0 else 21
		var dealt: Array[OkeyTileData] = deck_manager.deal_tiles(count)
		var face_down = (id != local_player_id)

		for d in dealt:
			var t = _create_tile(d, $CenterDeckPos.global_position, face_down)
			if not face_down:
				_connect_local_tile(t)
			racks[id].add_tile(t)

	# ── Kalan taşları yığın olarak ortaya koy ─────────────────────────────
	spawn_deck_pile()

	current_player      = 0
	has_drawn_this_turn = false
	game_started        = true
	emit_signal("turn_changed", current_player)

# ─────────────────────────────────────────────────────────────────────────────
#  GÖRSEL SPAWN
# ─────────────────────────────────────────────────────────────────────────────

## Genel tile üretici — face_down bayrağını kullanır
func _create_tile(data: OkeyTileData, pos: Vector3, face_down: bool = false) -> TileObject:
	if not tile_scene: return null
	var tile = tile_scene.instantiate() as TileObject
	add_child(tile)
	tile.global_position = pos
	active_tiles.append(tile)
	tile.setup(data, face_down)
	return tile

func spawn_okey_indicator() -> void:
	if not deck_manager.okey_indicator: return
	var ind = _create_tile(
		deck_manager.okey_indicator,
		$CenterDeckPos.global_position + Vector3(5, 0.6, -2),
		false    # yüzü yukarı
	)
	ind.freeze = true
	ind.global_rotation_degrees = Vector3(-90, 0, 0)

func spawn_deck_pile() -> void:
	var remaining = deck_manager.remaining_tiles.size()
	if remaining == 0: return

	var center          = $CenterDeckPos.global_position
	var tiles_per_stack = 5
	var stacks          = ceili(float(remaining) / tiles_per_stack)
	var stack_spacing   = 1.4
	var total_width     = (stacks - 1) * stack_spacing
	var start_x         = center.x - total_width / 2.0

	for s in range(stacks):
		var sx       = start_x + s * stack_spacing
		var in_stack = min(tiles_per_stack, remaining - s * tiles_per_stack)
		for t in range(in_stack):
			# Balyalar gerçek verilerle ama yüzü kapalı
			var data_idx = s * tiles_per_stack + t
			var data = deck_manager.remaining_tiles[data_idx]
			var pile = _create_tile(data, Vector3(sx, center.y + 0.5 + t * 0.22, center.z - 2.0), true)
			pile.freeze = true
			deck_pile_tiles.append(pile)

func _refresh_top_discard() -> void:
	# Artık her oyuncunun son attığı taşı masada bırakıyoruz.
	# "Çekilebilecek" son taş, bizden önce (soldaki) oyuncunun attığı taştır.
	# 101'de sadece bir önceki oyuncunun son taşı alınabilir.
	var shooter = (current_player - 1 + 4) % 4
	var p_pile = player_discard_tiles[shooter]
	
	if p_pile.size() > 0:
		top_discard_visual = p_pile.back()
		top_discard_visual.set_meta("is_discard_top", true)
		if not top_discard_visual.is_connected("tile_clicked", _on_discard_top_clicked):
			top_discard_visual.connect("tile_clicked", _on_discard_top_clicked)
	else:
		top_discard_visual = null

func get_discard_pos(player_id: int) -> Vector3:
	var rack = racks[player_id]
	# Istakanın sağına (rack basis X yönü) + yükseklik
	var pos = rack.global_position + (rack.global_basis.x * 12.0) - (rack.global_basis.z * 4.0)
	pos.y = 1.2
	return pos

# ─────────────────────────────────────────────────────────────────────────────
#  JOKER (OKEY) KURALI
# ─────────────────────────────────────────────────────────────────────────────

func _compute_okey_tile() -> void:
	if not deck_manager.okey_indicator:
		okey_tile_data = null
		return
	var ind = deck_manager.okey_indicator
	var joker_val = ind.value + 1
	if joker_val > 13:
		joker_val = 1
	okey_tile_data = OkeyTileData.new(joker_val, ind.color, false, -99)

## Bir taş gerçek joker mi? (sahte okey değil, göstergenin bir üstü)
func is_tile_okey(data: OkeyTileData) -> bool:
	if not okey_tile_data: return false
	return data.value == okey_tile_data.value and data.color == okey_tile_data.color and not data.is_joker

# ─────────────────────────────────────────────────────────────────────────────
#  OYUN AKIŞI — LOKAL OYUNCU
# ─────────────────────────────────────────────────────────────────────────────

func draw_from_deck() -> void:
	if not game_started: return
	if current_player != local_player_id: return
	if has_drawn_this_turn:
		print("Bu turda zaten taş çektin!")
		return

	var data = deck_manager.draw_tile()
	if not data:
		print("Deste bitti!")
		return

	var tile = _create_tile(data, $CenterDeckPos.global_position + Vector3(0, 2, 0), false)
	_connect_local_tile(tile)
	racks[local_player_id].add_tile(tile)
	has_drawn_this_turn = true

	# Yığından bir taş kaldır (görsel)
	if deck_pile_tiles.size() > 0:
		var removed = deck_pile_tiles.pop_back()
		removed.queue_free()
		active_tiles.erase(removed)

func _on_discard_top_clicked(_tile: TileObject) -> void:
	if not game_started: return
	if current_player != local_player_id: return
	if has_drawn_this_turn:
		print("Bu turda zaten taş çektin!")
		return

	var shooter = (current_player - 1 + 4) % 4
	var shooter_pile = player_discard_tiles[shooter]
	if shooter_pile.is_empty(): return
	
	var data = shooter_pile.back().data
	shooter_pile.pop_back().queue_free() # Görseli sil, yeni ıstakada başka bir tane yaratacağız

	var new_tile = _create_tile(data, get_discard_pos(shooter), false)
	_connect_local_tile(new_tile)
	racks[local_player_id].add_tile(new_tile)
	has_drawn_this_turn = true
	_refresh_top_discard()

func select_tile(tile: TileObject) -> void:
	if selected_tile and selected_tile != tile:
		selected_tile.set_selected(false)
	selected_tile = tile
	tile.set_selected(true)
	emit_signal("tile_selected", tile)

func discard_selected() -> void:
	if not game_started: return
	if current_player != local_player_id: return
	if not selected_tile: return

	# İlk tur: player 0, 22 taşla başlar → çekmeden atabilir
	var is_first_discard_turn = (not has_drawn_this_turn and racks[local_player_id].held_tiles.size() == 22)
	if not has_drawn_this_turn and not is_first_discard_turn:
		print("Önce taş çek!")
		return

	_do_discard(selected_tile)
	selected_tile = null

func _do_discard(tile: TileObject) -> void:
	racks[local_player_id].remove_tile(tile)
	tile.set_selected(false)
	deck_manager.discard_tile(tile.data)

	tile.freeze = true
	var d_pos = get_discard_pos(local_player_id)
	var stack_offset = Vector3(0, 0.05 * player_discard_tiles[local_player_id].size(), 0)
	tile.global_position = d_pos + stack_offset
	tile.global_rotation_degrees = Vector3(-90, racks[local_player_id].global_rotation_degrees.y, 0)

	player_discard_tiles[local_player_id].append(tile)
	emit_signal("tile_discarded", tile.data)
	_refresh_top_discard()

	has_drawn_this_turn = false
	_advance_turn()

func _connect_local_tile(tile: TileObject) -> void:
	if not tile.is_connected("tile_clicked", _on_local_tile_clicked):
		tile.connect("tile_clicked", _on_local_tile_clicked)

func _on_local_tile_clicked(tile: TileObject) -> void:
	if current_player != local_player_id: return
	select_tile(tile)

# ─────────────────────────────────────────────────────────────────────────────
#  SIRA GEÇİŞ & YAPAY ZEKA
# ─────────────────────────────────────────────────────────────────────────────

func _advance_turn() -> void:
	current_player = (current_player + 1) % 4
	GameState.current_player_id = current_player
	emit_signal("turn_changed", current_player)
	if current_player != local_player_id:
		_run_ai_turn()

func _run_ai_turn() -> void:
	await get_tree().create_timer(1.2).timeout
	if current_player == local_player_id: return

	var data = deck_manager.draw_tile()
	if not data: return

	if deck_pile_tiles.size() > 0:
		var removed = deck_pile_tiles.pop_back()
		if removed:
			removed.queue_free()
			active_tiles.erase(removed)

	# AI görsel olarak çektiği taşı atar
	var t = _create_tile(data, get_node("CenterDeckPos").global_position, false)
	t.freeze = true
	t.global_rotation_degrees = Vector3(-90, 0, 0)
	
	await get_tree().create_timer(0.4).timeout
	
	var d_pos = get_discard_pos(current_player)
	var stack_offset = Vector3(0, 0.05 * player_discard_tiles[current_player].size(), 0)
	t.global_position = d_pos + stack_offset
	t.global_rotation_degrees = Vector3(-90, racks[current_player].global_rotation_degrees.y, 0)
	
	player_discard_tiles[current_player].append(t)
	deck_manager.discard_tile(data)
	_refresh_top_discard()

	await get_tree().create_timer(0.5).timeout
	_advance_turn()

# ─────────────────────────────────────────────────────────────────────────────
#  EL AÇMA (SERİ)
# ─────────────────────────────────────────────────────────────────────────────

func open_local_series() -> void:
	if not game_started or current_player != local_player_id: return
	if not has_drawn_this_turn and racks[local_player_id].held_tiles.size() != 22:
		emit_signal("game_message", "Önce taş çekmelisin!", true)
		return

	var rack = racks[local_player_id]
	var sets = rack.get_openable_sets(okey_tile_data)
	
	# Toplam puanı hesapla
	var total = 0
	for s in sets:
		var data_array: Array[OkeyTileData] = []
		for t in s: data_array.append(t.data)
		total += RuleEngine.get_group_sum(data_array, okey_tile_data)
	
	var threshold = GameState.get_opening_threshold()
	
	if total >= threshold:
		# Başarılı açış
		for s in sets:
			for t in s:
				rack.remove_tile(t)
			player_opened_sets[local_player_id].append(s)
			_move_set_to_table(local_player_id, s, player_opened_sets[local_player_id].size() - 1)
		
		# Katlamalı ise barajı güncelle
		if GameState.game_mode == Constants.GameMode.KATLAMALI:
			GameState.register_opening(total)
			
		emit_signal("game_message", "%d puanla açtın!" % total, false)
	else:
		# Başarısız açış — ceza
		emit_signal("game_message", "Hatalı Açış! %d puan açamazsın (Baraj: %d)" % [total, threshold], true)
		# 101 Ceza (Uygulama: ekrana yazı, gerçek skor sisteminde scores[id] += 101)
		GameState.scores[local_player_id] += 101

# ─────────────────────────────────────────────────────────────────────────────
#  EL AÇMA (ÇİFT)
# ─────────────────────────────────────────────────────────────────────────────

func open_local_pairs() -> void:
	if not game_started or current_player != local_player_id: return
	var rack = racks[local_player_id]
	var pairs = rack.get_openable_pairs(okey_tile_data)
	
	# Çift açma barajı genelde 5 çifttir (ya da katlamalıda artar)
	var threshold = Constants.MIN_PAIRS_FOR_OPENING
	if GameState.game_mode == Constants.GameMode.KATLAMALI:
		# Katlamalıda çift barajı nasıl artıyor? Genelde +1 çift.
		# Şimdilik basitçe 5 çift diyelim, katlamalı puan üzerinden gider.
		pass
		
	if pairs.size() >= threshold:
		for p in pairs:
			for t in p:
				rack.remove_tile(t)
			player_opened_pairs[local_player_id].append(p)
			_move_pair_to_table(local_player_id, p, player_opened_pairs[local_player_id].size() - 1)
		emit_signal("game_message", "%d çiftle açtın!" % pairs.size(), false)
	else:
		emit_signal("game_message", "En az %d çift gerekli!" % threshold, true)

# ─────────────────────────────────────────────────────────────────────────────
#  GÖRSEL TAŞ HAREKETİ (MASAYA)
# ─────────────────────────────────────────────────────────────────────────────

func _move_set_to_table(player_id: int, tiles: Array, set_index: int) -> void:
	var base_pos: Vector3
	var direction: Vector3
	var spread: Vector3
	
	# Player 0 (Yerel) için tablo konumu (Basit yaklaşım)
	if player_id == 0:
		base_pos = Vector3(-8 + (set_index % 3) * 6, 1.2, 8 - floor(set_index / 3.0) * 4)
		direction = Vector3(1, 0, 0) # Yan yana diz
		spread = Vector3(1.1, 0, 0)
	
	for i in range(tiles.size()):
		var t = tiles[i]
		var target = base_pos + spread * i
		t.freeze = true
		var tween = get_tree().create_tween().set_parallel(true)
		tween.tween_property(t, "global_position", target, 0.4).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(t, "global_rotation_degrees", Vector3(-90, 0, 0), 0.4)

func _move_pair_to_table(player_id: int, tiles: Array, pair_index: int) -> void:
	if player_id == 0:
		var base_pos = Vector3(-8 + (pair_index % 5) * 3, 1.2, 4 - floor(pair_index / 5.0) * 3)
		for i in range(tiles.size()):
			var t = tiles[i]
			var target = base_pos + Vector3(0, 0, i * 1.2)
			t.freeze = true
			var tween = get_tree().create_tween().set_parallel(true)
			tween.tween_property(t, "global_position", target, 0.4)
			tween.tween_property(t, "global_rotation_degrees", Vector3(-90, 0, 0), 0.4)

func get_local_rack_score() -> Dictionary:
	if racks.is_empty(): return {"series": 0, "pairs": 0}
	return racks[local_player_id].calculate_current_score(okey_tile_data)
