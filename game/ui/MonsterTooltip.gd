extends Control
class_name MonsterTooltip

## Interface tooltip pour afficher les informations des monstres au survol

@onready var background: NinePatchRect = $Background
@onready var monster_name_label: Label = $VBoxContainer/NameLabel
@onready var level_label: Label = $VBoxContainer/LevelLabel
@onready var health_label: Label = $VBoxContainer/HealthLabel
@onready var stats_container: VBoxContainer = $VBoxContainer/StatsContainer
@onready var behavior_label: Label = $VBoxContainer/BehaviorLabel

var current_monster: Monster = null

func _ready():
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # Éviter les interférences avec la souris

func show_monster_info(monster: Monster, mouse_position: Vector2):
	"""Affiche les informations du monstre"""
	if not monster:
		hide_tooltip()
		return
	
	current_monster = monster
	
	# Mise à jour des informations
	update_monster_display()
	
	# Positionnement du tooltip
	position_tooltip(mouse_position)
	
	# Affichage avec animation
	visible = true
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.2)

func update_monster_display():
	"""Met à jour l'affichage des informations du monstre"""
	if not current_monster:
		return
	
	# Nom et niveau
	monster_name_label.text = current_monster.monster_name
	level_label.text = "Niveau " + str(current_monster.level)
	
	# Couleur selon le comportement
	var behavior_color = Monster.BEHAVIOR_COLORS.get(current_monster.behavior, Color.WHITE)
	monster_name_label.modulate = behavior_color
	
	# Vie
	health_label.text = str(current_monster.health) + " / " + str(current_monster.max_health) + " PV"
	
	# Stats
	clear_stats_display()
	add_stat_line("Force", current_monster.strength)
	add_stat_line("Intelligence", current_monster.intelligence)
	add_stat_line("Agilité", current_monster.agility)
	add_stat_line("Vitalité", current_monster.vitality)
	
	# Comportement
	var behavior_text = get_behavior_text(current_monster.behavior)
	behavior_label.text = behavior_text
	behavior_label.modulate = behavior_color

func clear_stats_display():
	"""Nettoie l'affichage des stats"""
	for child in stats_container.get_children():
		if child.has_method("queue_free"):
			child.queue_free()

func add_stat_line(stat_name: String, value: int):
	"""Ajoute une ligne de stat"""
	var stat_label = Label.new()
	stat_label.text = stat_name + ": " + str(value)
	stat_label.add_theme_font_size_override("font_size", 12)
	stats_container.add_child(stat_label)

func get_behavior_text(behavior: String) -> String:
	"""Retourne le texte descriptif du comportement"""
	match behavior:
		"passive":
			return "Pacifique"
		"neutral":
			return "Neutre"
		"aggressive":
			return "Agressif"
		_:
			return "Inconnu"

func position_tooltip(mouse_pos: Vector2):
	"""Positionne le tooltip près de la souris"""
	var viewport_size = get_viewport().get_visible_rect().size
	var tooltip_size = get_combined_minimum_size()
	
	# Position de base
	var tooltip_pos = mouse_pos + Vector2(10, -10)
	
	# Éviter de sortir de l'écran à droite
	if tooltip_pos.x + tooltip_size.x > viewport_size.x:
		tooltip_pos.x = mouse_pos.x - tooltip_size.x - 10
	
	# Éviter de sortir de l'écran en bas
	if tooltip_pos.y + tooltip_size.y > viewport_size.y:
		tooltip_pos.y = mouse_pos.y - tooltip_size.y + 10
	
	# Éviter de sortir de l'écran en haut
	tooltip_pos.y = max(0, tooltip_pos.y)
	tooltip_pos.x = max(0, tooltip_pos.x)
	
	position = tooltip_pos

func hide_tooltip():
	"""Cache le tooltip avec animation"""
	if not visible:
		return
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	tween.tween_callback(func(): visible = false)
	
	current_monster = null

func _input(event):
	"""Gère les événements d'entrée globaux"""
	if visible and event is InputEventMouseMotion:
		# Mettre à jour la position si le tooltip est visible
		if current_monster:
			position_tooltip(event.position) 
