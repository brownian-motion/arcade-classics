extends CharacterBody2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Sprite.play()
	self.y_sort_enabled = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if self.velocity.x < 0:
		face_left()
	elif self.velocity.x > 0:
		face_right()

func face_left() -> void:
	$Sprite.flip_h = true

func face_right() -> void:
	$Sprite.flip_h = false
