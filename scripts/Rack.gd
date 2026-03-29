extends StaticBody3D
class_name RackObject

@export var max_tiles: int = 22
@export var spacing: float = 1.02

var held_tiles: Array[TileObject] = []
var slots: Array[Vector3] = []
var slot_items: Array[TileObject] = []

var slot_highlight: MeshInstance3D

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
		var y_offset = 1.0 + (row * 0.8) # Istakadaki iki sıra arasını ve yüksekliği artırdık
		
		for col in range(row_capacity):
			slots.append(Vector3(start_x + (col * row_spacing), y_offset, z_offset))

	slot_items.resize(slots.size())
	slot_items.fill(null)
	
	slot_highlight = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(1.1, 1.8, 0.4)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 1.0, 0.2, 0.35)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	slot_highlight.mesh = box
	slot_highlight.visible = false
	add_child(slot_highlight)

func _process(_delta: float) -> void:
	var dragging_tile = null
	for t in held_tiles:
		if t is TileObject and t.is_dragging:
			dragging_tile = t
			break
			
	if not dragging_tile:
		if slot_highlight.visible: slot_highlight.visible = false
		return
		
	var best_dist = 9999.0
	var best_slot = -1
	for i in range(slots.size()):
		var slot_world_pos = global_position + (global_basis * slots[i])
		var d = dragging_tile.global_position.distance_to(slot_world_pos)
		if d < best_dist:
			best_dist = d
			best_slot = i
			
	if best_slot != -1 and best_dist < 6.0:
		slot_highlight.visible = true
		slot_highlight.global_position = global_position + (global_basis * slots[best_slot])
		slot_highlight.global_basis = global_basis
	else:
		slot_highlight.visible = false

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
	
	var table = get_tree().get_root().find_child("Table", true, false)
	var okey_tile = table.okey_tile_data if table else null
	
	var tiles = held_tiles.duplicate()
	var final_arrangement: Array[Array] = [] 
	
	var analysis = _find_all_valid_sets(tiles, okey_tile)
	var possible_sets = analysis.sets
	var duos = analysis.duos
	var okeys = analysis.okeys
	
	var remaining_tiles = tiles.duplicate()
	
	# En yüksek puan getirecek olan 2'li (duo) grupları Okey ile tamamla!
	duos.sort_custom(func(a, b):
		var sum_a = RuleEngine.get_effective_value(a[0].data, okey_tile) + RuleEngine.get_effective_value(a[1].data, okey_tile)
		var sum_b = RuleEngine.get_effective_value(b[0].data, okey_tile) + RuleEngine.get_effective_value(b[1].data, okey_tile)
		return sum_a > sum_b
	)
	
	for d in duos:
		if okeys.is_empty(): break
		if d[0] in remaining_tiles and d[1] in remaining_tiles:
			var ok = okeys.pop_back()
			var v1 = RuleEngine.get_effective_value(d[0].data, okey_tile)
			var v2 = RuleEngine.get_effective_value(d[1].data, okey_tile)
			var c1 = RuleEngine.get_effective_color(d[0].data, okey_tile)
			var c2 = RuleEngine.get_effective_color(d[1].data, okey_tile)
			
			var new_set = []
			if c1 != c2:
				new_set = [d[0], d[1], ok]
			else:
				var diff = v2 - v1
				if diff == 1:
					new_set = [d[0], d[1], ok]
				elif diff == 2:
					new_set = [d[0], ok, d[1]]
				elif v1 == 1 and v2 == 13: # 1, 13
					new_set = [ok, d[1], d[0]] # Okey(12), 13, 1
				elif v1 == 1 and v2 == 12: # 1, 12
					new_set = [d[1], ok, d[0]] # 12, Okey(13), 1
				elif v1 == 2 and v2 == 13: # 2, 13
					new_set = [d[1], ok, d[0]] # 13, Okey(1), 2
				else:
					new_set = [d[0], d[1], ok]
					
			final_arrangement.append(new_set)
			remaining_tiles.erase(d[0])
			remaining_tiles.erase(d[1])
			remaining_tiles.erase(ok)
			
	# Geriye kalan normal perleri (3'lü, 4'lü) yerleştir
	possible_sets.sort_custom(func(a, b):
		return a.size() > b.size()
	)
	
	for s in possible_sets:
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

func _find_all_valid_sets(tiles: Array, okey_t: OkeyTileData) -> Dictionary:
	var sets: Array[Array] = []
	var potential_duos: Array[Array] = []
	
	var okey_tiles = []
	var regular_tiles = []
	for t in tiles:
		if RuleEngine.is_tile_joker(t.data, okey_t):
			okey_tiles.append(t)
		else:
			regular_tiles.append(t)
	
	var val_map = {}
	var color_map = {}
	for t in regular_tiles:
		var v = RuleEngine.get_effective_value(t.data, okey_t)
		var c = RuleEngine.get_effective_color(t.data, okey_t)
		if not val_map.has(v): val_map[v] = []
		val_map[v].append(t)
		if not color_map.has(c): color_map[c] = []
		color_map[c].append(t)
	
	# 1. Gruplar (Aynı Numara, Farklı Renk)
	for v in val_map:
		var group_tiles = val_map[v]
		var unique_cols = {}
		var unique_t = []
		for t in group_tiles:
			var c = RuleEngine.get_effective_color(t.data, okey_t)
			if not unique_cols.has(c):
				unique_cols[c] = true
				unique_t.append(t)
		
		if unique_t.size() >= 3:
			sets.append(unique_t.duplicate())
		if unique_t.size() >= 2:
			for i in range(unique_t.size()):
				for j in range(i+1, unique_t.size()):
					potential_duos.append([unique_t[i], unique_t[j]])

	# 2. Seriler (Aynı Renk, Ardışık Numara)
	for c in color_map:
		var c_tiles = color_map[c]
		c_tiles.sort_custom(func(a, b): return RuleEngine.get_effective_value(a.data, okey_t) < RuleEngine.get_effective_value(b.data, okey_t))
		
		var current_run = []
		for i in range(c_tiles.size()):
			if current_run.is_empty():
				current_run.append(c_tiles[i])
			else:
				var current_v = RuleEngine.get_effective_value(c_tiles[i].data, okey_t)
				var last_v = RuleEngine.get_effective_value(current_run.back().data, okey_t)
				
				if current_v == last_v + 1:
					current_run.append(c_tiles[i])
				elif current_v == last_v:
					continue
				else:
					if current_run.size() >= 3: sets.append(current_run.duplicate())
					current_run = [c_tiles[i]]
		if current_run.size() >= 3: sets.append(current_run.duplicate())
		
		var unique_c = []
		var seen_v = {}
		for t in c_tiles:
			var v = RuleEngine.get_effective_value(t.data, okey_t)
			if not seen_v.has(v):
				seen_v[v] = true
				unique_c.append(t)
				
		for i in range(unique_c.size()):
			for j in range(i+1, unique_c.size()):
				var v1 = RuleEngine.get_effective_value(unique_c[i].data, okey_t)
				var v2 = RuleEngine.get_effective_value(unique_c[j].data, okey_t)
				var diff = v2 - v1
				# Farka göre ardışık veya boşluklu olduğunu anlarız. 
				# 1: Normal ardışık (4-5) 
				# 2: Arada bir boşluk (4-6)
				# 12: (1 ve 13)
				# 11: (1 ve 12) veya (2 ve 13)
				if diff == 1 or diff == 2 or diff == 12 or diff == 11:
					potential_duos.append([unique_c[i], unique_c[j]])
					
	return {"sets": sets, "duos": potential_duos, "okeys": okey_tiles}

func _reassign_with_groups(groups: Array, leftovers: Array) -> void:
	var new_slot_items: Array[TileObject] = []
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
			
		while cursor != -1 and cursor < slots.size() and new_slot_items[cursor] != null:
			cursor += 1
			if cursor >= slots.size():
				cursor = new_slot_items.find(null)
				break
				
		if cursor == -1: 
			break
			
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
