extends Node2D

var lifetime: float = 0.8
var speed: float = 100.0
var display_text: String = ""
var text_color: Color = Color.WHITE

@onready var label: Label = $ParticleLabel

func _ready():
	label.text = display_text
	label.modulate = text_color
	var timer = get_tree().create_timer(lifetime)
	timer.timeout.connect(queue_free)

func _process(delta):
	position.y -= speed * delta
