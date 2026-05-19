extends ColorRect
## Cream canvas with a subtle star pattern for full-screen backgrounds.


func _draw() -> void:
	UITheme.draw_star_pattern(self, Rect2(Vector2.ZERO, size))
