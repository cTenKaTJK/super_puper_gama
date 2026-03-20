extends Node2D

var lifetime = 0.8
var speed = 100 

func _ready():
	# Удаляем узел через lifetime
	var timer = get_tree().create_timer(lifetime)
	timer.timeout.connect(queue_free)

func _process(delta):
	position.y -= speed * delta
