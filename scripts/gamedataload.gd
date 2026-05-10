extends Node

var level: int = 1
var hero_curr_hp: int = 50
var max_level: int = 1
var enemy_base_hp: int = 30
var enemy_base_attack: int = 10
var turn_time_limit: float = 6.0
var time_to_counter = 2400

func _ready():
	load_data()

func increase_difficulty():
	level += 1
	
	if level == 2:
		turn_time_limit *= 0.5
		time_to_counter *= 0.5
	elif level > 2:
		enemy_base_hp = max(80, int(enemy_base_hp * 1.1))
		enemy_base_attack = min(49, int(enemy_base_attack + (level - 1) * 3))
		turn_time_limit = max(1.4, turn_time_limit * 0.8)
		time_to_counter = max(700, time_to_counter * 0.85)
	print("Сложность увеличена до уровня ", level)
	
	if level > max_level:
		max_level = level
		save_data()

func save_data():
	var config = ConfigFile.new()
	config.set_value("stats", "max_level", max_level)
	config.save("user://game_data.cfg")

func load_data():
	var config = ConfigFile.new()
	if config.load("user://game_data.cfg") == OK:
		max_level = config.get_value("stats", "max_level", 1)
	else:
		max_level = 1
	print("Загружен максимальный уровень: ", max_level)

func reset_game():
	level = 1
	enemy_base_hp = 20
	enemy_base_attack = 5
	turn_time_limit = 3.0
	time_to_counter = 2400
