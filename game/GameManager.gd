extends Node

## GESTIONNAIRE CENTRAL DU JEU (SINGLETON)
## =========================================
## Ce script est un Autoload (singleton) qui gère tous les aspects du gameplay :
## - Chargement et gestion des maps
## - Création et gestion du joueur principal
## - Système multijoueur (autres joueurs)
## - Transitions entre maps
## - Communication avec le serveur WebSocket
##
## ARCHITECTURE:
## Main.gd -> GameManager (ce script) -> WebSocketManager + AuthManager
##         -> Player.gd (joueur principal)
##         -> OtherPlayers (joueurs distants)

## ÉNUMÉRATION DES ÉTATS DU JEU
## =============================
enum GameState {
	MENU,           # Dans les menus (connexion, sélection personnage)
	LOADING,        # Chargement en cours
	IN_GAME,        # En jeu normal
	IN_COMBAT,      # En combat tactique
	PAUSED          # Jeu en pause
}

## VARIABLES D'ÉTAT PRINCIPAL
## ===========================
var current_state: GameState = GameState.MENU  # État actuel du jeu
var current_map: Node = null              # Instance de la map actuellement chargée
var current_player: CharacterBody2D = null # Instance du joueur principal
var current_map_id: String = ""           # ID de la map actuelle (ex: "map_0_0")

## SYSTÈME DE PERSONNAGES
## =======================
var current_character: Dictionary = {}    # Données du personnage sélectionné
var characters: Array = []                # Liste des personnages du joueur
var character_classes: Array = []         # Informations sur les classes disponibles

## SYSTÈME DE MONSTRES ET INTERACTIONS
## ====================================
var monster_tooltip: Control = null       # Interface tooltip pour les monstres
var monsters_on_map: Array[Monster] = []  # Liste des monstres sur la map actuelle

## VARIABLES DE SPAWN
## ==================
var spawn_x: float = 0.0  # Position X où spawner le joueur
var spawn_y: float = 0.0  # Position Y où spawner le joueur

## GESTION MULTIJOUEUR
## ====================
var other_players: Dictionary = {}              # user_id -> Player node (autres joueurs)
var player_scene = preload("res://game/players/Player.tscn")  # Scène du joueur à instancier

## GESTION DES MONSTRES
## =====================
var monsters: Dictionary = {}                   # monster_id -> Monster node
var monster_scene = preload("res://game/monsters/Monster.tscn")  # Scène du monstre à instancier

## RÉFÉRENCES AUX MANAGERS
## ========================
var websocket_manager: Node = null  # Référence au WebSocketManager (Autoload)
var auth_manager: Node = null        # Référence à l'AuthManager (Autoload)
var ws_manager: Node = null          # Référence legacy pour compatibilité avec main.gd

## SYSTÈME DE COMBAT
## =================
var combat_manager: Node = null     # Gestionnaire de combat tactique

## ÉTAT D'INITIALISATION
## ======================
var _is_initialized := false  # Empêche l'initialisation multiple du singleton

# Nœud pour les requêtes HTTP
var http_request: HTTPRequest

## INITIALISATION DU SINGLETON
## ============================
func _ready():
	# Sécurité : empêcher l'initialisation multiple
	if _is_initialized: 
		return
	_is_initialized = true
	print("[GameManager] === INITIALISATION DU GESTIONNAIRE CENTRAL ===")
	
	# Initialisation du système de tooltip
	setup_monster_tooltip()
	
	# Initialisation terminée
	print("[GameManager] Système de maps initialisé")
	
	# RÉCUPÉRATION DES RÉFÉRENCES AUX MANAGERS
	# ==========================================
	# AuthManager est un Autoload
	auth_manager = get_node_or_null("/root/AuthManager")
	
	# WebSocketManager est créé dans main.tscn, pas un Autoload
	# On va le chercher différemment
	
	# Vérification de disponibilité des managers
	if auth_manager == null:
		print("[GameManager] ⚠️ ATTENTION: AuthManager non trouvé")
	else:
		print("[GameManager] ✅ AuthManager trouvé")
	
	# Le WebSocketManager sera connecté plus tard quand main.tscn sera chargé
	print("[GameManager] WebSocketManager sera connecté lors de la connexion au serveur")
	
	# Initialiser le système de combat
	initialize_combat_system()
	
	print("[GameManager] Gestionnaire central prêt")

	# Créer le nœud HTTPRequest
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_http_request_completed)
	http_request.timeout = 10.0  # Timeout de 10 secondes
	http_request.use_threads = true  # Utiliser des threads pour éviter les blocages

## GESTION DES CONFIGURATIONS DE MAP
## =================================
func get_map_config(map_id: String) -> Dictionary:
	"""
	Charge la configuration de combat d'une map en l'instanciant brièvement.
	C'est la méthode la plus robuste pour récupérer les variables @export.
	Retourne un dictionnaire avec les données ou un dictionnaire vide si non trouvé.
	"""
	var map_path = "res://game/maps/%s/%s.tscn" % [map_id, map_id]
	
	if not ResourceLoader.exists(map_path):
		print("[GameManager] ❌ Fichier de scène non trouvé pour la config: ", map_path)
		return {}
	
	var packed_scene = ResourceLoader.load(map_path)
	if not packed_scene or not packed_scene.can_instantiate():
		print("[GameManager] ❌ Impossible de charger PackedScene pour: ", map_path)
		return {}
		
	# Instancier la scène pour lire les valeurs (y compris les valeurs par défaut du script)
	var instance = packed_scene.instantiate()
	if not instance:
		print("[GameManager] ❌ Impossible d'instancier la scène pour: ", map_path)
		return {}
	
	var config: Dictionary # Déclaration de la variable
	if "combat_config" in instance: # CORRECTION: Utiliser le mot-clé 'in' pour vérifier l'existence d'une propriété
		config = instance.get("combat_config")
		print("[GameManager] ✅ 'combat_config' trouvée et lue: ", config)
	else:
		print("[GameManager] ⚠️ Aucune 'combat_config' trouvée pour: ", map_id)
		config = {} # Retourner vide comme promis
	
	# Libérer l'instance immédiatement après usage
	instance.queue_free()
	
	return config

## RETRY CONNEXION WEBSOCKET
## ==========================
func _retry_websocket_connection():
	"""
	Essaie de reconnecter au WebSocketManager après un délai.
	Utilisé quand le WebSocketManager n'est pas encore disponible au _ready().
	"""
	print("[GameManager] === RETRY CONNEXION WEBSOCKET ===")
	
	# Essayer de récupérer le WebSocketManager
	websocket_manager = get_node_or_null("/root/WebSocketManager")
	
	if websocket_manager != null:
		print("[GameManager] ✅ WebSocketManager trouvé en retry")
		_connect_websocket_signals()
	else:
		print("[GameManager] ❌ WebSocketManager toujours non trouvé en retry")
		# Réessayer dans 1 seconde
		await get_tree().create_timer(1.0).timeout
		_retry_websocket_connection()

## CONNEXION AUX SIGNAUX WEBSOCKET
## ================================
func _connect_websocket_signals():
	"""
	Connecte tous les signaux WebSocket nécessaires au fonctionnement du jeu.
	Cette méthode centralise toutes les connexions pour éviter les oublis.
	"""
	print("[GameManager] === CONNEXION AUX SIGNAUX WEBSOCKET ===")
	
	# Vérifier que websocket_manager existe avant de connecter
	if websocket_manager == null:
		print("[GameManager] ❌ WebSocketManager est null, impossible de connecter les signaux")
		return
	
	# SIGNAUX DE CONNEXION
	# ====================
	websocket_manager.connect("map_changed", _on_map_changed)
	print("[GameManager] ✅ Signal map_changed connecté")
	
	websocket_manager.connect("connected", _on_websocket_connected)
	print("[GameManager] ✅ Signal connected connecté")
	
	websocket_manager.connect("disconnected", _on_websocket_disconnected)
	print("[GameManager] ✅ Signal disconnected connecté")
	
	websocket_manager.connect("connection_error", _on_websocket_error)
	print("[GameManager] ✅ Signal connection_error connecté")
	
	# SIGNAUX MULTIJOUEUR
	# ===================
	websocket_manager.connect("player_joined", _on_player_joined)
	print("[GameManager] ✅ Signal player_joined connecté")
	
	websocket_manager.connect("player_left", _on_player_left)
	print("[GameManager] ✅ Signal player_left connecté")
	
	websocket_manager.connect("player_moved", _on_player_moved)
	print("[GameManager] ✅ Signal player_moved connecté")
	
	websocket_manager.connect("players_list_received", _on_players_list_received)
	print("[GameManager] ✅ Signal players_list_received connecté")
	
	# SIGNAUX DE COMBAT
	# =================
	websocket_manager.connect("combat_started", _on_combat_started_from_server) # Renommée pour clarté
	print("[GameManager] ✅ Signal combat_started connecté")
	
	print("[GameManager] Tous les signaux WebSocket connectés")

func _on_combat_started_from_server(combat_data: Dictionary):
	"""
	Callback déclenché par le serveur pour démarrer un combat.
	Utilise directement les données CombatState du serveur.
	"""
	print("[GameManager] ⚔️ Ordre de démarrage de combat reçu du serveur avec données: ", combat_data)
	
	if not combat_manager:
		print("[GameManager] ❌ CombatManager non initialisé.")
		return
		
	if combat_manager.is_combat_active:
		print("[GameManager] ⚠️ Un combat est déjà en cours, ignoré.")
		return

	# Utiliser la nouvelle API qui traite directement les données serveur
	combat_manager.start_combat_from_server(combat_data)
	print("[GameManager] ✅ Combat démarré avec les données serveur")
	current_state = GameState.IN_COMBAT
	print("[GameManager] ✅ Combat démarré localement. État du jeu: IN_COMBAT")

## CONNEXION AU SERVEUR DE JEU
## ============================
func connect_to_game_server():
	"""
	Initie la connexion au serveur de jeu avec le token d'authentification.
	Utilise le token JWT stocké dans l'AuthManager pour s'authentifier.
	"""
	print("[GameManager] === CONNEXION AU SERVEUR DE JEU ===")
	
	# MISE À JOUR DE LA RÉFÉRENCE WEBSOCKET MANAGER
	# ==============================================
	# Le WebSocketManager est créé dans main.tscn, pas comme Autoload
	if websocket_manager == null:
		# Chercher dans la scène courante
		var main_scene = get_tree().current_scene
		if main_scene:
			websocket_manager = main_scene.get_node_or_null("WebSocketManager")
			if websocket_manager != null:
				print("[GameManager] ✅ WebSocketManager trouvé dans main.tscn")
				_connect_websocket_signals()
			else:
				print("[GameManager] ❌ WebSocketManager non trouvé dans main.tscn")
	
	# SÉLECTION DU MANAGER WEBSOCKET
	# ===============================
	# Utiliser websocket_manager en priorité, ws_manager en fallback (compatibilité)
	var manager = websocket_manager if websocket_manager != null else ws_manager
	
	if not manager:
		print("[GameManager] ❌ ERREUR: Aucun WebSocket manager disponible")
		return
	
	# RÉCUPÉRATION DU TOKEN D'AUTHENTIFICATION
	# =========================================
	var token = AuthManager._access_token if AuthManager else ""
	if token != "":
		print("[GameManager] ✅ Token trouvé, lancement de la connexion...")
		manager.connect_with_auth(token)
	else:
		print("[GameManager] ❌ Pas de token d'authentification, connexion impossible")

## CHARGEMENT D'UNE MAP
## ====================
func load_map(map_id: String, _spawn_x: float = 0.0, _spawn_y: float = 0.0):
	"""
	Charge une map et positionne le joueur à la position spécifiée.
	
	Args:
		map_id (String): ID de la map à charger (ex: "map_0_0")
		_spawn_x (float): Position X de spawn du joueur
		_spawn_y (float): Position Y de spawn du joueur
	"""
	print("[GameManager] === CHARGEMENT DE MAP ===")
	print("[GameManager] Map: ", map_id, " Spawn: (", _spawn_x, ", ", _spawn_y, ")")
	
	# SAUVEGARDE DES COORDONNÉES
	# ===========================
	spawn_x = _spawn_x
	spawn_y = _spawn_y
	current_map_id = map_id
	
	# NETTOYAGE DE L'ÉTAT ACTUEL
	# ===========================
	# Supprimer la map et le joueur actuels avant de charger la nouvelle map
	_cleanup_current_state()
	
	# CHARGEMENT DE LA NOUVELLE MAP
	# ==============================
	var map_path = "res://game/maps/" + map_id + "/" + map_id + ".tscn"
	print("[GameManager] Chemin de la map: ", map_path)
	
	if ResourceLoader.exists(map_path):
		print("[GameManager] ✅ Fichier de map trouvé, chargement...")
		var map_scene = load(map_path)
		current_map = map_scene.instantiate()
		get_tree().current_scene.add_child(current_map)
		print("[GameManager] ✅ Map chargée avec succès: ", map_id)
		
		# GÉNÉRATION AUTOMATIQUE DES TRANSITIONS
		# =======================================
		print("[GameManager] === GÉNÉRATION DES TRANSITIONS AUTOMATIQUES ===")
		MapTransitionGenerator.generate_transitions_for_map(current_map, map_id)
		
		# CRÉATION DU JOUEUR
		# ===================
		# Créer le joueur après avoir chargé la map pour que la navigation fonctionne
		_create_player()
		
		# CHARGEMENT DES MONSTRES
		# ========================
		# Charger les monstres présents sur cette map
		_load_monsters_for_map(map_id)
	else:
		print("[GameManager] ❌ ERREUR: Fichier de map non trouvé: ", map_path)

## NETTOYAGE DE L'ÉTAT ACTUEL
## ===========================
func _cleanup_current_state():
	"""
	Nettoie l'état actuel du jeu : supprime la map, le joueur et les autres joueurs.
	Cette méthode est appelée avant de charger une nouvelle map.
	"""
	print("[GameManager] === NETTOYAGE DE L'ÉTAT ACTUEL ===")
	
	# SUPPRESSION DE LA MAP ACTUELLE
	# ===============================
	if current_map != null:
		print("[GameManager] Suppression de la map actuelle")
		current_map.queue_free()
		current_map = null

	# SUPPRESSION DU JOUEUR ACTUEL
	# =============================
	if current_player != null:
		print("[GameManager] Suppression du joueur actuel")
		current_player.queue_free()
		current_player = null
	
	# SUPPRESSION DES AUTRES JOUEURS
	# ===============================
	_clear_other_players()
	
	# SUPPRESSION DES MONSTRES
	# =========================
	_clear_monsters()
	
	print("[GameManager] Nettoyage terminé")

## CRÉATION DU JOUEUR PRINCIPAL
## =============================
func _create_player():
	"""
	Crée et configure le joueur principal du jeu.
	Connecte tous les signaux nécessaires et configure l'affichage du nom.
	"""
	print("[GameManager] === CRÉATION DU JOUEUR PRINCIPAL ===")
	
	# INSTANCIATION DU JOUEUR
	# ========================
	current_player = player_scene.instantiate()
	current_player.position = Vector2(spawn_x, spawn_y)
	get_tree().current_scene.add_child(current_player)
	print("[GameManager] Joueur instancié à la position: (", spawn_x, ", ", spawn_y, ")")
	
	# CONFIGURATION DU NOM DU JOUEUR
	# ===============================
	if auth_manager != null:
		var username = auth_manager.get_username()
		if username != "":
			var name_label = current_player.get_node_or_null("NameLabel")
			if name_label:
				name_label.text = username
				print("[GameManager] Nom du joueur configuré: ", username)
			else:
				print("[GameManager] ⚠️ NameLabel non trouvé dans le joueur")
		else:
			print("[GameManager] ⚠️ Nom d'utilisateur vide")
	else:
		print("[GameManager] ⚠️ AuthManager non disponible pour le nom")
	
	# CONNEXION DES SIGNAUX DU JOUEUR
	# ================================
	# Ces signaux permettent de réagir aux actions du joueur
	current_player.connect("player_moved", _on_current_player_moved)
	current_player.connect("map_transition_triggered", _on_map_transition_triggered)
	
	# MISE À JOUR DE L'ÉTAT DU JEU
	# =============================
	current_state = GameState.IN_GAME
	print("[GameManager] État du jeu: IN_GAME")
	print("[GameManager] Signaux du joueur connectés")
	
	print("[GameManager] ✅ Joueur principal créé avec succès")

## GESTION DES TRANSITIONS DE MAP
## ===============================

func _on_map_transition_triggered(target_map_id: String, entry_point: Vector2):
	"""
	Appelé quand le joueur entre dans une zone de transition.
	Gère le changement de map côté client et notifie le serveur.
	
	Args:
		target_map_id (String): ID de la map de destination
		entry_point (Vector2): Point d'entrée sur la nouvelle map
	"""
	print("[GameManager] === TRANSITION DE MAP DEMANDÉE ===")
	print("[GameManager] Destination: ", target_map_id, " Point d'entrée: ", entry_point)
	
	# NOTIFICATION DU SERVEUR
	# ========================
	# Essayer de notifier le serveur du changement de map
	var manager = websocket_manager if websocket_manager != null else ws_manager
	if manager and manager.has_method("send_change_map_request"):
		print("[GameManager] Notification serveur du changement de map")
		manager.send_change_map_request(target_map_id)
	else:
		# FALLBACK LOCAL
		# ==============
		# Si pas de serveur, faire le changement localement
		print("[GameManager] Pas de serveur disponible, changement local")
		load_map(target_map_id, entry_point.x, entry_point.y)

## GESTION MULTIJOUEUR
## ====================

func _on_current_player_moved(new_position: Vector2):
	"""
	Notifie le serveur du mouvement du joueur local pour synchronisation multijoueur.
	
	Args:
		new_position (Vector2): Nouvelle position du joueur local
	"""
	var manager = websocket_manager if websocket_manager != null else ws_manager
	if manager and manager.has_method("send_player_move"):
		manager.send_player_move(new_position.x, new_position.y, current_map_id)
		print("[GameManager] Position envoyée au serveur: (", new_position.x, ", ", new_position.y, ")")

func _on_player_joined(player_data):
	"""
	Un nouveau joueur s'est connecté au serveur.
	
	Args:
		player_data (Dictionary): Données du nouveau joueur (user_id, username, position, etc.)
	"""
	print("[GameManager] === NOUVEAU JOUEUR CONNECTÉ ===")
	print("[GameManager] Joueur: ", player_data.get("username", "inconnu"))
	_spawn_other_player(player_data)

func _on_player_left(user_id: String):
	"""
	Un joueur s'est déconnecté du serveur.
	
	Args:
		user_id (String): ID du joueur qui s'est déconnecté
	"""
	print("[GameManager] === JOUEUR DÉCONNECTÉ ===")
	print("[GameManager] User ID: ", user_id)
	_despawn_other_player(user_id)

func _on_player_moved(user_id: String, x: float, y: float):
	"""
	Un autre joueur a bougé, mettre à jour sa position.
	
	Args:
		user_id (String): ID du joueur qui a bougé
		x (float): Nouvelle position X
		y (float): Nouvelle position Y
	"""
	if other_players.has(user_id):
		other_players[user_id].position = Vector2(x, y)
		# Note: Pas de log ici pour éviter le spam, c'est appelé très souvent

func _on_players_list_received(players_array):
	"""
	Liste des joueurs déjà connectés reçue du serveur.
	
	Args:
		players_array (Array): Liste des joueurs connectés
	"""
	print("[GameManager] === LISTE DES JOUEURS REÇUE ===")
	
	# Vérifier que players_array n'est pas null
	if players_array == null:
		print("[GameManager] ⚠️ Liste des joueurs null, aucun joueur à afficher")
		return
	
	print("[GameManager] Nombre de joueurs: ", players_array.size())
	for player_data in players_array:
		_spawn_other_player(player_data)

func _spawn_other_player(player_data):
	"""
	Crée un autre joueur dans le jeu (joueur distant).
	
	Args:
		player_data (Dictionary): Données du joueur à créer
	"""
	# EXTRACTION DES DONNÉES
	# =======================
	var user_id = player_data.get("user_id", "")
	var username = player_data.get("username", "inconnu")
	var x = player_data.get("x", 0.0)
	var y = player_data.get("y", 0.0)
	var map_id = player_data.get("map_id", "")
	
	print("[GameManager] === SPAWN AUTRE JOUEUR ===")
	print("[GameManager] User: ", username, " ID: ", user_id, " Map: ", map_id)
	
	# VÉRIFICATIONS DE VALIDITÉ
	# ==========================
	if user_id == "":
		print("[GameManager] ⚠️ User ID vide, abandon du spawn")
		return
	
	if map_id != current_map_id:
		print("[GameManager] ⚠️ Joueur sur map différente (", map_id, " vs ", current_map_id, "), ignoré")
		return
	
	if other_players.has(user_id):
		print("[GameManager] ⚠️ Joueur déjà présent, ignoré")
		return

	# CRÉATION DU JOUEUR DISTANT
	# ===========================
	var other_player = player_scene.instantiate()
	other_player.position = Vector2(x, y)
	
	# CONFIGURATION DE L'APPARENCE
	# =============================
	var name_label = other_player.get_node_or_null("NameLabel")
	if name_label:
		name_label.text = username
		name_label.modulate = Color.CYAN  # Couleur différente pour les autres joueurs
	
	# DÉSACTIVATION DES CONTRÔLES
	# ============================
	# Les autres joueurs ne doivent pas être contrôlables
	other_player.set_script(null)
	
	# AJOUT À LA SCÈNE
	# ================
	get_tree().current_scene.add_child(other_player)
	other_players[user_id] = other_player
	
	print("[GameManager] ✅ Autre joueur spawné: ", username)

func _despawn_other_player(user_id: String):
	"""
	Supprime un autre joueur du jeu.
	
	Args:
		user_id (String): ID du joueur à supprimer
	"""
	if other_players.has(user_id):
		other_players[user_id].queue_free()
		other_players.erase(user_id)
		print("[GameManager] ✅ Autre joueur supprimé: ", user_id)

func _clear_other_players():
	"""
	Supprime tous les autres joueurs (utilisé lors des changements de map).
	"""
	if other_players.size() > 0:
		print("[GameManager] Suppression de ", other_players.size(), " autres joueurs")
		for player_node in other_players.values():
			player_node.queue_free()
		other_players.clear()

## CALLBACKS WEBSOCKET
## ====================

func _on_map_changed(map_id: String, _spawn_x: float, _spawn_y: float):
	"""
	Callback appelé quand le serveur confirme un changement de map.
	
	Args:
		map_id (String): ID de la nouvelle map
		_spawn_x (float): Position X de spawn
		_spawn_y (float): Position Y de spawn
	"""
	print("[GameManager] === CHANGEMENT DE MAP CONFIRMÉ PAR LE SERVEUR ===")
	print("[GameManager] Nouvelle map: ", map_id, " Position: (", _spawn_x, ", ", _spawn_y, ")")
	print("[GameManager] Map actuelle: ", current_map_id)
	
	# Éviter les changements de map en boucle
	if map_id == current_map_id:
		print("[GameManager] ⚠️ Changement vers la même map ignoré")
		return

	load_map(map_id, _spawn_x, _spawn_y)

func _on_websocket_connected():
	"""Callback appelé quand la connexion WebSocket est établie."""
	print("[GameManager] ✅ WebSocket connecté!")

func _on_websocket_disconnected():
	"""Callback appelé quand la connexion WebSocket est perdue."""
	print("[GameManager] ❌ WebSocket déconnecté")

func _on_websocket_error(error: String):
	"""Callback appelé en cas d'erreur WebSocket."""
	print("[GameManager] ❌ Erreur WebSocket: ", error)

## GESTION DES PERSONNAGES (API REST)
## ==================================
var _characters_response = null
var _classes_response = null

func request_characters():
	"""Demande la liste des personnages ET des classes au serveur."""
	print("[GameManager] Lancement de la requête pour les personnages.")
	
	var token = AuthManager.get_access_token()
	if token.is_empty():
		print("[GameManager] ERREUR: Token vide, utilisateur non authentifié.")
		emit_signal("character_error", "Utilisateur non authentifié.")
		return

	var token_preview = token.substr(0, 20) + "..." if token.length() > 20 else token
	print("[GameManager] Token trouvé: ", token_preview)
	_characters_response = null
	_classes_response = null

	var headers = AuthManager.get_auth_header()
	headers.append("User-Agent: Flumen-Client/1.0")
	print("[GameManager] Headers utilisés: ", headers)
	var api_url = ServerConfig.API_URL
	print("[GameManager] URL de requête: ", api_url + "/characters")
	var err = http_request.request(api_url + "/characters", headers, HTTPClient.METHOD_GET)
	print("[GameManager] Résultat de la requête HTTP: ", err)
	
	if err != OK:
		print("[GameManager] ERREUR: Échec du lancement de la requête, code: ", err)
		emit_signal("character_error", "Échec du lancement de la requête pour les personnages.")

func _on_http_request_completed(_result, response_code, _headers, body):
	print("[GameManager DEBUG] Réponse reçue - Code: ", response_code)
	print("[GameManager DEBUG] Headers de réponse: ", _headers)
	var response_text = body.get_string_from_utf8()
	print("[GameManager DEBUG] Corps de la réponse: '", response_text, "'")
	print("[GameManager DEBUG] Taille du corps: ", body.size(), " bytes")
	
	var response = JSON.parse_string(response_text)
	if response == null:
		print("[GameManager DEBUG] ERREUR: Impossible de parser le JSON.")
		print("[GameManager DEBUG] Contenu brut: ", response_text)
		emit_signal("character_error", "Réponse invalide du serveur.")
		return

	if _characters_response == null: # C'est la réponse de la première requête (/characters)
		if response_code == 200:
			_characters_response = response
			print("[GameManager DEBUG] Personnages reçus: ", _characters_response)
			print("[GameManager] Personnages reçus, demande des classes...")
			var api_url = ServerConfig.API_URL 
			http_request.request(api_url + "/classes")
		elif response_code == 401:
			print("[GameManager DEBUG] Token JWT invalide ou expiré. Redirection vers la connexion.")
			# Nettoyer le token expiré
			AuthManager._access_token = ""
			AuthManager._is_authenticated = false
			# Rediriger vers la scène de connexion
			get_tree().call_deferred("change_scene_to_file", "res://game/ui/LoginScene.tscn")
			return
		else:
			print("[GameManager DEBUG] Échec du chargement des personnages. Code: ", response_code)
			emit_signal("character_error", "Erreur lors du chargement des personnages.")
			return
	else: # C'est la réponse de la deuxième requête (/classes)
		if response_code == 200:
			_classes_response = response
			print("[GameManager DEBUG] Classes reçues: ", _classes_response)
			_process_character_data() # On a maintenant les deux réponses
		else:
			print("[GameManager DEBUG] Échec du chargement des classes. Code: ", response_code)
			emit_signal("character_error", "Erreur lors du chargement des classes.")

func _process_character_data():
	if _characters_response.has("error") or _classes_response.has("error"):
		var error_msg = _characters_response.get("error", "") + " " + _classes_response.get("error", "")
		emit_signal("character_error", error_msg.strip_edges())
	else:
		var combined_data = {
			"success": true,
			"characters": _characters_response,
			"classes": _classes_response
		}
		print("[GameManager DEBUG] Données combinées prêtes à être émises: ", combined_data)
		emit_signal("characters_and_classes_loaded", combined_data)

	# Réinitialiser pour les prochaines requêtes
	_characters_response = null
	_classes_response = null

## GESTION DES PERSONNAGES (API REST)
## ==================================
func create_character(character_name: String, class_id: String):
	"""Crée un personnage via l'API REST (POST /characters)"""
	var token = AuthManager.get_access_token()
	if token.is_empty():
		emit_signal("character_error", "Utilisateur non authentifié.")
		return

	var api_url = ServerConfig.API_URL + "/characters"
	var headers = [
		"Authorization: Bearer " + token,
		"Content-Type: application/json"
	]
	var payload = {
		"name": character_name,
		"class": class_id
	}

	var req := HTTPRequest.new()
	add_child(req)
	req.request_completed.connect(_on_create_character_request_completed.bind(req))
	var err = req.request(api_url, headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
	if err != OK:
		emit_signal("character_error", "Erreur lors de l'envoi de la requête de création.")

func _on_create_character_request_completed(_result, response_code, _headers, body, req: HTTPRequest):
	var response = JSON.parse_string(body.get_string_from_utf8())
	if response_code == 201:
		emit_signal("character_created", {"success": true, "character": response})
	else:
		var msg = response.get("error", "Erreur lors de la création du personnage.") if typeof(response) == TYPE_DICTIONARY else "Erreur inconnue."
		emit_signal("character_error", msg)
	req.queue_free()

func delete_character(character_id: int):
	"""Supprime un personnage via l'API REST (DELETE /characters/{id})"""
	var token = AuthManager.get_access_token()
	if token.is_empty():
		emit_signal("character_error", "Utilisateur non authentifié.")
		return
	var api_url = ServerConfig.API_URL + "/characters/" + str(character_id)
	var headers = ["Authorization: Bearer " + token]
	var req := HTTPRequest.new()
	add_child(req)
	req.request_completed.connect(_on_delete_character_request_completed.bind(req))
	var err = req.request(api_url, headers, HTTPClient.METHOD_DELETE)
	if err != OK:
		emit_signal("character_error", "Erreur lors de l'envoi de la requête de suppression.")

func _on_delete_character_request_completed(_result, response_code, _headers, body, req: HTTPRequest):
	if response_code == 204:
		emit_signal("character_deleted", {"success": true})
	else:
		var response = JSON.parse_string(body.get_string_from_utf8())
		var msg = response.get("error", "Erreur lors de la suppression du personnage.") if typeof(response) == TYPE_DICTIONARY else "Erreur inconnue."
		emit_signal("character_error", msg)
	req.queue_free()

func select_character(character_id: String):
	"""Sélectionne un personnage et récupère un nouveau token via l'API."""
	var token = AuthManager.get_access_token()
	if token.is_empty():
		emit_signal("character_error", "Utilisateur non authentifié.")
		return

	var api_url = ServerConfig.API_URL + "/characters/" + str(character_id) + "/select"
	var headers = [
		"Authorization: Bearer " + token,
		"Content-Type: application/json"
	]
	var req := HTTPRequest.new()
	add_child(req)
	req.request_completed.connect(_on_select_character_request_completed.bind(req))
	var err = req.request(api_url, headers, HTTPClient.METHOD_POST)
	if err != OK:
		emit_signal("character_error", "Erreur lors de l'envoi de la requête de sélection.")

func _on_select_character_request_completed(_result, response_code, _headers, body, req: HTTPRequest):
	var response = JSON.parse_string(body.get_string_from_utf8())
	if response_code == 200:
		# Récupère le nouveau token et stocke dans AuthManager
		var new_token = response.get("token", "")
		if new_token != "":
			AuthManager.set_access_token(new_token)
			emit_signal("character_selected", {"success": true, "character": response})
		else:
			emit_signal("character_error", "Token manquant dans la réponse.")
	else:
		var msg = response.get("error", "Erreur lors de la sélection du personnage.") if typeof(response) == TYPE_DICTIONARY else "Erreur inconnue."
		emit_signal("character_error", msg)
	req.queue_free()

## ACCESSEURS PUBLICS
## ===================
func get_current_map() -> Node:
	"""
	Retourne la map actuellement chargée.
	Utilisé par le Player pour rechercher les NavigationRegion2D.
	
	Returns:
		Node: Instance de la map actuelle ou null si aucune map chargée
	"""
	return current_map

func get_current_player() -> CharacterBody2D:
	"""
	Retourne le joueur principal actuellement actif.
	
	Returns:
		CharacterBody2D: Instance du joueur principal ou null
	"""
	return current_player

func send_websocket_message(type: String, data: Dictionary):
	# Utiliser la référence locale du WebSocketManager si disponible
	var manager = websocket_manager
	if not manager:
		# Essayer de le récupérer depuis la scène principale si pas encore initialisé
		var main_scene = get_tree().current_scene
		if main_scene and main_scene.has_node("WebSocketManager"):
			manager = main_scene.get_node("WebSocketManager")
	
	if manager:
		var message = {
			"type": type,
			"data": data,
			"timestamp": Time.get_unix_time_from_system()
		}
		manager.send_message(JSON.stringify(message))
		print("[GameManager] 📤 Message WebSocket envoyé: ", type, " avec données: ", data)
	else:
		print("[GameManager] ❌ Pas de WebSocket manager disponible")

## ===================================
## GESTION DES MONSTRES
## ===================================

func _load_monsters_for_map(map_id: String):
	"""Charge les monstres présents sur une map"""
	print("[GameManager] === CHARGEMENT DES MONSTRES ===")
	print("[GameManager] Map: ", map_id)
	
	# Requête HTTP pour récupérer les monstres de la map
	var token = auth_manager.get_access_token()
	if token == "":
		print("[GameManager] ❌ Token manquant pour charger les monstres")
		return
	
	var url = "http://127.0.0.1:9090/api/v1/monsters/map/" + map_id
	var headers = [
		"Authorization: Bearer " + token,
		"Content-Type: application/json"
	]
	
	var request = HTTPRequest.new()
	add_child(request)
	request.request_completed.connect(_on_monsters_loaded)
	request.request(url, headers, HTTPClient.METHOD_GET)
	
	print("[GameManager] Requête des monstres envoyée pour: ", map_id)

func _on_monsters_loaded(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
	"""Callback quand les monstres sont chargés"""
	print("[GameManager] === RÉPONSE MONSTRES ===")
	print("[GameManager] Code: ", response_code)
	
	if response_code == 200:
		var json = JSON.new()
		var parse_result = json.parse(body.get_string_from_utf8())
		
		if parse_result == OK:
			var data = json.data
			if data.has("monsters") and data["monsters"] != null:
				var monsters_data = data["monsters"]
				print("[GameManager] Monstres trouvés: ", len(monsters_data))
				
				# Créer les monstres
				for monster_data in monsters_data:
					_create_monster(monster_data)
			else:
				print("[GameManager] Aucun monstre sur cette map")
		else:
			print("[GameManager] ❌ Erreur parsing JSON monstres")
	else:
		print("[GameManager] ❌ Erreur chargement monstres: ", response_code)

func _create_monster(monster_data: Dictionary):
	"""Crée un monstre à partir des données serveur"""
	var monster_id = monster_data.get("id", "")
	if monster_id == "":
		print("[GameManager] ❌ ID monstre manquant")
		return
	
	# Vérifier si le monstre existe déjà
	if monsters.has(monster_id):
		print("[GameManager] Monstre déjà existant: ", monster_id)
		return
	
	# Créer l'instance du monstre
	var monster_instance = monster_scene.instantiate()
	monster_instance.initialize_monster(monster_data)
	
	# Ajouter à la map
	if current_map:
		current_map.add_child(monster_instance)
		monsters[monster_id] = monster_instance
		monsters_on_map.append(monster_instance)
		
		# Connecter tous les signaux d'interaction
		connect_monster_signals(monster_instance)
		
		print("[GameManager] ✅ Monstre créé: ", monster_data.get("name", "Inconnu"))
	else:
		print("[GameManager] ❌ Pas de map pour ajouter le monstre")
		monster_instance.queue_free()

func connect_monster_signals(monster: Monster):
	"""Connecte les signaux d'interaction d'un monstre au GameManager."""
	if not is_instance_valid(monster):
		print("[GameManager] ❌ Tentative de connexion sur un monstre invalide.")
		return
	
	# Connecter le clic pour initier le combat
	if monster.has_user_signal("monster_clicked"):
		# Utiliser call_deferred pour éviter les bugs si le signal est émis dans la même frame
		monster.connect("monster_clicked", Callable(self, "_on_monster_clicked"))
	else:
		print("[GameManager] ⚠️ Le signal 'monster_clicked' est manquant sur la scène Monster.")
	
	# Connecter le clic droit pour initier le combat
	if monster.has_user_signal("monster_right_clicked"):
		monster.connect("monster_right_clicked", Callable(self, "_on_monster_right_clicked"))
	else:
		print("[GameManager] ⚠️ Le signal 'monster_right_clicked' est manquant sur la scène Monster.")
		
	# Connecter le survol pour le tooltip
	if monster.has_user_signal("monster_hovered"):
		monster.connect("monster_hovered", Callable(self, "_on_monster_hovered"))
	else:
		print("[GameManager] ⚠️ Le signal 'monster_hovered' est manquant sur la scène Monster.")
		
	# Connecter la mort du monstre
	if monster.has_user_signal("monster_died"):
		monster.connect("monster_died", Callable(self, "_on_monster_died"))
	else:
		print("[GameManager] ⚠️ Le signal 'monster_died' est manquant sur la scène Monster.")

func _clear_monsters():
	"""Supprime tous les monstres"""
	print("[GameManager] Suppression des monstres")
	for monster_id in monsters.keys():
		var monster = monsters[monster_id]
		if monster and is_instance_valid(monster):
			monster.queue_free()
	monsters.clear()
	monsters_on_map.clear()
	
	# Cacher le tooltip s'il est visible
	if monster_tooltip:
		monster_tooltip.hide_tooltip()

func _on_monster_clicked(monster: Monster):
	"""Gère le clic gauche sur un monstre pour lancer le combat."""
	print("[GameManager] ⚔️ Clic gauche sur monstre reçu pour lancer le combat: ", monster.monster_name)
	
	if combat_manager and not combat_manager.is_combat_active:
		start_combat_with_monster(monster)
	elif combat_manager and combat_manager.is_combat_active:
		print("[GameManager] ⚠️ Un combat est déjà en cours.")
	else:
		print("[GameManager] ❌ Le CombatManager n'est pas prêt.")

func _on_monster_right_clicked(monster: Monster):
	"""Gère le clic droit sur un monstre pour lancer le combat."""
	print("[GameManager] ⚔️ Clic droit sur monstre reçu pour lancer le combat: ", monster.monster_name)
	
	if combat_manager and not combat_manager.is_combat_active:
		start_combat_with_monster(monster)
	elif combat_manager and combat_manager.is_combat_active:
		print("[GameManager] ⚠️ Un combat est déjà en cours.")
	else:
		print("[GameManager] ❌ Le CombatManager n'est pas prêt.")

func _on_monster_died(monster: Monster):
	"""Callback quand un monstre meurt"""
	print("[GameManager] Monstre mort: ", monster.monster_name)
	
	# Supprimer de la liste
	if monsters.has(monster.monster_id):
		monsters.erase(monster.monster_id)
	
	# Ici, on pourrait :
	# - Donner de l'XP au joueur
	# - Générer du butin
	# - Notifier le serveur

## SIGNAUX
## =======
signal characters_and_classes_loaded(data: Dictionary)
signal character_selected(character_data)
signal character_created(character_data)
signal character_deleted(character_id)
signal character_error(message: String)

## SYSTÈME DE TOOLTIP ET INTERACTIONS MONSTRES
## ===============================================

func setup_monster_tooltip():
	"""Initialise le système de tooltip pour les monstres"""
	if monster_tooltip:
		return  # Déjà initialisé
	
	# Charger la scène du tooltip
	var tooltip_scene = preload("res://game/ui/MonsterTooltip.tscn")
	monster_tooltip = tooltip_scene.instantiate()
	
	# Ajouter au niveau le plus haut pour qu'il soit toujours visible
	get_tree().current_scene.add_child(monster_tooltip)
	
	print("[GameManager] Système de tooltip initialisé")

func _on_monster_hovered(monster: Monster, is_hovering: bool):
	"""Gère le survol des monstres"""
	if not monster_tooltip:
		return
	
	if is_hovering:
		# Afficher le tooltip
		var mouse_pos = get_viewport().get_mouse_position()
		monster_tooltip.show_monster_info(monster, mouse_pos)
	else:
		# Cacher le tooltip
		monster_tooltip.hide_tooltip()

func start_combat_with_monster(monster: Monster):
	"""Démarre un combat tactique avec un monstre en envoyant une requête au serveur."""
	print("[GameManager] ⚔️ Demande de lancement de combat avec le monstre: ", monster.monster_name)
	
	if not monster or not is_instance_valid(monster):
		print("[GameManager] ❌ Monstre invalide, impossible de lancer le combat.")
		return
		
	var monster_id = monster.monster_id
	if monster_id == "":
		print("[GameManager] ❌ ID de monstre vide, impossible de lancer le combat.")
		return

	print("[GameManager] -> Envoi de la requête 'initiate_combat' au serveur pour le monstre ID: ", monster_id)
	
	# Envoyer la requête au serveur via le WebSocketManager
	# Le serveur sera responsable de créer le combat et de notifier les clients.
	send_websocket_message("initiate_combat", {
		"monster_id": monster_id
	})
	
	# La logique de `combat_manager.start_combat` sera maintenant déclenchée
	# par un message entrant du serveur (ex: "combat_started").

## SYSTÈME DE COMBAT
## ==================
func initialize_combat_system():
	"""Initialise le système de combat tactique"""
	print("[GameManager] 🔧 Initialisation du système de combat...")
	
	# Charger le gestionnaire de combat
	var combat_manager_script = preload("res://game/combat/CombatManager.gd")
	combat_manager = combat_manager_script.new()
	combat_manager.name = "CombatManager"
	add_child(combat_manager)
	
	# Initialiser tous les systèmes de combat
	combat_manager.initialize_combat_systems()
	
	# Connecter les signaux de combat
	# Note: ces signaux sont maintenant déclenchés par le CombatManager local
	# et n'entrent pas en conflit avec les signaux du serveur.
	combat_manager.combat_ended.connect(_on_local_combat_ended)
	
	print("[GameManager] ✅ Système de combat initialisé")

func _on_local_combat_ended(winning_team):
	"""Appelé quand un combat local se termine"""
	print("[GameManager] 🏁 Combat terminé - Gagnant: ", winning_team)
	
	# Réactiver les contrôles de déplacement normal
	if current_player and current_player.has_method("set_movement_enabled"):
		current_player.set_movement_enabled(true)
	
	current_state = GameState.IN_GAME
	print("[GameManager] État du jeu: IN_GAME")

## COMBAT MOVEMENT - Handled by CombatManager via synchronized combat state
## Movement actions are now processed through CombatManager.process_action()
## instead of direct signal callbacks

## TESTS DE COMBAT
## ===============
func test_combat_system():
	"""Lance un combat de test pour vérifier le système"""
	print("[GameManager] 🧪 Lancement d'un test de combat...")
	
	if not combat_manager:
		print("[GameManager] ❌ Combat manager non trouvé")
		return
	
	# Forcer l'arrêt d'un combat en cours
	if combat_manager.is_combat_active:
		print("[GameManager] 🔄 Arrêt du combat en cours...")
		combat_manager.end_combat({"result": "test_ended", "winner": "test"})
		current_state = GameState.IN_GAME
	
	# Lancer le combat de test avec la nouvelle architecture
	current_state = GameState.IN_COMBAT
	print("[GameManager] État du jeu: IN_COMBAT")
	
	# Créer des données de combat compatibles serveur pour test
	var test_combat_data = {
		"id": "test_combat_001",
		"status": "STARTING",
		"current_turn_index": 0,
		"turn_timer": 30,
		"current_map_id": current_map_id,
		"combatants": [
			{
				"id": "test_ally",
				"name": "Testeur", 
				"team": 0,
				"position": {"x": 7, "y": 8},
				"stats": {
					"health": 100,
					"max_health": 100,
					"action_points": 6,
					"max_action_points": 6,
					"movement_points": 3,
					"max_movement_points": 3
				},
				"initiative": 15,
				"active_effects": [],
				"is_alive": true
			},
			{
				"id": "test_enemy",
				"name": "Monstre Test",
				"team": 1,
				"position": {"x": 10, "y": 8},
				"stats": {
					"health": 50,
					"max_health": 50,
					"action_points": 4,
					"max_action_points": 4,
					"movement_points": 2,
					"max_movement_points": 2
				},
				"initiative": 10,
				"active_effects": [],
				"is_alive": true
			}
		]
	}
	
	combat_manager.start_combat_from_server(test_combat_data)
	
	# NOUVEAU : Timer automatique pour terminer le combat de test
	print("[GameManager] ⏰ Combat de test terminera automatiquement dans 10 secondes")
	await get_tree().create_timer(10.0).timeout
	
	if combat_manager and combat_manager.is_combat_active:
		print("[GameManager] ⏰ Fin automatique du combat de test")
		combat_manager.end_combat({"result": "test_timeout", "winner": "ally"})
		current_state = GameState.IN_GAME
		print("[GameManager] ✅ Combat de test terminé automatiquement")

func _input(event):
	"""Gestion des entrées pour les tests de combat"""
	# Test de combat avec la touche T (quand en jeu et pas en combat)
	if event is InputEventKey and event.pressed and event.keycode == KEY_T:
		if current_state == GameState.IN_GAME and current_player:
			# Vérifier qu'on n'est pas déjà en combat
			if not combat_manager or not combat_manager.is_combat_active:
				test_combat_system()
			else:
				print("[GameManager] ⚠️ Combat déjà en cours")
	
	# Test des interactions monstres avec la touche M
	if event is InputEventKey and event.pressed and event.keycode == KEY_M:
		test_monster_interactions()
	
	# NOUVEAU : Terminer un combat avec Échap
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if combat_manager and combat_manager.is_combat_active:
			print("[GameManager] 🛑 Arrêt manuel du combat (Échap)")
			combat_manager.end_combat(CombatTurnManager.Team.ALLY)
			current_state = GameState.IN_GAME
			print("[GameManager] ✅ Combat terminé manuellement")
	
	# NOUVEAU : Reset complet du système de combat avec R
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		print("[GameManager] 🔄 Reset complet du système de combat")
		if combat_manager:
			if combat_manager.is_combat_active:
				combat_manager.end_combat(CombatTurnManager.Team.ALLY)
			current_state = GameState.IN_GAME
			print("[GameManager] ✅ Système de combat réinitialisé")
	
	# NOUVEAU : Debug visuel de la grille avec G
	if event is InputEventKey and event.pressed and event.keycode == KEY_G:
		print("[GameManager] 🔍 ACTIVATION DEBUG GRILLE")
		if combat_manager and combat_manager.combat_grid:
			combat_manager.combat_grid.force_visible_debug()
		else:
			print("[GameManager] ❌ Combat manager ou grille non disponible")

func test_monster_interactions():
	"""Teste les interactions avec les monstres"""
	print("[GameManager] 🧪 Test des interactions monstres...")
	print("[GameManager] Nombre de monstres sur la map: ", monsters_on_map.size())
	
	for monster in monsters_on_map:
		print("[GameManager] - Monstre: ", monster.monster_name, " Position: ", monster.position)
		print("[GameManager] - Zone d'interaction: ", monster.interaction_area != null)
		if monster.interaction_area:
			print("[GameManager] - input_pickable: ", monster.interaction_area.input_pickable)
			print("[GameManager] - monitoring: ", monster.interaction_area.monitoring)
	
	# Tester le combat avec le premier monstre disponible
	if monsters_on_map.size() > 0:
		var test_monster = monsters_on_map[0]
		print("[GameManager] 🎯 Test de combat avec: ", test_monster.monster_name)
		_on_monster_clicked(test_monster)

func _on_create_name_input_text_changed(_new_text: String):
	# TODO: Ajouter une validation en temps réel du nom si nécessaire
	pass
