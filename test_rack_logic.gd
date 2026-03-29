extends SceneTree

func _initialize():
	var td_class = load("res://scripts/OkeyTileData.gd")
	var rack = load("res://scripts/Rack.gd").new()
	var rule_engine = load("res://scripts/RuleEngine.gd")
	
	# Root node for the scene
	var root_node = Node.new()
	self.root.add_child(root_node)

	var table = Node.new()
	table.name = "Table"
	table.set_script(load("res://scripts/Table.gd"))
	root_node.add_child(table)
	table.add_child(rack)

	var o_tile = td_class.new(5, 0, false, 99) # Red 5 (Okey)
	table.okey_tile_data = o_tile
	
	var t1 = td_class.new(4, 0, false, 1) # Red 4
	var t2 = td_class.new(6, 0, false, 2) # Red 6
	var okey_tile = td_class.new(5, 0, false, 3) # Red 5 (OKEY)
	var t_sahte = td_class.new(0, 4, true, 4) # Sahte Okey
	
	var tile_class = load("res://scripts/Tile.gd")
	var obj1 = tile_class.new()
	obj1.data = t1
	var obj2 = tile_class.new()
	obj2.data = okey_tile
	var obj3 = tile_class.new()
	obj3.data = t2
	
	# Simulate placing them contiguously in the rack
	rack.slot_items.resize(5)
	rack.slot_items.fill(null)
	rack.slot_items[0] = obj1 # Red 4
	rack.slot_items[1] = obj2 # Okey
	rack.slot_items[2] = obj3 # Red 6
	
	var score = rack.calculate_current_score(o_tile)
	print("Manual Run Score [4, Okey, 6]: ", score)

	rack.slot_items.fill(null)
	var obj4 = tile_class.new()
	var t4 = td_class.new(4, 1, false, 5) # Blue 4
	obj4.data = t4
	var obj5 = tile_class.new()
	var t5 = td_class.new(4, 2, false, 6) # Black 4
	obj5.data = t5
	rack.slot_items[0] = obj1 # Red 4
	rack.slot_items[1] = obj4 # Blue 4
	rack.slot_items[2] = obj2 # Okey (acts as Red 4? No, acts as missing color)
	
	score = rack.calculate_current_score(o_tile)
	print("Manual Group Score [Red 4, Blue 4, Okey]: ", score)
	
	quit()
