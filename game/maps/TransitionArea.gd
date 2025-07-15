extends Area2D

@export var target_map: String
@export var direction: String = "right"  # "right", "left", "up", "down"
@export var entry_point: Vector2 = Vector2.ZERO  # Position de spawn sur la map de destination
@export var offset: float = 32.0  # Pour positionner juste après la zone

var ws_manager: Node = null

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))
	
	# Récupérer le WebSocketManager depuis le GameManager (qui est un Autoload)
	if GameManager:
		ws_manager = GameManager.ws_manager
		print("[TransitionArea] ws_manager récupéré depuis GameManager : ", ws_manager)
	else:
		print("[TransitionArea] ERREUR : Le singleton GameManager n'est pas trouvé.")

func _on_body_entered(body):
	# Logs de debug uniquement en mode développement
	if OS.is_debug_build():
		print("[TransitionArea] Transition vers ", target_map, " à ", entry_point)

	if body.is_in_group("Player") and body.is_multiplayer_authority():
		if target_map.is_empty():
			print("[TransitionArea] ERREUR: La propriété 'target_map' n'est pas définie pour cette zone.")
			return
			
		var current_pos = body.position
		var _new_pos = calculate_new_position(current_pos)

		if ws_manager:
			ws_manager.send_change_map_request(target_map)
		else:
			print("[TransitionArea] ERREUR : WebSocket manager non disponible")

func calculate_new_position(current_pos: Vector2) -> Vector2:
	# Utiliser entry_point si défini, sinon utiliser l'ancien calcul
	if entry_point != Vector2.ZERO:
		return entry_point
	
	# Fallback vers l'ancien calcul si entry_point n'est pas défini
	match direction:
		"right":
			return Vector2(offset, current_pos.y)
		"left":
			return Vector2(1920 - offset, current_pos.y)  # Ajuster selon la largeur de la map
		"up":
			return Vector2(current_pos.x, 1080 - offset)  # Ajuster selon la hauteur de la map
		"down":
			return Vector2(current_pos.x, offset)
		_:
			return current_pos
