class_name RuleEngine

# ─── Wildcard Tespiti ─────────────────────────────────────────────────────────
# Hem gerçek Okey taşı (gösterge+1, aynı renk) hem Sahte Okey (is_joker=true)
# wildcard sayılır.
static func is_wildcard(tile: OkeyTileData, okey_tile: OkeyTileData) -> bool:
	if not okey_tile: return false
	if tile.is_joker: return true  # Sahte Okey
	var target_val = okey_tile.value + 1
	if target_val > 13: target_val = 1
	return tile.value == target_val and tile.color == okey_tile.color

# Eski uyumluluk için alias
static func is_tile_joker(tile: OkeyTileData, okey_tile: OkeyTileData) -> bool:
	return is_wildcard(tile, okey_tile)

static func get_effective_value(tile: OkeyTileData, _okey_tile: OkeyTileData) -> int:
	return tile.value

static func get_effective_color(tile: OkeyTileData, _okey_tile: OkeyTileData) -> int:
	return tile.color

# ─── Grup Doğrulama ──────────────────────────────────────────────────────────
static func is_valid_group(group: Array[OkeyTileData], okey_tile: OkeyTileData = null) -> bool:
	if group.size() < 3: return false
	if is_same_number_group(group, okey_tile): return true
	if is_run_group(group, okey_tile): return true
	return false

# Grup: Aynı sayı, 3-4 farklı renk (wildcard herhangi bir renk/sayı olabilir)
static func is_same_number_group(group: Array[OkeyTileData], okey_tile: OkeyTileData = null) -> bool:
	if group.size() < 3 or group.size() > 4: return false
	var value = -1
	var colors: Array = []
	var wildcards = 0
	for tile in group:
		if is_wildcard(tile, okey_tile):
			wildcards += 1
		else:
			if value == -1:
				value = tile.value
			elif value != tile.value:
				return false
			if tile.color in colors:
				return false  # Aynı renk iki kez olamaz
			colors.append(tile.color)
	return true if value != -1 else (wildcards >= 3)

# Seri: Aynı renk, ardışık sayılar (1-13 arası). 12-13-1 sarmalama YOK.
static func is_run_group(group: Array[OkeyTileData], okey_tile: OkeyTileData = null) -> bool:
	if group.size() < 3 or group.size() > 13: return false
	var color = -1
	var wildcards = 0
	var vals: Array = []
	for tile in group:
		if is_wildcard(tile, okey_tile):
			wildcards += 1
		else:
			if color == -1:
				color = tile.color
			elif color != tile.color:
				return false  # Farklı renk var, seri değil
			vals.append(tile.value)
	if color == -1: return true  # Hepsi wildcard
	vals.sort()
	# Aynı değer iki kez var mı?
	for i in range(vals.size() - 1):
		if vals[i] == vals[i + 1]: return false
	# Değerler 1-13 arasında olmalı
	if vals[0] < 1 or vals[-1] > 13: return false
	# Gerçek taşların yayıldığı aralık + wildcard sayısı = grup büyüklüğünü karşılamalı
	var span = vals[-1] - vals[0] + 1  # Gerçek taşların min-max aralığı
	if span > group.size(): return false  # Boşluklar wildcard'larla kapanamaz
	# Seri 1'den küçük veya 13'ten büyük bir sayıya ihtiyaç duymamalı
	var extra_left = wildcards - (span - vals.size())  # Sola genişletilebilecek
	var start_min = vals[0] - extra_left
	var start_max = vals[0]
	var end_val = start_min + group.size() - 1
	if start_min < 1: start_min = 1
	end_val = start_min + group.size() - 1
	if end_val > 13: return false
	return true

# ─── Skor ────────────────────────────────────────────────────────────────────
static func get_group_sum(group: Array[OkeyTileData], okey_tile: OkeyTileData = null) -> int:
	if not is_valid_group(group, okey_tile): return 0
	if is_same_number_group(group, okey_tile):
		for t in group:
			if not is_wildcard(t, okey_tile):
				return t.value * group.size()
		return 0
	if is_run_group(group, okey_tile):
		var wildcards = 0
		var vals: Array = []
		for t in group:
			if is_wildcard(t, okey_tile):
				wildcards += 1
			else:
				vals.append(t.value)
		vals.sort()
		if vals.is_empty(): return 0
		# Wildcard'ları mümkün olan en sağa (büyük değerlere) ekle
		var end_val = vals[-1] + wildcards
		if end_val > 13: end_val = 13
		var start = end_val - group.size() + 1
		if start < 1: start = 1
		var total = 0
		for i in range(group.size()):
			total += start + i
		return total
	return 0

# ─── Çift Kontrolü ───────────────────────────────────────────────────────────
static func is_pair(tile1: OkeyTileData, tile2: OkeyTileData, okey_tile: OkeyTileData = null) -> bool:
	# Wildcard çift oluşturamaz (101 kuralı)
	if is_wildcard(tile1, okey_tile) or is_wildcard(tile2, okey_tile): return false
	return tile1.value == tile2.value and tile1.color == tile2.color
