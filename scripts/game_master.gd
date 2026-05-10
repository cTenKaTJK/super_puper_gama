extends Node


@export var slider_scene = preload("res://scenes/Slider.tscn")
@export var popup_scene = preload("res://scenes/Particles.tscn")
@export var hero: Hero
@export var enemy: Enemy
@export var battery_container: BatteryContainer
@export var battery_scene: PackedScene
@export var action_menu: ActionMenu
@export var death_screen: CanvasLayer
@export var win_screen: CanvasLayer

@export var turn_time_limit: float = 2.0
var time_to_counter: int = 1200
var turn: int = 0
var buff_turn: int

@onready var turn_timer: Timer = $TurnTimer
@onready var restart_btn = $"../DeathScreen/DeathRestart"
@onready var win_next_btn = $"../WinScreen/WinNext"


var is_player_turn: bool = false
var is_hero_buffed: bool = false
var is_menu_open: bool = false

var start_time
var actions: Dictionary = {
	"": _foo, 
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
var circle_slider : Dictionary = {"type" : "circle",
	"checkpoints" : [
		Vector2(376, 324),
		Vector2(435, 183),
		Vector2(576, 124),
		Vector2(717, 183),
		Vector2(776, 324),
		Vector2(717, 465),
		Vector2(576, 524),
		Vector2(435, 465)
		]}
var wave_slider : Dictionary = {"type" : "wave",
	"checkpoints" : [
		Vector2(400, 500),
		Vector2(440, 350),
		Vector2(480, 200),
		Vector2(520, 350),
		Vector2(560, 500),
		Vector2(600, 350),
		Vector2(640, 200),
		Vector2(680, 350),
		Vector2(720, 500),
		Vector2(760, 350),
		Vector2(800, 200),
		Vector2(840, 350),
		Vector2(880, 500)
		]}
var turns: int = 0
var active_objects: Array = []
var batteries: Array = []

var music_player: AudioStreamPlayer
var music_tracks: Array = []

var sfx_player: AudioStreamPlayer
var hit_sound: AudioStream
var hurt_sound: AudioStream


		
func _ready():
	
	sfx_player = AudioStreamPlayer.new()
	add_child(sfx_player)
	sfx_player.volume_db = -10
	var hit_path = "res://src/sfx/hit.mp3"          
	var hurt_path = "res://src/sfx/hurt.mp3"
	if ResourceLoader.exists(hit_path):
		hit_sound = load(hit_path)
	if ResourceLoader.exists(hurt_path):
		hurt_sound = load(hurt_path)
	
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	
	music_player.volume_db = -20
	
	var dir = DirAccess.open("res://src/ost/battle_themes/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".mp3"):
				var track = load("res://src/ost/battle_themes/" + file_name)
				if track:
					music_tracks.append(track)
			file_name = dir.get_next()
	if music_tracks.size() > 0:
		var random_track = music_tracks[randi() % music_tracks.size()]
		music_player.stream = random_track
		music_player.play()
	
	find_batteries()
	if hero:
		hero.current_hp = GameDataLoad.hero_curr_hp
		update_batteries(hero.current_hp)
	if enemy:
		enemy.max_hp = GameDataLoad.enemy_base_hp
		enemy.current_hp = enemy.max_hp
		enemy.attack_power = GameDataLoad.enemy_base_attack
		enemy.health_updated.emit(enemy.current_hp, enemy.max_hp)
		turn_time_limit = GameDataLoad.turn_time_limit
		time_to_counter = GameDataLoad.time_to_counter
	action_menu.action_selected.connect(_on_action_selected)
	start_turn()
	if restart_btn:
		restart_btn.pressed.connect(_return_to_menu)
	if win_next_btn:
		win_next_btn.pressed.connect(_next_battle)
		
		
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
		var should_be_visible = (i < (current_hp * 0.1))
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
	turn += 1
	if is_hero_buffed and (turn - buff_turn) > 1:
		is_hero_buffed = false
	print("-----------------------------------")
	print("Начало хода")
	is_player_turn = true
	turn_timer.wait_time = randi_range(turn_time_limit * 0.8, turn_time_limit * 1.2)
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
		"circle":
			spawn_slash_slider(circle_slider)
		"wave":
			spawn_slash_slider(wave_slider)

# Удар прошел (только если игрок промахнулся)
func _on_enemy_attack_hit():
	print("Удар нанесен! Игрок получает урон")
	play_sound(hurt_sound)
	hero.take_damage(enemy.attack_power)
	update_batteries(hero.current_hp)
	if not hero.is_alive():
		lose()
	end_enemy_turn()

func end_enemy_turn():
	is_enemy_attacking = false
	current_enemy_attack_type = ""
	await get_tree().create_timer(0.1).timeout
	is_player_turn = true
	end_turn()

func end_turn():
	print("Конец хода!")
	turns += 1
	start_turn()
	
func win():
	GameDataLoad.hero_curr_hp = hero.current_hp
	if turn_timer.is_stopped() == false:
		turn_timer.stop()
	if is_menu_open:
		close_menu()
	win_screen.visible = true
	action_menu.visible = false
	if win_next_btn:
		win_next_btn.grab_focus()

func lose():
	if turn_timer.is_stopped() == false:
		turn_timer.stop()
	if is_menu_open:
		close_menu()
	death_screen.visible = true
	action_menu.visible = false
	if restart_btn:
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


func _foo():
	pass


func _heal_action():
	hero.take_damage(-10)
	show_popup("Heal +10", Vector2(350,200), Color.LIME)
	update_batteries(hero.current_hp)
	start_enemy_turn()


func _buff_action():
	show_popup("Buff x1.75", Vector2(350,200), Color.CYAN)
	is_hero_buffed = true
	buff_turn = turn
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
	slider.lifetime = time_to_counter
	
	slider.slider_hit.connect(_on_counter_success)
	slider.slider_miss.connect(_on_counter_fail)
	
	add_child(slider)
	active_objects.push_back(slider)

func _on_counter_success(slider):
	print("Успешное отражение!")
	
	play_sound(hit_sound)
	
	if is_enemy_attacking:
		await hero.play_counter_animation(current_enemy_attack_type)
		
		enemy.take_damage(hero.attack_power + (int(is_hero_buffed) * hero.attack_power * 0.75))
		
		if not enemy.is_alive():
			win()
			return
		
		enemy.cancel_attack()
	
	_on_obj_hit(slider)
	end_enemy_turn()

func _on_counter_fail(slider):
	print("Промах!")
	if is_enemy_attacking:
		enemy.execute_hit()
	_on_enemy_attack_hit()
	_on_obj_miss(slider)


func _on_turn_timer_timeout():
	if hero.is_alive() and is_player_turn:
		print("Время вышло!")
		if is_enemy_attacking:
			enemy.execute_hit()
		start_enemy_turn()


func _on_obj_hit(obj):
	if not is_instance_valid(obj):
		return
	
	var pos = obj.global_position
	if obj.has_method("get_end_position"):
		pos = obj.get_end_position()
	
	show_popup("Counter!", pos, Color.CYAN)
	active_objects.erase(obj)

func _on_obj_miss(obj):
	if not is_instance_valid(obj):
		return
	
	var pos = obj.global_position
	if obj.has_method("get_end_position"):
		pos = obj.get_end_position()
	
	show_popup("Miss!", pos, Color.INDIAN_RED)
	active_objects.erase(obj)


func show_popup(text: String, pos: Vector2, color):
	if popup_scene:
		var popup = popup_scene.instantiate()
		popup.display_text = text
		popup.text_color = color
		popup.position = pos
		add_child(popup)


func _return_to_menu():
	GameDataLoad.reset_game()
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
	
func _next_battle():
	print("Переход на следующий уровень")
	GameDataLoad.increase_difficulty()
	get_tree().reload_current_scene()
	
	
func play_sound(sound: AudioStream):
	if sound and sfx_player:
		sfx_player.stream = sound
		sfx_player.play()
