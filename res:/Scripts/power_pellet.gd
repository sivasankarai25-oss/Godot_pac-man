extends Area2D

# Signal emitted when power pellet is collected
signal collected

# Reference to the AnimatedSprite2D
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	# Play the animation (if any)
	animated_sprite.play("default")
	
	# Connect the body_entered signal to our function
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	# Check if the body is the player (Pac-Man)
	if body.is_in_group("player"):
		# Emit the collected signal
		collected.emit()
		# Free this power pellet
		queue_free()