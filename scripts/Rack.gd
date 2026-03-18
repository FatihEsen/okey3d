extends StaticBody3D
class_name RackObject

@export var max_tiles: int = 22
@export var spacing: float = 1.02

var held_tiles: Array[TileObject] = []
var slots: Array[Vector3] = []
var slot_items: Array[TileObject] = []

signal logic_updated()

func _ready() -> void:
	slots.clear()
	var row_capacity = 16
	var row_spacing = 1.1 
	var col_spacing = 1.2 
	
	for row in range(2):
		var total_width = (row_capacity - 1) * row_spacing
		var start_x = -total_width / 2.0
		var z_offset = (0.5 - row) * col_spacing
		var y_offset = 1.0 + (row * 0.5) 
		
		for col in range(row_capacity):
			slots.append(Vector3(start_x + (col * row_spacing), y_offset, z_offset))

	slot_items.resize(slots.size())
	slot_items.fill(null)

func clear_tiles() -> void:
	held_tiles.clear()
	for i in range(slot_items.size()):
		slot_items[i] = null
	emit_signal("logic_updated")

func add_tile(tile: TileObject) -> bool:
	if held_tiles.size() >= slots.size():
		return false
	
	held_tiles.append(tile)
	if not tile.is_connected("drag_started", _on_tile_drag_started):
		tile.connect("drag_started", _on_tile_drag_started)
		tile.connect("drag_ended", _on_tile_drag_ended)

	var slot_index = find_empty_slot()
	if slot_index != -1:
		slot_items[slot_index] = tile
		snap_tile_to_slot(tile, slot_index)
	emit_signal("logic_updated")
	return true

func remove_tile(tile: TileObject) -> void:
	held_tiles.erase(tile)
	var idx = slot_items.find(tile)
	if idx != -1:
		slot_items[idx] = null
	emit_signal("logic_updated")

func find_empty_slot() -> int:
	return slot_items.find(null)

func snap_tile_to_slot(tile: TileObject, slot_index: int) -> void:
	if slot_index < 0 or slot_index >= slots.size(): return
	var target_pos = global_position + (global_basis * slots[slot_index])
	tile.freeze = true
	var tween = get_tree().create_tween().set_parallel(true)
	tween.tween_property(tile, "global_position", target_pos, 0.2)
	
	var tilted_basis: Basis
	if tile.is_face_down:
		var flipped = global_basis.rotated(global_basis.y, deg_to_rad(180))
		tilted_basis = flipped.rotated(flipped.x, deg_to_rad(-15))
	else:
		tilted_basis = global_basis.rotated(global_basis.x, deg_to_rad(-15))
	
	tween.tween_property(tile, "global_basis", tilted_basis, 0.2)

# ─────────────────────────────────────────────────────────────────────────────
#  AKILLI DİZME (SERİ)
# ─────────────────────────────────────────────────────────────────────────────

func arrange_by_series() -> void:
	if held_tiles.is_empty(): return
	
	# Tablodan okey_tile bilgisini al (RuleEngine için)
	var table = get_tree().get_root().find_child("Table", true, false)
	var okey_tile = table.okey_tile_data if table else null
	
	var tiles = held_tiles.duplicate()
	var final_arrangement: Array[Array] = [] # Array[Array[TileObject]]
	
	# 1. Tüm olası perleri (run ve group) bul
	var possible_sets = _find_all_valid_sets(tiles, okey_tile)
	
	# 2. En iyi kombinasyonu seç (Greedy: En uzun/yüksek puanlı olanı seç ve taşları kullanılmış say)
	var remaining_tiles = tiles.duplicate()
	possible_sets.sort_custom(func(a, b):
		return a.size() > b.size() # Önce uzun takımları al
	)
	
	for s in possible_sets:
		# Bu set içindeki tüm taşlar hala "kullanılmamış" mı?
		var all_available = true
		for t in s:
			if t not in remaining_tiles:
				all_available = false
				break
		
		if all_available:
			final_arrangement.append(s)
			for t in s:
				remaining_tiles.erase(t)
	
	# 3. Kalan taşları renk ve sayıya göre sırala
	remaining_tiles.sort_custom(func(a, b):
		if a.data.color < b.data.color: return true
		if a.data.color > b.data.color: return false
		return a.data.value < b.data.value
	)
	
	# 4. Istakaya yerleştir (Perler arasında boşluk bırakarak)
	_reassign_with_groups(final_arrangement, remaining_tiles)

func _find_all_valid_sets(tiles: Array, okey_t: OkeyTileData) -> Array[Array]:
	var sets: Array[Array] = []
	
	# Grupları bul (aynı sayı farklı renk)
	var val_map = {}
	for t in tiles:
		var v = t.data.value
		if not val_map.has(v): val_map[v] = []
		val_map[v].append(t)
	
	for v in val_map:
		var group_tiles = val_map[v]
		if group_tiles.size() >= 3:
			# Renk tekrarı olmayan tüm 3'lü ve 4'lü kombinasyonlar...
			# Basitleştirme: 3 veya 4 farklı renk varsa ekle
			var colors = {}
			var unique_color_group = []
			for t in group_tiles:
				if not colors.has(t.data.color):
					colors[t.data.color] = true
					unique_color_group.append(t)
			if unique_color_group.size() >= 3:
				sets.append(unique_color_group)

	# Serileri bul (ardışık aynı renk)
	var color_map = {}
	for t in tiles:
		var c = t.data.color
		if not color_map.has(c): color_map[c] = []
		color_map[c].append(t)
		
	for c in color_map:
		var c_tiles = color_map[c]
		c_tiles.sort_custom(func(a, b): return a.data.value < b.data.value)
		
		var current_run = []
		for i in range(c_tiles.size()):
			if current_run.is_empty():
				current_run.append(c_tiles[i])
			else:
				if c_tiles[i].data.value == current_run.back().data.value + 1:
					current_run.append(c_tiles[i])
				elif c_tiles[i].data.value == current_run.back().data.value:
					continue # Aynı taştan iki tane varsa seriyi bozma ama ekleme de
				else:
					if current_run.size() >= 3:
						sets.append(current_run.duplicate())
					current_run = [c_tiles[i]]
		if current_run.size() >= 3:
			sets.append(current_run.duplicate())
			
	return sets

func _reassign_with_groups(groups: Array, leftovers: Array) -> void:
	var new_slot_items = []
	new_slot_items.resize(slots.size())
	new_slot_items.fill(null)
	
	var cursor = 0
	# Önce grupları diz
	for group in groups:
		if cursor + group.size() > slots.size(): break
		for t in group:
			new_slot_items[cursor] = t
			cursor += 1
		cursor += 1 # Boşluk bırak
	
	# Sonra artıkları diz
	for t in leftovers:
		if cursor >= slots.size():
			cursor = new_slot_items.find(null)
		if cursor == -1: break
		new_slot_items[cursor] = t
		cursor += 1

	slot_items = new_slot_items
	for i in range(slot_items.size()):
		if slot_items[i]:
			snap_tile_to_slot(slot_items[i], i)
	emit_signal("logic_updated")

# ─────────────────────────────────────────────────────────────────────────────
#  ÇİFT DİZME
# ─────────────────────────────────────────────────────────────────────────────

func arrange_by_pairs() -> void:
	if held_tiles.is_empty(): return
	var tiles = held_tiles.duplicate()
	
	tiles.sort_custom(func(a, b):
		if a.data.value < b.data.value: return true
		if a.data.value > b.data.value: return false
		return a.data.color < b.data.color
	)
	
	var pairs = []
	var remaining = []
	var i = 0
	while i < tiles.size():
		if i + 1 < tiles.size() and RuleEngine.is_pair(tiles[i].data, tiles[i+1].data):
			pairs.append([tiles[i], tiles[i+1]])
			i += 2
		else:
			remaining.append(tiles[i])
			i += 1
			
	_reassign_with_groups(pairs, remaining)

# ─────────────────────────────────────────────────────────────────────────────
#  SLOT VE PUAN MANTIĞI
# ─────────────────────────────────────────────────────────────────────────────

func move_tile_to_slot(tile: TileObject, slot_index: int) -> void:
	var old_idx = slot_items.find(tile)
	if old_idx != -1:
		slot_items[old_idx] = null
	
	if slot_items[slot_index] != null:
		var occupying_tile = slot_items[slot_index]
		var empty_idx = find_empty_slot()
		if empty_idx != -1:
			slot_items[empty_idx] = occupying_tile
			snap_tile_to_slot(occupying_tile, empty_idx)
				
	slot_items[slot_index] = tile
	snap_tile_to_slot(tile, slot_index)
	emit_signal("logic_updated")

func _on_tile_drag_started(tile: TileObject) -> void:
	# Drag başladığında slotta yerini boşaltma (opsiyonel, genelde bitince yapılır)
	pass

func _on_tile_drag_ended(tile: TileObject) -> void:
	var best_dist = 9999.0
	var best_slot = -1
	for i in range(slots.size()):
		var slot_world_pos = global_position + (global_basis * slots[i])
		var d = tile.global_position.distance_to(slot_world_pos)
		if d < best_dist:
			best_dist = d
			best_slot = i
			
	if best_slot != -1:
		move_tile_to_slot(tile, best_slot)

func calculate_current_score(okey_tile: OkeyTileData = null) -> Dictionary:
	var total_series_score = 0
	var sets = get_openable_sets(okey_tile)
	for s in sets:
		var data_array: Array[OkeyTileData] = []
		for t in s: data_array.append(t.data)
		total_series_score += RuleEngine.get_group_sum(data_array, okey_tile)
		
	var valid_pairs_count = get_openable_pairs(okey_tile).size()
	return {"series": total_series_score, "pairs": valid_pairs_count}

func get_openable_sets(okey_tile: OkeyTileData = null) -> Array[Array]:
	var result: Array[Array] = []
	var current_set: Array[TileObject] = []
	for item in slot_items:
		if item != null:
			current_set.append(item)
		else:
			if current_set.size() >= 3:
				var data_set: Array[OkeyTileData] = []
				for t in current_set: data_set.append(t.data)
				if RuleEngine.is_valid_group(data_set, okey_tile):
					result.append(current_set.duplicate())
			current_set = []
	if current_set.size() >= 3:
		var data_set: Array[OkeyTileData] = []
		for t in current_set: data_set.append(t.data)
		if RuleEngine.is_valid_group(data_set, okey_tile):
			result.append(current_set.duplicate())
	return result

func get_openable_pairs(okey_tile: OkeyTileData = null) -> Array[Array]:
	var result: Array[Array] = []
	var current_set: Array[TileObject] = []
	for item in slot_items:
		if item != null:
			current_set.append(item)
		else:
			if current_set.size() == 2:
				if RuleEngine.is_pair(current_set[0].data, current_set[1].data, okey_tile):
					result.append(current_set.duplicate())
			current_set = []
	if current_set.size() == 2:
		if RuleEngine.is_pair(current_set[0].data, current_set[1].data, okey_tile):
			result.append(current_set.duplicate())
	return result
