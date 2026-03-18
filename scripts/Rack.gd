extends StaticBody3D
class_name RackObject

@export var max_tiles: int = 22 # Initial max hand size the rack should fit
@export var spacing: float = 1.02 # Distance between tile slots

var held_tiles: Array[TileObject] = []
var slots: Array[Vector3] = []
var slot_items: Array[TileObject] = []

signal logic_updated()

func _ready() -> void:
	# Generate simple slots across x-axis
	var total_width = (max_tiles - 1) * spacing
	var start_x = -total_width / 2.0
	
	# Overwrite with two row logic
	slots.clear()
	var row_capacity = 16
	var row_spacing = 1.1 # Width of tile + some margin
	var col_spacing = 1.2 # Depth/height difference
	
	for row in range(2):
		total_width = (row_capacity - 1) * row_spacing
		start_x = -total_width / 2.0
		# Calculate offset
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
		return false # Rack is full
	
	held_tiles.append(tile)
	if not tile.is_connected("drag_started", _on_tile_drag_started):
		tile.connect("drag_started", _on_tile_drag_started)
		tile.connect("drag_ended", _on_tile_drag_ended)

	# Snap to next available slot
	var slot_index = find_empty_slot()
	if slot_index != -1:
		slot_items[slot_index] = tile
		snap_tile_to_slot(tile, slot_index)
	emit_signal("logic_updated")
	return true

func remove_tile(tile: TileObject) -> void:
	if tile in held_tiles:
		held_tiles.erase(tile)
		tile.freeze = false # Let physics take over again when removed
		var idx = slot_items.find(tile)
		if idx != -1:
			slot_items[idx] = null
		emit_signal("logic_updated")
		
func find_empty_slot() -> int:
	return slot_items.find(null)

func move_tile_to_slot(tile: TileObject, target_slot: int) -> void:
	if target_slot < 0 or target_slot >= slots.size(): return
	
	var current_slot = slot_items.find(tile)
	if current_slot == target_slot: return
	
	if current_slot != -1:
		slot_items[current_slot] = null
		
	# If the target slot is currently occupied, swap the tiles
	if slot_items[target_slot] != null:
		var occupying_tile = slot_items[target_slot]
		if current_slot != -1:
			slot_items[current_slot] = occupying_tile
			snap_tile_to_slot(occupying_tile, current_slot)
		else:
			var empty_idx = find_empty_slot()
			if empty_idx != -1:
				slot_items[empty_idx] = occupying_tile
				snap_tile_to_slot(occupying_tile, empty_idx)
				
	slot_items[target_slot] = tile
	snap_tile_to_slot(tile, target_slot)
	emit_signal("logic_updated")

func snap_tile_to_slot(tile: TileObject, slot_index: int) -> void:
	if slot_index < 0 or slot_index >= slots.size(): return
	
	var target_pos = global_position + (global_basis * slots[slot_index])
	
	tile.freeze = true # Freeze physics so the tile stays on the rack
	
	var tween = get_tree().create_tween().set_parallel(true)
	tween.tween_property(tile, "global_position", target_pos, 0.2)
	var tilted_basis = global_basis.rotated(global_basis.x, deg_to_rad(15))
	tween.tween_property(tile, "global_basis", tilted_basis, 0.2)

func arrange_by_series() -> void:
	if held_tiles.is_empty(): return
	var tiles = held_tiles.duplicate()
	
	# Sort by Color then Value
	tiles.sort_custom(func(a, b):
		if a.data.color < b.data.color: return true
		if a.data.color > b.data.color: return false
		return a.data.value < b.data.value
	)
	
	var new_slots = []
	new_slots.resize(slot_items.size())
	new_slots.fill(null)
	
	var current_idx = 0
	for i in range(tiles.size()):
		if current_idx >= new_slots.size():
			current_idx = new_slots.find(null)
			
		if i > 0 and current_idx != -1:
			var prev = tiles[i-1]
			var curr = tiles[i]
			# Add a gap if color changed, or value gap exists, and we are not at end of row
			if curr.data.color != prev.data.color or curr.data.value > prev.data.value + 1:
				current_idx += 1
				
		if current_idx >= new_slots.size() or current_idx == -1:
			current_idx = new_slots.find(null)
			
		if current_idx != -1:
			new_slots[current_idx] = tiles[i]
			current_idx += 1
			
	_reassign_slots_array(new_slots)

func arrange_by_pairs() -> void:
	if held_tiles.is_empty(): return
	var tiles = held_tiles.duplicate()
	
	# Sort by Value, then Color
	tiles.sort_custom(func(a, b):
		if a.data.value < b.data.value: return true
		if a.data.value > b.data.value: return false
		return a.data.color < b.data.color
	)
	
	var paired_tiles: Array[TileObject] = []
	var unpaired_tiles: Array[TileObject] = []
	
	var i = 0
	while i < tiles.size():
		if i + 1 < tiles.size() and tiles[i].data.matches(tiles[i+1].data):
			paired_tiles.append(tiles[i])
			paired_tiles.append(tiles[i+1])
			i += 2
		else:
			unpaired_tiles.append(tiles[i])
			i += 1
			
	var result_tiles = paired_tiles
	result_tiles.append_array(unpaired_tiles)
	
	# Place them tightly, no special gaps
	var new_slots = []
	new_slots.resize(slot_items.size())
	new_slots.fill(null)
	for j in range(result_tiles.size()):
		new_slots[j] = result_tiles[j]
		
	_reassign_slots_array(new_slots)

func _reassign_slots_array(new_slots: Array) -> void:
	for i in range(slot_items.size()):
		slot_items[i] = new_slots[i]
		if slot_items[i] != null:
			snap_tile_to_slot(slot_items[i], i)
	emit_signal("logic_updated")

func _on_tile_drag_started(tile: TileObject) -> void:
	# Unassign from physical slot without losing reference
	pass

func _on_tile_drag_ended(tile: TileObject) -> void:
	# Find closest slot
	var best_dist = INF
	var best_slot = -1
	for i in range(slots.size()):
		var slot_world_pos = global_position + (global_basis * slots[i])
		var d = slot_world_pos.distance_to(tile.global_position)
		if d < best_dist:
			best_dist = d
			best_slot = i
			
	if best_slot != -1:
		move_tile_to_slot(tile, best_slot)

func calculate_current_score() -> Dictionary:
	var total_series_score = 0
	var valid_pairs_count = 0
	
	var current_group: Array[OkeyTileData] = []
	for item in slot_items:
		if item != null:
			current_group.append(item.data)
		else:
			if current_group.size() > 0:
				total_series_score += _evaluate_group(current_group)
				if current_group.size() == 2 and RuleEngine.is_pair(current_group[0], current_group[1]):
					valid_pairs_count += 1
				current_group = []
				
	if current_group.size() > 0:
		total_series_score += _evaluate_group(current_group)
		if current_group.size() == 2 and RuleEngine.is_pair(current_group[0], current_group[1]):
			valid_pairs_count += 1
			
	return {"series": total_series_score, "pairs": valid_pairs_count}

func _evaluate_group(group: Array[OkeyTileData]) -> int:
	if RuleEngine.is_valid_group(group):
		return RuleEngine.get_group_sum(group)
	return 0
