extends Node

# Okey 101 Constants

enum TileColor { YELLOW, BLUE, BLACK, RED, JOKER }

const COLOR_NAMES = {
	TileColor.YELLOW: "Yellow",
	TileColor.BLUE: "Blue",
	TileColor.BLACK: "Black",
	TileColor.RED: "Red",
	TileColor.JOKER: "Joker",
}

const HEX_COLORS = {
	TileColor.YELLOW: Color.YELLOW,
	TileColor.BLUE: Color.CORNFLOWER_BLUE,
	TileColor.BLACK: Color.DARK_SLATE_GRAY,
	TileColor.RED: Color.CRIMSON,
	TileColor.JOKER: Color.PURPLE,
}

const MAX_NUMBER = 13
const NUM_PLAYERS = 4
const TILES_PER_PLAYER = 21 # Initial hand size for 101
const TILES_PER_PLAYER_START = 22 # The person who starts gets 22
const JOKER_VALUE = 0

# Opening 101 rules
const MIN_OPENING_SUM = 101
const MIN_PAIRS_FOR_OPENING = 5
