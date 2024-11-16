extends Control

signal continue_chosen()
signal quit_chosen()

func show_menu() -> void:
	print("showing pause menu")
	self.visible = true
	$Buttons/Continue.grab_focus()
	
func hide_menu() -> void:
	print("hiding pause menu")
	self.visible = false
	for button in $Buttons.get_children():
		button.release_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_released("pause_toggle"):
		get_viewport().set_input_as_handled()
		unpause()
		return

func unpause() -> void:
	get_tree().paused = false
	self.hide_menu()
	self.continue_chosen.emit()
