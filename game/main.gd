extends Node2D

## GESTIONNAIRE PRINCIPAL DE LA SCÈNE DE JEU
## ===========================================
## Ce script gère l'interface utilisateur, la caméra et la coordination avec le GameManager.
## Il ne gère PAS directement le joueur ou les maps - c'est le rôle du GameManager.

## RÉFÉRENCES AUX NŒUDS DE LA SCÈNE
## =================================
@onready var websocket_manager = $WebSocketManager  # Gestionnaire de connexion WebSocket
@onready var camera = $Camera2D                     # Caméra principale du jeu
@onready var hud = $UILayer/HUD                     # Interface utilisateur HUD style Dofus

## VARIABLES D'ÉTAT
## =================
var fallback_executed: bool = false  # Empêche l'exécution multiple du fallback

## INITIALISATION DE LA SCÈNE PRINCIPALE
## ======================================
func _ready():
	print("[Main] === INITIALISATION SCÈNE PRINCIPALE ===")
	
	# CONFIGURATION DU REDIMENSIONNEMENT
	# ===================================
	# Connecter le signal de redimensionnement de fenêtre pour ajuster la caméra
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	
	# VÉRIFICATION DE L'AUTHENTIFICATION
	# ===================================
	# Si le joueur n'est pas authentifié, retourner à l'écran de connexion
	if not AuthManager.is_authenticated():
		print("[Main] ❌ Joueur non authentifié, redirection vers login")
		get_tree().change_scene_to_file("res://game/LoginScene.tscn")
		return
	
	print("[Main] ✅ Joueur authentifié: ", AuthManager.get_username())
	
	# CONFIGURATION DES SIGNAUX WEBSOCKET
	# ====================================
	# Connecter les signaux pour réagir aux événements de connexion
	websocket_manager.connected.connect(_on_websocket_connected)
	websocket_manager.disconnected.connect(_on_websocket_disconnected)
	websocket_manager.connection_error.connect(_on_websocket_error)
	
	# LIAISON AVEC LE GAMEMANAGER
	# ============================
	# Informer le GameManager du WebSocket manager pour compatibilité
	GameManager.ws_manager = websocket_manager
	
	# LANCEMENT DE LA CONNEXION
	# ==========================
	print("[Main] Lancement de la connexion au serveur de jeu...")
	GameManager.connect_to_game_server()
	
	# FALLBACK DE SÉCURITÉ
	# ====================
	# Si la connexion échoue, charger la map en mode hors ligne après 5 secondes
	print("[Main] Fallback programmé dans 5 secondes si connexion échoue")
	get_tree().create_timer(5.0).timeout.connect(_fallback_load_map)



## CALLBACK: CONNEXION WEBSOCKET RÉUSSIE
## ======================================
func _on_websocket_connected():
	"""
	Appelé quand la connexion WebSocket est établie avec succès.
	Lance le chargement de la map et la création de l'interface.
	"""
	print("[Main] === CONNEXION WEBSOCKET RÉUSSIE ===")
	
	# LECTURE DES DONNÉES JWT
	# =======================
	# Récupérer les informations du joueur depuis le token JWT
	var payload = AuthManager.get_jwt_payload()
	var map_id = payload.get("map_id", "map_0_0")
	var pos_x = payload.get("pos_x", 758.0)  # Position par défaut au centre
	var pos_y = payload.get("pos_y", 605.0)
	
	print("[Main] Données JWT - Map: ", map_id, " Position: (", pos_x, ", ", pos_y, ")")
	
	# CONFIGURATION DE LA CAMÉRA
	# ===========================
	# Configurer la caméra adaptative avant de charger la map
	_setup_adaptive_camera()
	
	# CHARGEMENT DE LA MAP VIA GAMEMANAGER
	# =====================================
	# Le GameManager s'occupe de charger la map et créer le joueur
	print("[Main] Chargement de la map via GameManager...")
	GameManager.load_map(map_id, pos_x, pos_y)
	
	# INITIALISATION DU HUD
	# ======================
	print("[Main] Initialisation du HUD...")
	if hud:
		hud.visible = true
		print("[Main] HUD activé avec succès - Position: ", hud.position, " Taille: ", hud.size)
	else:
		print("[Main] ❌ HUD non trouvé !")
	
	print("[Main] Initialisation terminée avec succès!")

## CALLBACK: DÉCONNEXION WEBSOCKET
## ================================
func _on_websocket_disconnected():
	"""
	Appelé quand la connexion WebSocket est perdue.
	Met à jour l'interface pour indiquer le mode hors ligne.
	"""
	print("[Main] === CONNEXION WEBSOCKET PERDUE ===")
	# Le HUD gère lui-même l'affichage des états de connexion

## CALLBACK: ERREUR WEBSOCKET
## ===========================
func _on_websocket_error(error_message: String):
	"""
	Appelé en cas d'erreur de connexion WebSocket.
	Affiche l'erreur dans l'interface utilisateur.
	"""
	print("[Main] === ERREUR WEBSOCKET ===")
	print("[Main] Erreur: ", error_message)
	# Le HUD gère lui-même l'affichage des états de connexion

## FALLBACK: CHARGEMENT HORS LIGNE
## ================================
func _fallback_load_map():
	"""
	Fallback de sécurité : charge la map en mode hors ligne si la connexion WebSocket échoue.
	Ne s'exécute que si aucune map n'est encore chargée ET si le fallback n'a pas déjà été exécuté.
	"""
	print("[Main] === VÉRIFICATION FALLBACK ===")
	
	# VÉRIFICATIONS DE SÉCURITÉ
	# ==========================
	# Ne pas exécuter le fallback si :
	# 1. Il a déjà été exécuté
	# 2. WebSocket est connecté
	# 3. Une map est déjà chargée
	
	if fallback_executed:
		print("[Main] Fallback déjà exécuté, abandon")
		return
	
	if websocket_manager.is_user_connected():
		print("[Main] WebSocket connecté, fallback non nécessaire")
		return
	
	if GameManager.current_map_id != "":
		print("[Main] Map déjà chargée: ", GameManager.current_map_id, ", fallback non nécessaire")
		return
	
	# EXÉCUTION DU FALLBACK
	# ======================
	print("[Main] === EXÉCUTION DU FALLBACK (MODE HORS LIGNE) ===")
	fallback_executed = true
	
	# Lire les données du token JWT
	var payload = AuthManager.get_jwt_payload()
	var map_id = payload.get("map_id", "map_0_0")
	var pos_x = payload.get("pos_x", 758.0)
	var pos_y = payload.get("pos_y", 605.0)
	
	print("[Main] Chargement hors ligne - Map: ", map_id, " Position: (", pos_x, ", ", pos_y, ")")
	
	# Configurer la caméra
	_setup_adaptive_camera()
	
	# Charger la map via le GameManager
	GameManager.load_map(map_id, pos_x, pos_y)
	
	# Initialiser le HUD en mode hors ligne
	if hud:
		hud.visible = true
		print("[Main] HUD activé en mode hors ligne")
	else:
		print("[Main] ❌ HUD non trouvé en mode hors ligne !")
	
	print("[Main] Mode hors ligne activé avec succès")



## CONFIGURATION DE LA CAMÉRA ADAPTATIVE
## =======================================
func _setup_adaptive_camera():
	"""
	Configure la caméra pour s'adapter automatiquement à toutes les résolutions d'écran.
	Calcule le zoom optimal pour afficher toute la map tout en gardant les proportions.
	"""
	print("[Main] === CONFIGURATION CAMÉRA ADAPTATIVE ===")
	
	# CALCUL DES DIMENSIONS
	# =====================
	# Taille de la fenêtre actuelle
	var screen_size = get_viewport().get_visible_rect().size
	print("[Main] Taille écran: ", screen_size)
	
	# Taille de la map (basée sur le sprite map_0_0.png avec son scale)
	var map_base_size = Vector2(1536, 1024)  # Taille originale de la texture
	var map_scale = Vector2(1.25, 1.05176)   # Scale appliqué dans la scène
	var map_size = map_base_size * map_scale
	print("[Main] Taille map: ", map_size)
	
	# CALCUL DU ZOOM OPTIMAL
	# =======================
	# Calculer le zoom nécessaire pour afficher toute la map
	var zoom_x = screen_size.x / map_size.x
	var zoom_y = screen_size.y / map_size.y
	var zoom_factor = min(zoom_x, zoom_y)  # Garder les proportions
	
	print("[Main] Zoom calculé: ", zoom_factor)
	
	# APPLICATION DES PARAMÈTRES CAMÉRA
	# ==================================
	# Appliquer le zoom à la caméra
	camera.zoom = Vector2(zoom_factor, zoom_factor)
	
	# Centrer la caméra sur le centre de la map
	var map_center = map_size / 2
	camera.position = map_center
	camera.enabled = true
	
	print("[Main] Caméra configurée - Centre: ", map_center, " Zoom: ", zoom_factor)

## CALLBACK: REDIMENSIONNEMENT DE FENÊTRE
## =======================================
func _on_viewport_size_changed():
	"""
	Appelé automatiquement quand la taille de la fenêtre change.
	Reconfigure la caméra pour s'adapter à la nouvelle taille.
	"""
	print("[Main] === REDIMENSIONNEMENT FENÊTRE ===")
	if camera != null:
		_setup_adaptive_camera()
		print("[Main] Caméra ajustée à la nouvelle taille de fenêtre")
