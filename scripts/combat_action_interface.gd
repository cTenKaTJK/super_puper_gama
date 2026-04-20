extends Panel

class_name ActionMenu

signal action_selected(action_name: String)
signal menu_closed

@onready var hbox: HBoxContainer = $HBoxContainer
var buttons: Array[Button] = []
var selected_index: int = 0
var last_press_time: int = 0   # время последнего обработанного нажатия (в миллисекундах)

func set_actions(actions: Array):
	for btn in buttons:
		btn.queue_free()
	buttons.clear()
	
	for action in actions:
		var btn = Button.new()
		btn.text = action
		btn.pressed.connect(_on_button_pressed.bind(action))
		btn.focus_mode = Control.FOCUS_ALL
		hbox.add_child(btn)
		buttons.append(btn)
	
	selected_index = 0
	if buttons.size() > 0:
		buttons[selected_index].grab_focus()

func _on_button_pressed(action: String):
	action_selected.emit(action)
	hide_menu()

func show_menu():
	visible = true
	selected_index = 0
	if buttons.size() > 0:
		buttons[selected_index].grab_focus()
	last_press_time = 0  # сброс блокировки

func hide_menu():
	visible = false
	release_focus()

func _input(event):
	if not visible:
		return
	
	if not (event is InputEventKey):
		return
	
	# Обрабатываем только нажатие, не повтор (echo)
	if not event.pressed or event.echo:
		return
	
	var current_time = Time.get_ticks_msec()
	# Если прошло меньше 150 мс с предыдущего нажатия — игнорируем
	if current_time - last_press_time < 150:
		get_viewport().set_input_as_handled()
		return
	
	match event.keycode:
		KEY_A:
			selected_index = max(0, selected_index - 1)
			if selected_index < buttons.size():
				buttons[selected_index].grab_focus()
			last_press_time = current_time
			get_viewport().set_input_as_handled()
		KEY_D:
			selected_index = min(buttons.size() - 1, selected_index + 1)
			if selected_index >= 0:
				buttons[selected_index].grab_focus()
			last_press_time = current_time
			get_viewport().set_input_as_handled()
		KEY_W:
			if selected_index >= 0 and selected_index < buttons.size():
				buttons[selected_index].emit_signal("pressed")
			last_press_time = current_time
			get_viewport().set_input_as_handled()
		KEY_ESCAPE:
			hide_menu()
			menu_closed.emit()
			last_press_time = current_time
			get_viewport().set_input_as_handled()
	
	# Блокируем стандартные клавиши навигации, чтобы они не мешали
	if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("ui_cancel") and visible:
		get_viewport().set_input_as_handled()
