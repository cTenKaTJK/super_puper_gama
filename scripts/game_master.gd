extends Node


@export var slider_scene = preload("res://scenes/Slider.tscn")
@export var popup_scene = preload("res://scenes/Particles.tscn")
@export var hero: Hero
@export var enemy: Enemy
@export var battery_container: BatteryContainer
@export var battery_scene: PackedScene
@export var action_menu: ActionMenu
@export var death_screen: CanvasLayer

@export var turn_time_limit: float = 2.0

@onready var turn_timer: Timer = $TurnTimer
@onready var restart_btn = $"../DeathScreen/DeathRestart"


var is_player_turn: bool = false
var is_menu_open: bool = false

var start_time
var actions: Dictionary = {
	"Атака": _attack_action,
	"Лечение": _heal_action,
	"Усиление": _buff_action,}
var up_slash_slider: Dictionary = {"type" : "slash",
	"checkpoints" : [
		Vector2(400,200),
		Vector2(450,160),
		Vector2(500,120),
		Vector2(550,80),
		Vector2(600,40)]}
var middle_slash_slider: Dictionary = {"type" : "slash",
	"checkpoints" : [
		Vector2(400,300),
		Vector2(450,300),
		Vector2(500,300),
		Vector2(550,300),
		Vector2(600,300)]}
var down_slash_slider: Dictionary = {"type" : "slash",
	"checkpoints" : [
		Vector2(400,400),
		Vector2(450,440),
		Vector2(500,480),
		Vector2(550,520),
		Vector2(600,560)]}
		
var turns: int = 0
var active_objects: Array = []
var batteries: Array = []


func _ready():
	find_batteries()
	if hero:
		update_batteries(hero.current_hp)
	action_menu.action_selected.connect(_on_action_selected)
	start_turn()
	if restart_btn:
		restart_btn.pressed.connect(_restart_combat)
		
		
func _input(event):
	# открытие меню атаки только во время хода игрока
	if hero.is_alive() and is_player_turn and not is_menu_open and event.is_action_pressed("ui_accept"):
		open_menu()

'''
#############################################################
						БАТАРЕЙКИ
#############################################################
'''

func find_batteries():
	batteries.clear()
	var container = get_node("BatteryContainer")
	if container == null:
		print("Ошибка: BatteryContainer не найден на сцене!")
		return
	# Проверяем, что контейнер назначен
	
	for child in container.get_children():
		if child.name.begins_with("Battery"):
			batteries.append(child)
		print("Найдена батарейка: ", child.name)
	
	batteries.sort_custom(func(a, b): return a.name < b.name)
	print("Найдено батареек: ", batteries.size())


func update_batteries(current_hp: int):
	for i in range(batteries.size()):
		var should_be_visible = (i < current_hp)
		if batteries[i].visible != should_be_visible:
			if should_be_visible:
					# Анимация появления
				var tween = create_tween()
				tween.tween_property(batteries[i], "modulate:a", 1.0, 0.2)
				batteries[i].visible = true
			else:
					# Анимация исчезновения
				var tween = create_tween()
				tween.tween_property(batteries[i], "modulate:a", 0.0, 0.2)
				await tween.finished
				batteries[i].visible = false
			batteries[i].visible = should_be_visible

'''
#############################################################
						ХОДЫ
#############################################################
'''

func start_turn():
	print("-----------------------------------")
	print("Начало хода")
	is_player_turn = true
	turn_timer.wait_time = turn_time_limit
	turn_timer.start()


func start_enemy_turn():
	if is_menu_open:
		close_menu()
	if turn_timer.is_stopped() == false:
		turn_timer.stop()
	print("Ход врага.")
	is_player_turn = false
	await get_tree().create_timer(0.7).timeout
	enemy_attack()


func enemy_attack():
	print("Враг атакует!")
	if hero.is_alive():
		match enemy.choose_attack():
			"up":
				print("Атака сверху!")
				spawn_slash_slider(up_slash_slider)
			"middle":
				print("Прямая атака!")
				spawn_slash_slider(middle_slash_slider)
			"down":
				print("Атака снизу!")
				spawn_slash_slider(down_slash_slider)
	await get_tree().create_timer(2.0).timeout
	is_player_turn = true
	end_turn()


func end_turn():
	print("Конец хода!")
	turns += 1
	start_turn()

func lose():
	if turn_timer.is_stopped() == false:
		turn_timer.stop()
	if is_menu_open:
		close_menu()
	death_screen.visible = true
	action_menu.visible = false
	if restart_btn:
		restart_btn.disabled = false
		restart_btn.grab_focus()
	

'''
#############################################################
					МЕНЮ АТАКИ
#############################################################
'''

func open_menu():
	is_menu_open = true
	action_menu.set_actions(actions.keys())
	action_menu.show_menu()

func close_menu():
	is_menu_open = false
	action_menu.hide_menu()

func _on_action_selected(action_name: String):
	close_menu()
	if actions.has(action_name):
		actions[action_name].call()
	else:
		print("Неизвестное действие: ", action_name)


func _attack_action():
	enemy.take_damage(hero.attack_power)
	if enemy.is_alive():
		start_enemy_turn()
	else:
		# конец боя
		pass


func _heal_action():
	hero.take_damage(-1)
	update_batteries(hero.current_hp)
	start_enemy_turn()


func _buff_action():
	hero.attack_power += 2
	print("Сила атаки увеличена на 2!")
	start_enemy_turn()

'''
#############################################################
					СЛАЙДЕРЫ (ЗАЩИТА)
#############################################################
'''

func spawn_slash_slider(event: Dictionary):
	var slider = slider_scene.instantiate()
	slider.checkpoints = event.checkpoints
	slider.creation_time = Time.get_ticks_msec()
	slider.lifetime = 1000
	
	slider.slider_hit.connect(_on_counter_success)
	slider.slider_miss.connect(_on_counter_fail)
	
	add_child(slider)
	active_objects.push_back(slider)


func _on_counter_success(slider):
	print("Успешное отражение!")
	_on_obj_hit(slider)
	
	
func _on_counter_fail(slider):
	print("Промах!")
	hero.take_damage(enemy.attack_power)
	_on_obj_miss(slider)
	update_batteries(hero.current_hp)
	if not hero.is_alive():
		lose()


func _on_obj_hit(obj):
	var pos = obj.global_position
	if obj.has_method("get_end_position"):
		pos = obj.get_end_position()
	show_popup("Counter!", pos)
	active_objects.erase(obj)

func _on_obj_miss(obj):
	var pos = obj.global_position
	if obj.has_method("get_end_position"):
		pos = obj.get_end_position()
	show_popup("Miss!", pos)
	active_objects.erase(obj)


func _on_turn_timer_timeout():
	if hero.is_alive() and is_player_turn:
		print("Время вышло! Ход переходит врагу.")
		start_enemy_turn()


func show_popup(text: String, pos: Vector2):
	if popup_scene:
		var popup = popup_scene.instantiate()
		popup.position = pos
		popup.get_node("ParticleLabel").text = text
		add_child(popup)


func _restart_combat() -> void:
	if turn_timer.is_stopped() == false:
		turn_timer.stop()
	get_tree().reload_current_scene()
	
