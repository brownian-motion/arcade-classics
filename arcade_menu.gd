extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_start_breakout_pressed() -> void:
	var scene = preload("res://breakout.tscn").instantiate()
#	 TODO: animate the transition
	get_tree().root.add_child(scene)
	get_tree().root.remove_child(self)
	
	
func _on_start_pac_man_pressed() -> void:
	#var scene = preload("res://pacman.tscn").instantiate()
##	 TODO: animate the transition
	#get_tree().root.add_child(scene)
	#get_tree().root.remove_child(self)
	pass
