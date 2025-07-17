extends CharacterBody2D
class_name Monster

## Classe Monster pour l'affichage des monstres côté client

# ================================
# SIGNAUX POUR INTERACTION COMBAT - RECOMPILATION FORCÉE
# ================================
signal monster_clicked(monster: Monster)
signal monster_right_clicked(monster: Monster) 
signal monster_hovered(monster: Monster, is_hovering: bool)
signal monster_died(monster: Monster)

@export var monster_id: String
@export var monster_type: String
@export var monster_name: String
@export var level: int = 1
@export var is_alive: bool = true

# Stats du monstre
var health: int
var max_health: int
var strength: int
var intelligence: int
var agility: int
var vitality: int

# Composants visuels
@onready var sprite: ColorRect = $ColorRect
@onready var health_bar: ProgressBar = $HealthBar
@onready var name_label: Label = $NameLabel
@onready var level_label: Label = $LevelLabel

# Couleurs selon le comportement
const BEHAVIOR_COLORS = {
	"passive": Color.GREEN,
	"neutral": Color.YELLOW,
	"aggressive": Color.RED
}

var behavior: String = "neutral"

# Variables pour les interactions
var is_mouse_over: bool = false
var interaction_area: Area2D

func setup_visual_components():
	# Configuration du nom
	if name_label:
		name_label.text = monster_name
		name_label.modulate = BEHAVIOR_COLORS.get(behavior, Color.WHITE)
	
	# Configuration du niveau
	if level_label:
		level_label.text = "Niv. " + str(level)
	
	# Configuration de la barre de vie
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = health
		health_bar.visible = health < max_health  # Masquer si pleine vie

func initialize_monster(monster_data: Dictionary):
	"""Initialise le monstre avec les données du serveur"""
	monster_id = monster_data.get("id", "")
	monster_type = monster_data.get("template_id", "")
	monster_name = monster_data.get("name", "Monstre")
	level = monster_data.get("level", 1)
	is_alive = monster_data.get("is_alive", true)
	behavior = monster_data.get("behavior", "neutral")
	
	# Position
	position.x = monster_data.get("pos_x", 0)
	position.y = monster_data.get("pos_y", 0)
	
	# Stats
	var stats = monster_data.get("stats", {})
	health = stats.get("health", 100)
	max_health = stats.get("max_health", 100)
	strength = stats.get("strength", 10)
	intelligence = stats.get("intelligence", 10)
	agility = stats.get("agility", 10)
	vitality = stats.get("vitality", 10)
	
	# Sprite selon le type
	setup_sprite_for_type(monster_type)
	
	# Mise à jour visuelle
	setup_visual_components()
	
	print("[Monster] Monstre initialisé: ", monster_name, " (", monster_type, ") Niv.", level)

func setup_sprite_for_type(type: String):
	"""Configure le sprite selon le type de monstre"""
	if not sprite:
		return
	
	# Couleurs temporaires selon le type (en attendant les vrais sprites)
	var color_map = {
		"bouftou": Color.BROWN,
		"tofu": Color.WHITE,
		"larve": Color.BLUE,
		"prespic": Color.PURPLE,
		"abeille": Color.YELLOW,
		"sanglier": Color.DARK_GRAY
	}
	
	sprite.color = color_map.get(type, Color.GRAY)
	
	# Taille selon le niveau
	var scale_factor = 1.0 + (level - 1) * 0.1
	sprite.scale = Vector2(scale_factor, scale_factor)

func take_damage(damage: int):
	"""Applique des dégâts au monstre"""
	if not is_alive:
		return
	
	health = max(0, health - damage)
	
	# Mise à jour de la barre de vie
	if health_bar:
		health_bar.value = health
		health_bar.visible = true
		
		# Animation de dégâts
		var tween = create_tween()
		tween.tween_property(health_bar, "modulate", Color.RED, 0.1)
		tween.tween_property(health_bar, "modulate", Color.WHITE, 0.1)
	
	# Mort du monstre
	if health <= 0:
		die()
	
	print("[Monster] ", monster_name, " reçoit ", damage, " dégâts. Vie: ", health, "/", max_health)

func die():
	"""Gère la mort du monstre"""
	is_alive = false
	
	# Animation de mort
	var tween = create_tween()
	tween.parallel().tween_property(self, "modulate", Color.RED, 0.5)
	tween.parallel().tween_property(self, "scale", Vector2(0.5, 0.5), 0.5)
	tween.tween_callback(func(): queue_free())
	
	print("[Monster] ", monster_name, " est mort !")

func _ready():
	print("[Monster] Initialisation du monstre: ", monster_name)
	setup_visual_components()
	setup_interaction_area()

func setup_interaction_area():
	"""Configure la zone d'interaction du monstre"""
	# Utiliser l'Area2D existante du .tscn au lieu d'en créer une nouvelle
	interaction_area = $Area2D
	
	if not interaction_area:
		print("[Monster] ⚠️ Area2D non trouvée dans le .tscn")
		return
	
	# CONFIGURATION CRITIQUE POUR DÉTECTER LES CLICS
	interaction_area.set_pickable(true)  # Force l'activation
	interaction_area.input_pickable = true
	interaction_area.monitoring = true
	interaction_area.monitorable = true
	
	# Priority élevée pour être détecté en premier
	interaction_area.priority = 10.0
	
	# Configuration des couches de collision
	interaction_area.collision_layer = 1
	interaction_area.collision_mask = 1
	
	# Force la mise à jour immédiate
	interaction_area.set_process_mode(Node.PROCESS_MODE_ALWAYS)
	
	# NOUVEAU: Attacher le script spécialisé pour améliorer la détection des clics
	if not interaction_area.get_script():
		var area_script = preload("res://game/monsters/MonsterAreaScript.gd")
		interaction_area.set_script(area_script)
		print("[Monster] ✅ Script spécialisé attaché à l'Area2D pour meilleure détection")
	
	# Vérification de la CollisionShape2D
	var collision_shape = interaction_area.get_node("CollisionShape2D")
	if collision_shape and collision_shape.shape:
		print("[Monster] ✅ CollisionShape2D trouvée avec shape: ", collision_shape.shape.get_class())
		collision_shape.disabled = false
	else:
		print("[Monster] ⚠️ Problème avec CollisionShape2D")
	
	# Connexion des signaux supplémentaires (input_event déjà connecté dans .tscn)
	if not interaction_area.mouse_entered.is_connected(_on_mouse_entered):
		interaction_area.mouse_entered.connect(_on_mouse_entered)
	if not interaction_area.mouse_exited.is_connected(_on_mouse_exited):
		interaction_area.mouse_exited.connect(_on_mouse_exited)
	
	# Debug final
	print("[Monster] 🔧 Configuration Area2D: input_pickable=", interaction_area.input_pickable, 
		  " priority=", interaction_area.priority, " monitoring=", interaction_area.monitoring)
	
	print("[Monster] Zone d'interaction configurée pour: ", monster_name, " - Utilisation Area2D existante")

func _on_mouse_entered():
	"""Appelé quand la souris survole le monstre"""
	is_mouse_over = true
	monster_hovered.emit(self, true)
	
	# Effet visuel de survol
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1.2, 1.2, 1.2), 0.1)

func _on_mouse_exited():
	"""Appelé quand la souris quitte le monstre"""
	is_mouse_over = false
	monster_hovered.emit(self, false)
	
	# Retour à la normale
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)

# Fonction correspondant à la connexion dans le .tscn
func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int):
	"""Gère les clics sur le monstre (connexion .tscn)"""
	
	# Debug détaillé pour tous les événements importants
	if event is InputEventMouseButton:
		print("[Monster] 🖱️ ÉVÉNEMENT CLIC sur ", monster_name, " - Bouton: ", event.button_index, " Pressed: ", event.pressed, " Position: ", event.position)
		if event.pressed:
			print("[Monster] ✅ CLIC DÉTECTÉ sur ", monster_name, " - Bouton: ", event.button_index)
			
			# Marquer l'événement comme géré pour éviter la propagation
			get_viewport().set_input_as_handled()
			
			if event.button_index == MOUSE_BUTTON_LEFT:
				# Clic gauche = déplacement + attaque
				print("[Monster] 🔥 ÉMISSION SIGNAL monster_clicked pour: ", monster_name)
				monster_clicked.emit(self)
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				# Clic droit = menu contextuel (future feature)
				print("[Monster] 🔥 ÉMISSION SIGNAL monster_right_clicked pour: ", monster_name)
				monster_right_clicked.emit(self)
		else:
			print("[Monster] 📤 Relâchement bouton ", event.button_index, " sur ", monster_name)
	elif event is InputEventMouseMotion:
		# Log motion seulement si debug activé
		if false:  # Changer à true pour debug motion
			print("[Monster] 🔍 Motion sur ", monster_name, " - Position: ", event.position)
	else:
		print("[Monster] 🤔 Événement inconnu sur ", monster_name, ": ", event.get_class())

# Garder l'ancienne fonction pour compatibilité (peut être supprimée plus tard)
func _on_area_input_event(viewport: Node, event: InputEvent, shape_idx: int):
	"""Ancienne fonction - redirection vers la nouvelle"""
	_on_area_2d_input_event(viewport, event, shape_idx)

func get_interaction_position() -> Vector2:
	"""Retourne la position d'interaction (adjacente au monstre)"""
	# Position adjacente pour le combat
	return global_position + Vector2(-50, 0)  # À gauche du monstre

func _on_monster_died():
	monster_died.emit(self) 
