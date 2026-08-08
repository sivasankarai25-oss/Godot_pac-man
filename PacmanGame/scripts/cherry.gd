extends Area2D
class_name Cherry
## Cherry power-up (section 4 of the spec). On collection, triggers
## GameManager.enter_power_mode(), which drives every ghost into
## FRIGHTENED mode via the state_changed signal each ghost already listens
## to (see ghost.gd _on_game_state_changed). This keeps the role-reversal
## mechanic as a clean state transition rather than hardcoded per-ghost
## calls, per spec section 5.

signal collected

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

var _collected: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(sprite, "scale", Vector2(1.15, 1.15), 0.5)
	tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.5)

func _on_body_entered(body: Node2D) -> void:
	if _collected:
		return
	if body is Pacman:
		_collect()

func _collect() -> void:
	_collected = true
	AudioManager.play("power_pellet")
	GameManager.score_cherry()
	GameManager.enter_power_mode()
	collected.emit()
	visible = false
	collision.set_deferred("disabled", true)

func reset() -> void:
	_collected = false
	visible = true
	collision.set_deferred("disabled", false)
