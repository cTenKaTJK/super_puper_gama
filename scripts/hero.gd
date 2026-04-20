extends Node2D


class_name Hero
signal health_updated(current_hp, max_hp)

var display_name: String = "Hero"
var max_hp: int = 3
var attack_power: int = 1

var current_hp: int

func _ready():
	current_hp = max_hp



func take_damage(damage: int):
	current_hp -= damage
	if current_hp < 0:
		current_hp = 0
	if current_hp > max_hp:
		current_hp = max_hp
	if damage > 0:
		print(display_name + " получил " + str(damage) + " урона. Осталось HP: " + str(current_hp))
	else:
		print(display_name + " вылечился на " + str(damage).substr(1) + ". Осталось HP: " + str(current_hp))

	health_updated.emit(current_hp, max_hp)


func is_alive() -> bool:
	return current_hp > 0
