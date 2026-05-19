class_name PieceBag extends RefCounted

const BAG_SIZE: int = 7

var _pieces: Array[Piece] = []
var _index: int = 0


func _init(p_owner: Piece.Owner) -> void:
	for i in BAG_SIZE:
		_pieces.append(Piece.new(p_owner))


func current() -> Piece:
	return _pieces[_index]


func peek(offset: int) -> Piece:
	return _pieces[(_index + offset) % BAG_SIZE]


func get_queue_pieces(count: int) -> Array:
	var result: Array = []
	for i in count:
		result.append(peek(i + 1))
	return result


func advance() -> void:
	_index = (_index + 1) % BAG_SIZE
