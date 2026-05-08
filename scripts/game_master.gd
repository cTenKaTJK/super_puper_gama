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
		Vector2(490, 100),  
		Vector2(520, 200),  
		Vector2(550, 300),  
		Vector2(580, 400),  
		Vector2(620, 500)
		 
	]}

var middle_slash_slider: Dictionary = {"type" : "slash",
	"checkpoints" : [
		Vector2(350, 300),  
		Vector2(450, 300), 
		Vector2(550, 300),  
		Vector2(650, 300), 
		Vector2(750, 300)   
	]}

var down_slash_slider: Dictionary = {"type" : "slash",
	"checkpoints" : [
		Vector2(490, 500),  
		Vector2(520, 400),  
		Vector2(550, 300),  
		Vector2(580, 200),  
		Vector2(620, 100)    
	]}
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


# Переменные
var current_enemy_attack_type: String = ""
var is_enemy_attacking: bool = false

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
		# Подключаем сигналы
		if not enemy.attack_started.is_connected(_on_enemy_attack_started):
			enemy.attack_started.connect(_on_enemy_attack_started)
		if not enemy.attack_hit.is_connected(_on_enemy_attack_hit):
			enemy.attack_hit.connect(_on_enemy_attack_hit)
		
		# Запускаем атаку (замах + сразу сигнал для слайдера)
		enemy.start_attack()
		is_enemy_attacking = true
	else:
		end_enemy_turn()

# Начало атаки - спавним слайдер
func _on_enemy_attack_started(attack_type: String):
	print("Атака началась! Спавн слайдера для: ", attack_type)
	current_enemy_attack_type = attack_type
	
	# Спавним слайдер
	match attack_type:
		"up":
			spawn_slash_slider(up_slash_slider)
		"middle":
			spawn_slash_slider(middle_slash_slider)
		"down":
			spawn_slash_slider(down_slash_slider)

# Удар прошел (только если игрок промахнулся)
func _on_enemy_attack_hit(attack_type: String):
	print("Удар нанесен! Игрок получает урон")
	hero.take_damage(enemy.attack_power)
	update_batteries(hero.current_hp)
	
	if not hero.is_alive():
		lose()
	
	end_enemy_turn()

func end_enemy_turn():
	is_enemy_attacking = false
	current_enemy_attack_type = ""
	await get_tree().create_timer(0.5).timeout
	is_player_turn = true
	end_turn()

func end_turn():
	print("Конец хода!")
	turns += 1
	start_turn()
	
func win():
	print("ПОБЕДА!")
	
	if turn_timer.is_stopped() == false:
		turn_timer.stop()
	if is_menu_open:
		close_menu()
	
	action_menu.visible = false
	death_screen.visible = true
	
	var label = death_screen.get_node("Label") 
	if label:
		label.text = "ПОБЕДА!"
	
	if restart_btn:
		restart_btn.disabled = false
		restart_btn.grab_focus()

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
	
	# ПРОВЕРЯЕМ, ЖИВ ЛИ ВРАГ
	if not enemy.is_alive():
		win()  # Вызываем победу
		return
	
	# Если враг жив - продолжаем бой
	start_enemy_turn()


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
	
	if is_enemy_attacking:
		# 1. Сначала анимация героя (с правильным типом атаки)
		await hero.play_counter_animation(current_enemy_attack_type)
		
		# 2. Наносим урон врагу
		enemy.take_damage(hero.attack_power)
		
		# 3. Проверяем не умер ли враг
		if not enemy.is_alive():
			win()
			return
		
		# 4. Отменяем атаку врага с анимацией
		enemy.cancel_attack()
	
	_on_obj_hit(slider)
	end_enemy_turn()

func _on_counter_fail(slider):
	print("Промах!")
	
	# Наносим удар
	if is_enemy_attacking:
		enemy.execute_hit()
	
	_on_obj_miss(slider)
	# Урон будет нанесен в _on_enemy_attack_hit

func _on_turn_timer_timeout():
	if hero.is_alive() and is_player_turn:
		print("Время вышло!")
		
		# Если враг атакует - наносим удар
		if is_enemy_attacking:
			enemy.execute_hit()
		
		start_enemy_turn()


func _on_obj_hit(obj):
	# Проверяем, что объект еще существует
	if not is_instance_valid(obj):
		return
	
	var pos = obj.global_position
	if obj.has_method("get_end_position"):
		pos = obj.get_end_position()
	
	show_popup("Counter!", pos)
	active_objects.erase(obj)

func _on_obj_miss(obj):
	# Проверяем, что объект еще существует
	if not is_instance_valid(obj):
		return
	
	var pos = obj.global_position
	if obj.has_method("get_end_position"):
		pos = obj.get_end_position()
	
	show_popup("Miss!", pos)
	active_objects.erase(obj)


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
	
