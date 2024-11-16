extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$UI.find_child("GameSelect").get_child(0).grab_focus()


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
#
#func _unhandled_input(event: InputEvent) -> void:
	#if event.is_action("ui_select"):
		#var focus = get_viewport().gui_get_focus_owner()
		#if(focus != null && focus is Button):
			#focus = (Button) focus
			#focus.
		#
		#
		
