class_name CellState extends RefCounted

enum Occupant { EMPTY = 0, PLAYER = 1, AI = 2 }
enum PieceType { NORMAL = 0, WEIGHTED = 1, GHOST = 2, VOLATILE = 3 }

var col: int = 0
var row: int = 0
var occupant: Occupant = Occupant.EMPTY
var piece_type: PieceType = PieceType.NORMAL
var modifiers: Array[String] = []
var locked: bool = false
var frozen: bool = false
