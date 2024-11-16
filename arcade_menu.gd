extends Control

const games = [
	{"id": "StartPacMan", "res": "res://pacman.tscn", "label_en": "Pac-Man"},
	{"id": "StartBreakout", "res": "res://breakout.tscn", "label_en": "Breakout"},
]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var game_select = $UI.find_child("GameSelect")
	for child in game_select.get_children():
		game_select.remove_child(child)
	for game in games:
		var id = game.id
		var button = Button.new()
		button.text = game.label_en
		button.name = id
		button.pressed.connect(func(): self.on_game_selected(game))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		game_select.add_child(button)
	$UI.find_child("GameSelect").get_child(0).grab_focus()

func on_game_selected(game) -> void:
	print("clicked "+game.id)
	get_tree().change_scene_to_file(game.res)
		
