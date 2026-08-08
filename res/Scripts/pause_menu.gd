extends Node

# Signals
signal resume
signal restart
signal main_menu

func _on_resume_button_pressed() -> void:
	resume.emit()

func _on_restart_button_pressed() -> void:
	restart.emit()

func _on_main_menu_button_pressed() -> void:
	main_menu.emit()