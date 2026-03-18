extends Control

func _ready() -> void:
	print("MENU: Hazırlandı.")
	# Force visibility
	modulate = Color.WHITE
	self.show()
	_find_and_connect_buttons()

func _find_and_connect_buttons() -> void:
	# find_child ile recursive arama yapıp butonları doğrudan bağlayalım
	var buttons = {
		"BtnPlayKS": "CardKatlamasiz/VBox/Margin/Inner/BtnPlay",
		"BtnPlayKL": "CardKatlamali/VBox/Margin/Inner/BtnPlay",
		"BtnRuleKS": "CardKatlamasiz/VBox/Margin/Inner/BtnRules",
		"BtnRuleKL": "CardKatlamali/VBox/Margin/Inner/BtnRules"
	}
	
	# Buton isimlerini tscn içinde benzersiz yapalım veya find_child ile bulalım
	# Şu an find_child daha garanti.
	var all_btns = find_children("*", "Button", true)
	for b in all_btns:
		if b.pressed.is_connected(_on_any_button_pressed.bind(b)):
			b.pressed.disconnect(_on_any_button_pressed.bind(b))
		b.pressed.connect(_on_any_button_pressed.bind(b))
		print("MENU: Buton bağlandı: ", b.name, " (", b.text, ")")

func _on_any_button_pressed(btn: Button) -> void:
	print("MENU: Butona basıldı -> ", btn.name, " [", btn.text, "]")
	
	# Hangi kartta olduğumuzu tespit et (CardKatlamasiz / CardKatlamali)
	var p: Node = btn
	var card_name := ""
	while p:
		if p.name == "CardKatlamasiz" or p.name == "CardKatlamali":
			card_name = p.name
			break
		p = p.get_parent()
	
	var is_rules_btn = "Kurallar" in btn.text
	
	if card_name == "CardKatlamasiz":
		if is_rules_btn:
			_on_btn_rules_katlamasiz_pressed()
		else:
			_on_btn_katlamasiz_pressed()
	elif card_name == "CardKatlamali":
		if is_rules_btn:
			_on_btn_rules_katlamali_pressed()
		else:
			_on_btn_katlamali_pressed()
	else:
		# Kartı bulamazsak varsayılanı oyna/kurallar olarak kullan
		if is_rules_btn:
			_on_btn_rules_katlamasiz_pressed()
		else:
			_on_btn_katlamasiz_pressed()

func _on_btn_katlamasiz_pressed() -> void:
	GameState.game_mode = Constants.GameMode.KATLAMASIZ
	_start_game()

func _on_btn_katlamali_pressed() -> void:
	GameState.game_mode = Constants.GameMode.KATLAMALI
	_start_game()

func _start_game() -> void:
	print("MENU: Oyun başlatılıyor...")
	GameState.reset_state()
	var scene_path = "res://scenes/Main.tscn"
	
	# Sahne dosyasını manuel doğrula
	if not FileAccess.file_exists(scene_path):
		print("MENU: HATA! Dosya bulunamadı: ", scene_path)
		return
		
	var err = get_tree().change_scene_to_file(scene_path)
	if err != OK:
		print("MENU: Geçiş hatası kodu: ", err)

func _on_btn_rules_katlamasiz_pressed() -> void:
	var dlg = find_child("RuleDialog", true, false)
	if dlg:
		dlg.show_rules(Constants.GameMode.KATLAMASIZ)
		dlg.popup_centered()

func _on_btn_rules_katlamali_pressed() -> void:
	var dlg = find_child("RuleDialog", true, false)
	if dlg:
		dlg.show_rules(Constants.GameMode.KATLAMALI)
		dlg.popup_centered()
