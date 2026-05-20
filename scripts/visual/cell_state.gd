class_name CellState extends RefCounted

enum Occupant { EMPTY = 0, PLAYER = 1, AI = 2 }
enum PieceType { NORMAL = 0, PRISM = 1, COIN = 2, EMBER = 3, SHARD = 4 }

var col: int = 0
var row: int = 0
var occupant: Occupant = Occupant.EMPTY
var piece_type: PieceType = PieceType.NORMAL
var modifier: String = ""
var locked: bool = false
var frozen: bool = false
