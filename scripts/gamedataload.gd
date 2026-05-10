extends Node

var level: int = 1
var enemy_base_hp: int = 50
var enemy_base_attack: int = 10
var turn_time_limit: float = 3.0
var time_to_counter: int = 1200

func increase_difficulty():
	level += 1
	enemy_base_hp = int(enemy_base_hp * 1.2)
	enemy_base_attack = int(enemy_base_attack + (level - 1) * 3)
	turn_time_limit = max(1.0, turn_time_limit * 0.9)
	time_to_counter = max(500, time_to_counter * 0.9)
	print("Сложность увеличена до уровня ", level)
