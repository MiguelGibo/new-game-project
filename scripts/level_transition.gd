extends CanvasLayer

func _ready() -> void:
	# Start black then fade to transparent
	var overlay = $ColorRect
	overlay.color = Color(0, 0, 0, 1)
	
	var tween = create_tween()
	tween.tween_property(overlay, "color", Color(0, 0, 0, 0), 0.5)
	
	# Reset transitioning flag after fade in
	tween.tween_callback(func():
		GameManager.is_transitioning = false
	)
