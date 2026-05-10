extends Node2D

class_name Enemy

signal health_updated(current_hp, max_hp)
signal attack_started(attack_type: String)
signal attack_hit(attack_type: String)

enum State {
	IDLE, WINDUP_UP, WINDUP_MIDDLE, WINDUP_DOWN,
	ATTACK_UP, ATTACK_MIDDLE, ATTACK_DOWN, HURT
}

@export var sprite_sheet: Texture2D
@export var frame_width: int = 64
@export var frame_height: int = 64
@export var sprite_scale: float = 1.0


var sprite: Sprite2D
var textures: Dictionary = {}
var current_state: State = State.IDLE
var current_hp: int
var max_hp: int
var display_name: String = "Enemy"
var attack_power: int = 1
var is_attacking: bool = false
var current_attack_type: String = ""

func _ready():
	sprite = Sprite2D.new()
	add_child(sprite)
	
	sprite.scale = Vector2(sprite_scale, sprite_scale)
	
	current_hp = max_hp
	load_sprite_sheet()
	set_state(State.IDLE)

func load_sprite_sheet():
	if not sprite_sheet:
		return
	
	for i in range(8):
		var atlas = AtlasTexture.new()
		atlas.atlas = sprite_sheet
		atlas.region = Rect2(i * frame_width, 0, frame_width, frame_height)
		
		match i:
			0: textures[State.IDLE] = atlas
			1: textures[State.WINDUP_UP] = atlas
			2: textures[State.WINDUP_MIDDLE] = atlas
			3: textures[State.WINDUP_DOWN] = atlas
			4: textures[State.ATTACK_UP] = atlas
			5: textures[State.ATTACK_MIDDLE] = atlas
			6: textures[State.ATTACK_DOWN] = atlas
			7: textures[State.HURT] = atlas
	
	print("Загружено текстур: ", textures.size())

func set_state(new_state: State):
	current_state = new_state
	if textures.has(current_state) and textures[current_state]:
		sprite.texture = textures[current_state]

func choose_attack():
	var attacks = ["up", "middle", "down"]
	if GameDataLoad.level > 3:
		attacks.append("circle")
	if GameDataLoad.level > 5:
		attacks.append("wave")
	return attacks[randi() % attacks.size()]

func start_attack():
	if is_attacking:
		return
	
	is_attacking = true
	current_attack_type = choose_attack()
	
	match current_attack_type:
		"up":
			set_state(State.WINDUP_UP)
		"middle":
			set_state(State.WINDUP_MIDDLE)
		"down":
			set_state(State.WINDUP_DOWN)
		"circle":
			set_state(State.WINDUP_MIDDLE)
		"wave":
			set_state(State.WINDUP_MIDDLE)
	
	attack_started.emit(current_attack_type)

func execute_hit():
	if not is_attacking:
		return
	
	print("Удар наносится!")
	
	match current_attack_type:
		"up":
			set_state(State.ATTACK_UP)
		"middle":
			set_state(State.ATTACK_MIDDLE)
		"down":
			set_state(State.ATTACK_DOWN)
		"circle":
			set_state(State.ATTACK_MIDDLE)
		"wave":
			set_state(State.ATTACK_MIDDLE)
	
	attack_hit.emit(current_attack_type)
	await get_tree().create_timer(0.3).timeout
	
	set_state(State.IDLE)
	is_attacking = false


func cancel_attack():
	if not is_attacking:
		return
	
	play_hurt_animation()
	
	await get_tree().create_timer(0.2).timeout
	
	set_state(State.IDLE)
	is_attacking = false


func play_hurt_animation():
	var previous_state = current_state
	
	set_state(State.HURT)
	
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.RED, 0.05)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.15)
	
	await get_tree().create_timer(0.2).timeout
	
	if previous_state != State.HURT:
		set_state(previous_state)

func take_damage(damage: int):
	current_hp -= damage
	if current_hp < 0:
		current_hp = 0
	print(display_name + " получил " + str(damage) + " урона. Осталось HP: " + str(current_hp))
	if damage > 0:
		await play_hurt_animation()
	health_updated.emit(current_hp, max_hp)


func is_alive() -> bool:
	return current_hp > 0
