extends Node

# Okey 101 Constants

enum TileColor { YELLOW, BLUE, BLACK, RED, JOKER }

## Oyun modları
enum GameMode {
	KATLAMASIZ,   # Klasik 101 — her oyuncu için eşit 101 puan baraji
	KATLAMALI     # Katlayan kural — her açan bir öncekini geçmek zorunda
}

const COLOR_NAMES = {
	TileColor.YELLOW: "Sarı",
	TileColor.BLUE:   "Mavi",
	TileColor.BLACK:  "Siyah",
	TileColor.RED:    "Kırmızı",
	TileColor.JOKER:  "Joker",
}

const HEX_COLORS = {
	TileColor.YELLOW: Color(1.0,  0.85, 0.1,  1),
	TileColor.BLUE:   Color(0.25, 0.55, 1.0,  1),
	TileColor.BLACK:  Color(0.15, 0.15, 0.15, 1),
	TileColor.RED:    Color(0.9,  0.15, 0.15, 1),
	TileColor.JOKER:  Color(0.7,  0.3,  1.0,  1),
}

const MAX_NUMBER              = 13
const NUM_PLAYERS             = 4
const TILES_PER_PLAYER        = 21
const TILES_PER_PLAYER_START  = 22
const JOKER_VALUE             = 0

# El açma baraji
const MIN_OPENING_SUM         = 101
const MIN_PAIRS_FOR_OPENING   = 5

# Oyun sırası (saat yönünün tersi = +1 mod 4, Türk standart)
const TURN_ORDER_CCW          = true
