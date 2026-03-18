extends Resource
class_name OkeyTileData

@export var value: int = 1 # 1 to 13
@export var color: int = 0 # Maps to Constants.TileColor
@export var is_joker: bool = false
@export var id: int = -1 # Unique ID for each tile to differentiate duplicate tiles

func _init(_value: int = 1, _color: int = 0, _is_joker: bool = false, _id: int = -1) -> void:
	value = _value
	color = _color
	is_joker = _is_joker
	id = _id

func get_display_color() -> Color:
	if is_joker:
		return Constants.HEX_COLORS[Constants.TileColor.JOKER]
	return Constants.HEX_COLORS.get(color, Color.WHITE)

func get_display_text() -> String:
	if is_joker:
		return "J"
	return str(value)

func compare(other: OkeyTileData) -> int:
	# Sorting logic: Color -> Value
	if color < other.color:
		return -1
	elif color > other.color:
		return 1
	
	if value < other.value:
		return -1
	elif value > other.value:
		return 1
		
	return 0

func matches(other: OkeyTileData) -> bool:
	return self.value == other.value and self.color == other.color and self.is_joker == other.is_joker
