extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.find_child("StartButton").grab_focus()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_start_button_pressed() -> void:
	var scene = preload("res://arcade_menu.tscn").instantiate()
#	 TODO: animate the transition
	get_tree().root.add_child(scene)
	get_tree().root.remove_child(self)
