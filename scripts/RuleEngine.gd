class_name RuleEngine

# Evaluates a single set to see if it's a valid run (series) or valid group of same numbers.
static func is_valid_group(group: Array[OkeyTileData], okey_tile: OkeyTileData = null) -> bool:
	if group.size() < 3:
		return false
	
	if is_same_number_group(group, okey_tile):
		return true
	if is_run_group(group, okey_tile):
		return true
		
	return false

static func is_same_number_group(group: Array[OkeyTileData], okey_tile: OkeyTileData = null) -> bool:
	if group.size() < 3 or group.size() > 4:
		return false
		
	var value = -1
	var colors = []
	var jokers = 0
	
	for tile in group:
		if is_tile_joker(tile, okey_tile):
			jokers += 1
		else:
			if value == -1:
				value = tile.value
			elif value != tile.value:
				return false
			
			if tile.color in colors:
				return false # Distinct colors required
			colors.append(tile.color)
			
	return true if value != -1 else (jokers >= 3)

static func is_run_group(group: Array[OkeyTileData], okey_tile: OkeyTileData = null) -> bool:
	if group.size() < 3 or group.size() > 13:
		return false
		
	var color = -1
	var tile_values = [] # (index in group, value)
	
	for i in range(group.size()):
		var tile = group[i]
		if is_tile_joker(tile, okey_tile):
			tile_values.append({"idx": i, "val": -1})
		else:
			if color == -1:
				color = tile.color
			elif color != tile.color:
				return false
			tile_values.append({"idx": i, "val": tile.value})

	if color == -1: return true # All jokers
	
	# Find a non-joker to anchor the sequence
	var anchor_idx = -1
	var anchor_val = -1
	for item in tile_values:
		if item.val != -1:
			anchor_idx = item.idx
			anchor_val = item.val
			break
			
	# Infer what each tile's value should be
	var inferred_values = []
	for i in range(group.size()):
		var expected = anchor_val + (i - anchor_idx)
		if expected < 1 or expected > 13:
			return false # Out of bounds
		inferred_values.append(expected)
		
	# Check if non-joker tiles match their inferred values
	for i in range(group.size()):
		if tile_values[i].val != -1 and tile_values[i].val != inferred_values[i]:
			return false
			
	return true

static func get_group_sum(group: Array[OkeyTileData], okey_tile: OkeyTileData = null) -> int:
	if not is_valid_group(group, okey_tile):
		return 0
		
	if is_same_number_group(group, okey_tile):
		var val = -1
		for t in group:
			if not is_tile_joker(t, okey_tile):
				val = t.value
				break
		if val == -1: val = 0 # All jokers? odd case
		return val * group.size()
	
	if is_run_group(group, okey_tile):
		# Find anchor to infer sum
		var anchor_idx = -1
		var anchor_val = -1
		for i in range(group.size()):
			if not is_tile_joker(group[i], okey_tile):
				anchor_idx = i
				anchor_val = group[i].value
				break
		
		# If somehow all jokers
		if anchor_val == -1: return 0
		
		var total = 0
		for i in range(group.size()):
			total += (anchor_val + (i - anchor_idx))
		return total
		
	return 0

static func is_tile_joker(tile: OkeyTileData, okey_tile: OkeyTileData) -> bool:
	if not okey_tile: return false
	# False Joker (represented by is_joker field on data) plays as the Okey tile
	if tile.is_joker: return false 
	
	var target_val = okey_tile.value + 1
	if target_val > 13: target_val = 1
	return tile.value == target_val and tile.color == okey_tile.color

static func is_pair(tile1: OkeyTileData, tile2: OkeyTileData, okey_tile: OkeyTileData = null) -> bool:
	# Pairs must be identical (value and color).
	# Jokers cannot be used as pairs among themselves normally in 101, but they can be used? 
	# "okeyler çift olarak kullanılamaz bazı kurallarda" - User prompt says.
	# Standard rule: two identical tiles.
	return tile1.value == tile2.value and tile1.color == tile2.color and tile1.is_joker == tile2.is_joker
