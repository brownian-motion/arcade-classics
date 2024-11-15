extends Node2D

var scroll_speed = 400 # pixels/s
var offset = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.t
func _process(delta: float) -> void:
	pass
	#offset += scroll_speed * delta
	#$ParallaxFront.scroll_offset.x = -(int(offset) % int($ParallaxFront.repeat_size.x))
	#$ParallaxBack.scroll_offset.x = -(int(offset) % int($ParallaxBack.repeat_size.x))
