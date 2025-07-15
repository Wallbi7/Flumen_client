extends CharacterBody2D
class_name Player

## SIGNAUX ÉMIS PAR LE JOUEUR
## ============================
## player_moved: Émis quand le joueur termine un mouvement (pour synchronisation multijoueur)
## map_transition_triggered: Émis quand le joueur entre dans une zone de transition
signal player_moved(new_position: Vector2)
signal map_transition_triggered(target_map_id: String, entry_point: Vector2)

## PROPRIÉTÉS EXPORTÉES (modifiables dans l'éditeur)
## =================================================
@export var speed: float = 200.0  # Vitesse de déplacement en pixels/seconde

## RÉFÉRENCES AUX NŒUDS ENFANTS
## =============================
## Ces références sont automatiquement assignées quand la scène est chargée
@onready var sprite: Sprite2D = $Sprite2D  # Sprite visuel du joueur

## VARIABLES D'ÉTAT DU MOUVEMENT
## ==============================
var target_position: Vector2  # Position cible vers laquelle le joueur se déplace
var is_moving: bool = false   # Indique si le joueur est actuellement en mouvement

## INITIALISATION DU JOUEUR
## =========================
func _ready():
	print("[Player] === INITIALISATION DU JOUEUR ===")
	
	# Ajouter le joueur au groupe "Player" pour identification facile
	add_to_group("Player")
	
	target_position = global_position
	print("[Player] Joueur initialisé à la position: ", global_position)

## GESTION DES ENTRÉES UTILISATEUR
## ================================
func _input(event):
	"""
	Traite les entrées utilisateur pour le déplacement.
	Actuellement: clic droit pour se déplacer vers la position de la souris.
	"""
	# Déplacement par clic droit de souris
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		var mouse_pos = get_global_mouse_position()
		print("[Player] Clic droit détecté à la position: ", mouse_pos)
		move_to_position(mouse_pos)

## COMMANDE DE DÉPLACEMENT
## ========================
func move_to_position(pos: Vector2):
	"""
	Commande le joueur de se déplacer vers une position donnée.
	
	Args:
		pos (Vector2): Position cible en coordonnées globales
	"""
	print("[Player] === NOUVEAU DÉPLACEMENT ===")
	print("[Player] Position actuelle: ", global_position)
	print("[Player] Position cible: ", pos)
	
	target_position = pos
	is_moving = true
	
	print("[Player] Distance à parcourir: ", global_position.distance_to(pos), " pixels")

## MOUVEMENT PHYSIQUE
## ===================
func _physics_process(_delta):
	if not is_moving:
		return
	
	var distance_to_target = global_position.distance_to(target_position)
	
	# Arrivé à destination
	if distance_to_target < 5.0:
		_finish_movement()
		return
	
	# Calculer direction et vitesse
	var direction = (target_position - global_position).normalized()
	velocity = direction * speed
	move_and_slide()

## FINALISATION DU MOUVEMENT
## ==========================
func _finish_movement():
	"""
	Finalise le mouvement quand le joueur atteint sa destination.
	Émet le signal player_moved pour la synchronisation multijoueur.
	"""
	print("[Player] === MOUVEMENT TERMINÉ ===")
	is_moving = false
	velocity = Vector2.ZERO
	global_position = target_position
	emit_signal("player_moved", global_position)
	print("[Player] Signal player_moved émis pour synchronisation")

## GESTION DES COLLISIONS AVEC LES ZONES DE TRANSITION
## ====================================================
func _on_body_entered(body):
	"""
	Appelé quand le joueur entre en collision avec une zone de transition.
	Gère le changement de map quand le joueur touche les bords de la map.
	
	Args:
		body: L'objet avec lequel le joueur est entré en collision
	"""
	print("[Player] === COLLISION DÉTECTÉE ===")
	
	if body.has_method("get_transition_data"):
		print("[Player] Zone de transition détectée!")
		var transition_data = body.get_transition_data()
		var target_map = transition_data.get("target_map", "")
		var entry_point = transition_data.get("entry_point", Vector2.ZERO)
		
		if target_map != "":
			print("[Player] Transition vers: ", target_map)
			emit_signal("map_transition_triggered", target_map, entry_point)
			
			# Notification serveur
			var websocket_manager = get_node_or_null("/root/WebSocketManager")
			if websocket_manager and websocket_manager.has_method("send_change_map_request"):
				websocket_manager.send_change_map_request(target_map)
		else:
			print("[Player] ⚠️ Zone de transition sans map cible définie")
	else:
		print("[Player] Collision avec un objet non-transition: ", body.get_class() if body else "inconnu")
