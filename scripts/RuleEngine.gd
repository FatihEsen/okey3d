class_name RuleEngine

# Evaluates a single set to see if it's a valid run (series) or valid group of same numbers.
static func is_valid_group(group: Array[OkeyTileData], okey_tile: OkeyTileData = null) -> bool:
	if group.size() < 3:
		return false
	
	# Replace jokers with the best fit. For a simple check, we handle them carefully.
	# For now, let's implement validation without jokers, and then add joker support later.
	
	# Check if it's a same-number group (e.g. Red 5, Blue 5, Black 5)
	var all_same_value = true
	var values = []
	var colors = []
	
	var non_joker_count = 0
	var joker_count = 0
	
	for tile in group:
		if tile.is_joker or (okey_tile and is_tile_joker(tile, okey_tile)):
			joker_count += 1
		else:
			values.append(tile.value)
			if tile.color not in colors:
				colors.append(tile.color)
			else:
				# Cannot have matching colors in a same-number group unless it's a run.
				all_same_value = false # Will force it to check run logic
	
	# If all non-jokers have the same value, and we have distinct colors:
	if all_same_value and values.size() > 0:
		var first_val = values[0]
		var valid_same_num = true
		for v in values:
			if v != first_val:
				valid_same_num = false
				break
		
		# Colors must be distinct. We already checked if colors are repeated above for same-number group context.
		# If it's valid so far, and distinct colors + jokers <= 4 (max 4 colors)
		if valid_same_num and colors.size() + joker_count <= 4 and colors.size() == values.size():
			return true

	# Check if it's a run (consecutive numbers, same color)
	var run_color = -1
	var run_values = []
	for tile in group:
		if tile.is_joker or (okey_tile and is_tile_joker(tile, okey_tile)):
			pass # Skip jokers for color check
		else:
			if run_color == -1:
				run_color = tile.color
			elif run_color != tile.color:
				return false # Not a run, different colors
			run_values.append(tile.value)
	
	# If we have only jokers (rare but possible), it's valid
	if run_values.size() == 0:
		return true
		
	# Sort values
	run_values.sort()
	
	# Check for gaps and see if jokers can fill them
	var missing_count = 0
	for i in range(1, run_values.size()):
		var diff = run_values[i] - run_values[i-1]
		if diff == 0:
			return false # Duplicate tiles in a run not allowed
		missing_count += (diff - 1)
	
	# If missing slots can be filled by jokers, it's a valid run
	# Also need to make sure total length doesn't exceed 13
	# In Okey 101, 13-1 is NOT allowed.
	if missing_count <= joker_count:
		var max_val = run_values.back() + (joker_count - missing_count)
		if max_val <= 13: # or if jokers are added to the beginning, it could exceed but let's do a simple check
			return true
		
		# More complex: jokers can be at the start or end.
		# As long as the span of the sequence (max - min) < size of group, it's valid.
		var span = run_values.back() - run_values.front() + 1
		# jokers can cover the span
		if span <= group.size() and group.size() <= 13:
			return true

	return false

static func is_tile_joker(tile: OkeyTileData, okey_tile: OkeyTileData) -> bool:
	if tile.is_joker:
		# 'False Joker' - acts as the actual Okey tile value
		return false 
	# The actual joker in the game is one value higher than the face-up indicator
	# e.g., Indicator is Red 5. Joker is Red 6.
	var joker_val = okey_tile.value + 1
	var joker_color = okey_tile.color
	if joker_val > 13:
		joker_val = 1
	return tile.value == joker_val and tile.color == joker_color

static func get_group_sum(group: Array[OkeyTileData], okey_tile: OkeyTileData = null) -> int:
	var total = 0
	if not is_valid_group(group, okey_tile):
		return 0
		
	# Calculate value. Jokers take the value of the tile they represent.
	# For simplicity, if we have a group of same numbers: 
	# value = number * size
	# If we have a run: 
	# value = sum of numbers
	# ... (Implementation details for calculating exact sum with jokers)
	
	# Basic sum:
	for tile in group:
		if tile.is_joker or (okey_tile and is_tile_joker(tile, okey_tile)):
			pass # need context
		else:
			total += tile.value
			
	# FIXME: proper joker evaluation
	return total

static func is_pair(tile1: OkeyTileData, tile2: OkeyTileData, okey_tile: OkeyTileData = null) -> bool:
	# A pair is exactly identical tiles. E.g. Red 5 and Red 5.
	return tile1.value == tile2.value and tile1.color == tile2.color and tile1.is_joker == tile2.is_joker
