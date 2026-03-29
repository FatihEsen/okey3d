extends SceneTree

func _initialize():
	# Root node for the scene
	var root_node = Node.new()
	self.root.add_child(root_node)

	var table = Node.new()
	table.name = "Table"
	table.set_script(load("res://scripts/Table.gd"))
	root_node.add_child(table)

	var rack = load("res://scripts/Rack.gd").new()
	table.add_child(rack)
	
	var okey_data = load("res://scripts/OkeyTileData.gd")
	var tile_class = load("res://scripts/Tile.gd")
	for i in range(22):
		var t = tile_class.new()
		var d = okey_data.new()
		d.color = randi() % 4
		d.value = (randi() % 13) + 1
		t.data = d
		rack.held_tiles.append(t)
	
	rack._ready()
	
	print("Running arrange_by_series...")
	rack.arrange_by_series()
	print("Running arrange_by_pairs...")
	rack.arrange_by_pairs()
	print("Finished!")
	quit()
