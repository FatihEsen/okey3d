extends Node3D
class_name GameTable

@export var tile_scene: PackedScene
@export var rack_scene: PackedScene

var racks: Array[RackObject] = []
var active_tiles: Array[Node] = [] # Visual TileObjects in scene

@onready var deck_manager = preload("res://scripts/DeckManager.gd").new()

func _ready() -> void:
	add_child(deck_manager)
	
	setup_racks()
	
	# Start a new game directly for testing:
	start_new_round()

func setup_racks() -> void:
	if not rack_scene: return
	
	for i in range(4):
		var pos_node = get_node("PlayerPositions/Pos" + str(i))
		if pos_node:
			var rack = rack_scene.instantiate() as RackObject
			add_child(rack)
			rack.global_transform = pos_node.global_transform
			racks.append(rack)

func start_new_round() -> void:
	# Clear old visuals
	for child in active_tiles:
		child.queue_free()
	active_tiles.clear()
	
	# Clear logic
	for rack in racks:
		rack.clear_tiles()
	# Logic init
	deck_manager.create_deck()
	deck_manager.shuffle_deck()
	deck_manager.determine_okey()
	
	# Visual Init
	spawn_okey_indicator()
	
	# Deal tiles
	# Player 0 gets 22 tiles (starts), others get 21
	for id in range(4):
		var count = 22 if id == 0 else 21
		var dealt_data = deck_manager.deal_tiles(count)
		
		# For test, we spawn tiles for player 0 to see
		if id == 0:
			for data in dealt_data:
				var t = spawn_tile(data, $CenterDeckPos.global_position)
				racks[id].add_tile(t)
		else:
			# Not spawning visuals for AI/others right away, or spawn face down
			pass

func spawn_tile(data: OkeyTileData, pos: Vector3) -> TileObject:
	if not tile_scene: return null
	
	var tile = tile_scene.instantiate() as TileObject
	add_child(tile)
	tile.global_position = pos
	active_tiles.append(tile)
	tile.setup(data)
	
	return tile

func spawn_okey_indicator() -> void:
	if deck_manager.okey_indicator:
		var ind = spawn_tile(deck_manager.okey_indicator, $CenterDeckPos.global_position + Vector3(2, 0, 0))
		ind.global_rotation_degrees.x = 90 # Face up
