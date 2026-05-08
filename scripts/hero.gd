extends Node2D

class_name Hero

signal health_updated(current_hp, max_hp)
signal attack_animation_finished()

enum State {
	IDLE,
	ATTACK_UP,
	ATTACK_MIDDLE,
	ATTACK_DOWN,
	HURT
}

var display_name: String = "Hero"
var max_hp: int = 5
var attack_power: int = 2
var current_hp: int

# Анимация
@export var sprite_sheet: Texture2D
@export var frame_width: int = 256
@export var frame_height: int = 256
@export var sprite_scale: float = 2.0

var sprite: Sprite2D
var textures: Dictionary = {}
var current_state: State = State.IDLE
var is_attacking: bool = false

func _ready():
	sprite = Sprite2D.new()
	add_child(sprite)
	sprite.scale = Vector2(sprite_scale, sprite_scale)
	

	current_hp = max_hp
	
	load_sprite_sheet()
	set_state(State.IDLE)

func load_sprite_sheet():
	if not sprite_sheet:
		print("ОШИБКА Sprite Sheet!")
		return
	

	for i in range(5):
		var atlas = AtlasTexture.new()
		atlas.atlas = sprite_sheet
		atlas.region = Rect2(i * frame_width, 0, frame_width, frame_height)
		
		match i:
			0: textures[State.IDLE] = atlas
			1: textures[State.ATTACK_UP] = atlas
			2: textures[State.ATTACK_MIDDLE] = atlas
			3: textures[State.ATTACK_DOWN] = atlas
			4: textures[State.HURT] = atlas
	
	print("Загружено текстур героя: ", textures.size())

func set_state(new_state: State):
	current_state = new_state
	if textures.has(current_state) and textures[current_state]:
		sprite.texture = textures[current_state]

# АНИМАЦИЯ КАУНТЕРА (вызывается при успешном отражении)
func play_counter_animation(attack_type: String):
	if is_attacking:
		return
	
	is_attacking = true
	
	# Выбираем анимацию в зависимости от атаки врага
	match attack_type:
		"up":
			set_state(State.ATTACK_UP)
			print("Каунтер: удар СВЕРХУ!")
		"middle":
			set_state(State.ATTACK_MIDDLE)
			print("Каунтер: удар ПРЯМО!")
		"down":
			set_state(State.ATTACK_DOWN)
			print("Каунтер: удар СНИЗУ!")
	
	# Ждем анимацию удара
	await get_tree().create_timer(0.2).timeout
	
	# Возвращаемся в стойку
	set_state(State.IDLE)
	is_attacking = false
	
	attack_animation_finished.emit()

# АНИМАЦИЯ ПОЛУЧЕНИЯ УРОНА
func play_hurt_animation():
	var previous_state = current_state
	
	set_state(State.HURT)
	
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.RED, 0.1)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	
	await get_tree().create_timer(0.2).timeout
	
	if previous_state != State.HURT:
		set_state(previous_state)
	else:
		set_state(State.IDLE)

# ПОЛУЧЕНИЕ УРОНА
func take_damage(damage: int):
	var old_hp = current_hp
	current_hp -= damage
	
	if current_hp < 0:
		current_hp = 0
	if current_hp > max_hp:
		current_hp = max_hp
	
	if damage > 0:
		print(display_name + " получил " + str(damage) + " урона. Осталось HP: " + str(current_hp))
		await play_hurt_animation()
	else:
		print(display_name + " вылечился на " + str(-damage) + ". Осталось HP: " + str(current_hp))
	
	health_updated.emit(current_hp, max_hp)

func is_alive() -> bool:
	return current_hp > 0
