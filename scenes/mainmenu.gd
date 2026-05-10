extends CanvasLayer

@onready var record_label = $Record
@onready var start_button = $VBoxContainer/StartButton
@onready var quit_button = $VBoxContainer/QuitButton
@onready var help_button = $HelpButton
@onready var help_panel = $HelpPanel
@onready var help_label = $HelpPanel/HelpLabel

var tween: Tween
var is_open: bool = false

func _ready():
	update_record_display()
	start_button.pressed.connect(_on_start_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)
	help_panel.visible = false
	help_button.pressed.connect(_toggle_help)

func _input(event: InputEvent):
	if is_open and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = event.global_position
		if not help_panel.get_global_rect().has_point(mouse_pos):
			_close_panel()

func update_record_display():
	record_label.text = "Рекорд: " + str(GameDataLoad.max_level)

func _open_panel():
	help_panel.visible = true
	help_panel.modulate.a = 0.0
	tween = create_tween()
	tween.tween_property(help_panel, "modulate:a", 1.0, 0.2)
	is_open = true

func _close_panel():
	tween = create_tween()
	tween.tween_property(help_panel, "modulate:a", 0.0, 0.2)
	await tween.finished
	help_panel.visible = false
	is_open = false
	
func _toggle_help():
	if tween and tween.is_running():
		return
	if is_open:
		_close_panel()
	else:
		_open_panel()

func _on_start_pressed():
	get_tree().change_scene_to_file("res://scenes/Combat.tscn")

func _on_quit_pressed():
	get_tree().quit()
