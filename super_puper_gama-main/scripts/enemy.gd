extends Node2D


class_name Enemy
signal health_updated(current_hp, max_hp)

var display_name: String = "Enemy"
var max_hp: int = 10
var attack_power: int = 1
var count: int = 0

var current_hp: int

func _ready():
	current_hp = max_hp

func choose_attack():
	var attacks = ["up", "middle", "down"]
	var random_index = randi() % attacks.size()
	return attacks[random_index]


func take_damage(damage: int):
	current_hp -= damage
	if current_hp < 0:
		current_hp = 0
	print(display_name + " получил " + str(damage) + " урона. Осталось HP: " + str(current_hp))
	health_updated.emit(current_hp, max_hp)


func is_alive() -> bool:
	return current_hp > 0
