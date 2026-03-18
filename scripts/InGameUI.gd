extends CanvasLayer

@onready var score_label := $ScorePanel/Margin/ScoreLabel

func _ready() -> void:
	call_deferred("_setup_connections")

func _setup_connections() -> void:
	var table = get_tree().get_root().find_child("Table", true, false)
	if table and table.racks.size() > 0:
		var local_rack = table.racks[0]
		if not local_rack.is_connected("logic_updated", _on_rack_logic_updated):
			local_rack.connect("logic_updated", _on_rack_logic_updated)
			_on_rack_logic_updated() # Make sure it calculates initial state

func _on_rack_logic_updated() -> void:
	var table = get_tree().get_root().find_child("Table", true, false)
	if table and table.racks.size() > 0:
		var score = table.racks[0].calculate_current_score()
		if score_label:
			score_label.text = "Seri Puanı: %d   |   Çift: %d/5" % [score.series, score.pairs]

func _on_btn_seri_diz_pressed() -> void:
	var table = get_tree().get_root().find_child("Table", true, false)
	if table and table.racks.size() > 0:
		table.racks[0].arrange_by_series()

func _on_btn_cift_diz_pressed() -> void:
	var table = get_tree().get_root().find_child("Table", true, false)
	if table and table.racks.size() > 0:
		table.racks[0].arrange_by_pairs()

func _on_btn_seri_ac_pressed() -> void:
	print("Seri Aç pressed - logic to be implemented")

func _on_btn_cift_ac_pressed() -> void:
	print("Çift Aç pressed - logic to be implemented")
