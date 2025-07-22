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
@export var speed: float = 400.0  # Vitesse de déplacement en pixels/seconde

## RÉFÉRENCES AUX NŒUDS ENFANTS
## =============================
## Ces références sont automatiquement assignées quand la scène est chargée
@onready var sprite: Sprite2D = $Sprite2D  # Sprite visuel du joueur

## VARIABLES D'ÉTAT DU MOUVEMENT
## ==============================
var target_position: Vector2  # Position cible vers laquelle le joueur se déplace
var is_moving: bool = false   # Indique si le joueur est actuellement en mouvement
var movement_enabled: bool = true  # Indique si le joueur peut se déplacer

## RÉFÉRENCE AU GAMEMANAGER
## ========================
var game_manager: Node = null

## CONTRÔLE DES LOGS
## ==================
var last_combat_block_log: float = 0.0  # Timestamp du dernier log de mouvement bloqué

## INITIALISATION DU JOUEUR
## =========================
func _ready():
	print("[Player] === INITIALISATION DU JOUEUR ===")
	
	# Obtenir la référence au GameManager
	game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		print("[Player] ✅ GameManager trouvé")
	else:
		print("[Player] ⚠️ GameManager non trouvé")
	
	# Ajouter le joueur au groupe "Player" pour identification facile
	add_to_group("Player")
	
	target_position = global_position
	print("[Player] Joueur initialisé à la position: ", global_position)

## GESTION DES ENTRÉES UTILISATEUR
## ================================
func _unhandled_input(event):
	"""
	Traite les entrées utilisateur pour le déplacement SEULEMENT si elles ne sont pas gérées par d'autres nœuds.
	Cela permet aux monstres (Area2D) d'avoir la priorité sur les clics.
	Actuellement: clic droit pour se déplacer, clic gauche pour actions.
	"""
	# Ignorer l'événement s'il a déjà été marqué comme "handled" par un autre nœud (ex: Monster/Area2D)
	# Certaines classes d'InputEvent (p. ex. MouseMotion) ne possèdent pas la méthode is_handled().
	if event.has_method("is_handled") and event.is_handled():
		return
		
	# Vérifier si le jeu est en mode combat
	if game_manager and game_manager.current_state == game_manager.GameState.IN_COMBAT:
		# Limiter les logs à 1 par seconde pour éviter le spam
		var current_time = Time.get_ticks_msec() / 1000.0
		if current_time - last_combat_block_log > 1.0:
			print("[Player] Mouvement bloqué en mode combat")
			last_combat_block_log = current_time
		return
		
	# Vérifier si le mouvement est activé
	if not movement_enabled:
		print("[Player] ⚠️ Mouvement désactivé")
		return
		
	if event is InputEventMouseButton and event.pressed:
		var mouse_pos = get_global_mouse_position()
		
		if event.button_index == MOUSE_BUTTON_RIGHT:
			# Déplacement par clic droit de souris
			print("[Player] Clic droit détecté à la position: ", mouse_pos)
			move_to_position(mouse_pos)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			# Clic gauche sur du vide (les monstres ont déjà été vérifiés)
			print("[Player] Clic gauche sur du vide à la position: ", mouse_pos)
			# Ici on pourrait ajouter d'autres actions (ramasser objet, etc.)

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

## ACTIVE/DÉSACTIVE LE MOUVEMENT
## =============================
func set_movement_enabled(enabled: bool):
	"""
	Active ou désactive la capacité de mouvement du joueur.
	Utilisé principalement pour bloquer le mouvement pendant les combats.
	"""
	movement_enabled = enabled
	if not enabled:
		# Arrêter tout mouvement en cours
		is_moving = false
		target_position = global_position
		velocity = Vector2.ZERO
		print("[Player] Mouvement désactivé - Arrêt du personnage")
	else:
		print("[Player] Mouvement réactivé")
