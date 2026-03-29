extends SceneTree

func _initialize():
	var td_class = load("res://scripts/OkeyTileData.gd")
	var rule_engine = load("res://scripts/RuleEngine.gd")
	
	var okey_tile = td_class.new(5, 0, false, -99) # Red 5 (Color 0 = Yellow? Let's assume 0=Yellow)
	
	var t1 = td_class.new(3, 0, false, 1) # Yellow 3
	var t2 = td_class.new(4, 0, false, 2) # Yellow 4
	var t_okey = td_class.new(5, 0, false, 3) # Yellow 5 (OKEY)
	var t_sahte = td_class.new(0, 4, true, 4) # Sahte Okey
	
	# Test Run with True Okey: 3, 4, OKEY(5)
	var grp1: Array[OkeyTileData] = [t1, t2, t_okey]
	var is_valid1 = rule_engine.is_valid_group(grp1, okey_tile)
	var sum1 = rule_engine.get_group_sum(grp1, okey_tile)
	print("Group 1 (3, 4, True Okey): Valid=", is_valid1, " Sum=", sum1)

	# Test Run with Sahte Okey: 3, 4, SAHTE(5)
	var grp2: Array[OkeyTileData] = [t1, t2, t_sahte]
	var is_valid2 = rule_engine.is_valid_group(grp2, okey_tile)
	var sum2 = rule_engine.get_group_sum(grp2, okey_tile)
	print("Group 2 (3, 4, Sahte Okey): Valid=", is_valid2, " Sum=", sum2)
	
	# Test Wrap Around Run: 12, 13, Okey(1)
	var okey_tile2 = td_class.new(1, 0, false, -99) # Yellow 1
	var t12 = td_class.new(12, 0, false, 1) # Yellow 12
	var t13 = td_class.new(13, 0, false, 2) # Yellow 13
	var t_okey_1 = td_class.new(1, 0, false, 3) # Yellow 1 (OKEY)
	var grp3: Array[OkeyTileData] = [t12, t13, t_okey_1]
	var is_valid3 = rule_engine.is_valid_group(grp3, okey_tile2)
	var sum3 = rule_engine.get_group_sum(grp3, okey_tile2)
	print("Group 3 (12, 13, True Okey(1)): Valid=", is_valid3, " Sum=", sum3)

	# Test Wrap Around Gapped Run: Okey(12), 13, 1
	var okey_tile3 = td_class.new(12, 0, false, -99) # Yellow 12
	var t1_1 = td_class.new(1, 0, false, 1) # Yellow 1
	var t_okey_12 = td_class.new(12, 0, false, 3) # Yellow 12 (OKEY)
	var grp4: Array[OkeyTileData] = [t_okey_12, t13, t1_1]
	var is_valid4 = rule_engine.is_valid_group(grp4, okey_tile3)
	var sum4 = rule_engine.get_group_sum(grp4, okey_tile3)
	print("Group 4 (True Okey(12), 13, 1): Valid=", is_valid4, " Sum=", sum4)
	
	var r = load("res://scripts/Rack.gd").new()
	var test_duos = []
	var res = r._find_all_valid_sets([
		_mock_tile(t12), _mock_tile(t1_1)
	], okey_tile3)
	print("Rack duos for 12, 1? ", res.duos.size())

	quit()

func _mock_tile(data):
	var t = load("res://scripts/Tile.gd").new()
	t.data = data
	return t
