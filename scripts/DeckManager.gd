extends Node
class_name DeckManager

# Total tiles: 106.
# 2 sets of [1-13 in 4 colors] = 104 tiles
# 2 False Jokers = 2 tiles

var remaining_tiles: Array[OkeyTileData] = []
var discarded_tiles: Array[OkeyTileData] = []
var okey_indicator: OkeyTileData = null

# Called when starting a new round
func create_deck() -> void:
	remaining_tiles.clear()
	discarded_tiles.clear()
	okey_indicator = null
	
	var id_counter = 0
	
	# Add 2 sets of each numbered tile
	for i in range(2):
		for c in [Constants.TileColor.YELLOW, Constants.TileColor.BLUE, Constants.TileColor.BLACK, Constants.TileColor.RED]:
			for v in range(1, 14): # 1 to 13
				var td = preload("res://scripts/OkeyTileData.gd").new()
				td.value = v
				td.color = c
				td.is_joker = false
				td.id = id_counter
				remaining_tiles.append(td)
				id_counter += 1
				
		# Add 2 False Jokers (Sahte Okey)
		var sahte = preload("res://scripts/OkeyTileData.gd").new()
		sahte.value = 0
		sahte.color = Constants.TileColor.JOKER
		sahte.is_joker = true
		sahte.id = id_counter
		remaining_tiles.append(sahte)
		id_counter += 1
		
	# Now we have 106 tiles in `remaining_tiles`.

func shuffle_deck() -> void:
	# Use a simple shuffle (randomize each time or once)
	randomize()
	var shuffled: Array[OkeyTileData] = []
	while remaining_tiles.size() > 0:
		var index = randi() % remaining_tiles.size()
		shuffled.append(remaining_tiles[index])
		remaining_tiles.remove_at(index)
	remaining_tiles = shuffled

func determine_okey() -> void:
	# Randomly pick an indicator tile that is NOT a False Joker.
	var index = -1
	while true:
		index = randi() % remaining_tiles.size()
		if not remaining_tiles[index].is_joker:
			break
			
	# Remove the indicator tile from the deck and set it
	okey_indicator = remaining_tiles[index]
	remaining_tiles.remove_at(index)

func get_okey_tile_value() -> int:
	if not okey_indicator: 
		return -1
	
	var val = okey_indicator.value + 1
	if val > 13:
		val = 1
	return val

func get_okey_tile_color() -> Constants.TileColor:
	if not okey_indicator:
		return Constants.TileColor.JOKER
	return okey_indicator.color

func deal_tiles(num_tiles: int) -> Array[OkeyTileData]:
	var result: Array[OkeyTileData] = []
	for i in range(num_tiles):
		if remaining_tiles.size() > 0:
			var tile = remaining_tiles.pop_back()
			result.append(tile)
	return result

func draw_tile() -> OkeyTileData:
	if remaining_tiles.size() > 0:
		var tile = remaining_tiles.pop_back()
		return tile
	return null

func discard_tile(tile: OkeyTileData) -> void:
	discarded_tiles.append(tile)

func get_top_discard() -> OkeyTileData:
	if discarded_tiles.size() > 0:
		return discarded_tiles.back()
	return null
