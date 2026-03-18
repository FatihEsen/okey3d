extends Control

func _ready() -> void:
	modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.6)

func _on_btn_katlamasiz_pressed() -> void:
	GameState.game_mode = Constants.GameMode.KATLAMASIZ
	GameState.reset_state()
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_btn_katlamali_pressed() -> void:
	GameState.game_mode = Constants.GameMode.KATLAMALI
	GameState.reset_state()
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_btn_rules_katlamasiz_pressed() -> void:
	$RuleDialog.show_rules(Constants.GameMode.KATLAMASIZ)
	$RuleDialog.popup_centered()

func _on_btn_rules_katlamali_pressed() -> void:
	$RuleDialog.show_rules(Constants.GameMode.KATLAMALI)
	$RuleDialog.popup_centered()
