class_name PlayerHand

# Array of hands, which are arrays of OkeyTileData objects. 
# It represents the sets the player has arranged on their rack.
# Rack might be a 2D array of [rows][cols] in UI, but logically it's sets of tiles.
var pairs: Array[Array] = [] # Groups of size 2 (for opening pairs)
var sets: Array[Array] = []  # Groups of size >= 3 (for opening normal sets)

func add_set(new_set: Array[OkeyTileData]) -> void:
	sets.append(new_set)

func remove_set(index: int) -> void:
	if index >= 0 and index < sets.size():
		sets.remove_at(index)

func add_pair(pair: Array[OkeyTileData]) -> void:
	pairs.append(pair)

func remove_pair(index: int) -> void:
	if index >= 0 and index < pairs.size():
		pairs.remove_at(index)

func can_open_normal(okey_tile: OkeyTileData = null) -> bool:
	var total_sum = 0
	for s in sets:
		if RuleEngine.is_valid_group(s, okey_tile):
			var group_sum = RuleEngine.get_group_sum(s, okey_tile)
			if group_sum > 0:
				total_sum += group_sum
			else:
				# Invalid set in the group! Cannot open with invalid sets
				return false
		else:
			return false
	
	return total_sum >= Constants.MIN_OPENING_SUM

func can_open_pairs(okey_tile: OkeyTileData = null) -> bool:
	# Requires 5 valid pairs
	if pairs.size() < Constants.MIN_PAIRS_FOR_OPENING:
		return false
		
	for p in pairs:
		if p.size() != 2: return false
		if not RuleEngine.is_pair(p[0], p[1], okey_tile): return false
		
	return true
