class_name PieceVisualUtil extends RefCounted
## Piece type / modifier visuals from DataRegistry — shared by shop and board themes.

const PIECE_TYPE_IDS: PackedStringArray = ["NORMAL", "PRISM", "COIN", "EMBER", "SHARD"]


static func registry_id(piece_type: CellState.PieceType) -> String:
	if piece_type < 0 or piece_type >= PIECE_TYPE_IDS.size():
		return "NORMAL"
	return PIECE_TYPE_IDS[piece_type]


static func queue_entry_from_piece(piece: Piece) -> QueueEntry:
	var qe := QueueEntry.new()
	if piece == null:
		return qe
	qe.piece_type = cell_piece_type(piece.type)
	qe.modifier = piece.modifier
	return qe


static func cell_piece_type(t: Piece.Type) -> CellState.PieceType:
	match t:
		Piece.Type.NORMAL:
			return CellState.PieceType.NORMAL
		Piece.Type.PRISM:
			return CellState.PieceType.PRISM
		Piece.Type.COIN:
			return CellState.PieceType.COIN
		Piece.Type.EMBER:
			return CellState.PieceType.EMBER
		Piece.Type.SHARD:
			return CellState.PieceType.SHARD
	return CellState.PieceType.NORMAL


static func registry_id_from_piece(t: Piece.Type) -> String:
	match t:
		Piece.Type.NORMAL:
			return "NORMAL"
		Piece.Type.PRISM:
			return "PRISM"
		Piece.Type.COIN:
			return "COIN"
		Piece.Type.EMBER:
			return "EMBER"
		Piece.Type.SHARD:
			return "SHARD"
	return "NORMAL"


static func piece_type_data(piece_type: CellState.PieceType) -> PieceTypeData:
	return DataRegistry.get_piece_type(registry_id(piece_type))


static func piece_type_data_from_piece(t: Piece.Type) -> PieceTypeData:
	return DataRegistry.get_piece_type(registry_id_from_piece(t))


static func shader_style_index(piece_type: CellState.PieceType) -> int:
	return shader_style_index_from_registry_id(registry_id(piece_type))


static func shader_style_index_from_piece(t: Piece.Type) -> int:
	return shader_style_index_from_registry_id(registry_id_from_piece(t))


static func shader_style_index_from_registry_id(id: String) -> int:
	var data: PieceTypeData = DataRegistry.get_piece_type(id)
	if data == null:
		return 0
	match data.shader_style:
		"rainbow":
			return 1
		"gold":
			return 2
		"ember":
			return 3
		"crystal":
			return 4
		_:
			return 0


static func modifier_initial(modifier_id: String) -> String:
	var md: ModifierData = DataRegistry.get_modifier(modifier_id)
	if md != null:
		if not md.initial.is_empty():
			return md.initial
		if not modifier_id.is_empty():
			return modifier_id[0]
	return "?"


static func modifier_badge_color(modifier_id: String) -> Color:
	var md: ModifierData = DataRegistry.get_modifier(modifier_id)
	if md != null:
		return md.badge_color
	return UITheme.ACCENT


static func modifier_icon(modifier_id: String) -> Texture2D:
	var md: ModifierData = DataRegistry.get_modifier(modifier_id)
	if md != null:
		return md.icon
	return null
