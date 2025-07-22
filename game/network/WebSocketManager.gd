extends Node
class_name WebSocketManager

signal map_changed(map_id, spawn_x, spawn_y)
signal connected()
signal disconnected()
signal connection_error(error_message)
signal player_joined(player_data)
signal player_left(user_id)
signal player_moved(user_id, x, y)
signal players_list_received(players)
signal combat_started(combat_data)
signal combat_update(update_data)
signal combat_action_response(response_data)
signal combat_ended(end_data)
signal monsters_data(data)

# Signaux pour les personnages
signal characters_list_received(characters_data)
signal character_selected(character_data)
signal character_created(character_data)
signal character_deleted(character_data)
signal character_error(error_message)

var ws := WebSocketPeer.new()
var url := ""  # Sera défini dans _ready()
var _is_connected := false
var auth_token := ""
var current_user := ""
var _last_error_log_time := 0 # En millisecondes, pour limiter la fréquence des logs d'erreur

# Mécanisme de retry automatique
var _retry_enabled := false
var _retry_timer: Timer
var _retry_interval := 3.0  # Interval en secondes entre les tentatives
var _max_retry_attempts := 0  # 0 = retry infini
var _current_retry_count := 0

func _ready():
	print("[WebSocketManager] _ready() appelé.")
	# Utiliser l'URL depuis la configuration
	url = ServerConfig.websocket_url
	print("[WebSocketManager] Using WebSocket URL: ", url)
	
	# Créer le timer pour les tentatives de reconnexion
	_retry_timer = Timer.new()
	_retry_timer.wait_time = _retry_interval
	_retry_timer.timeout.connect(_retry_connection)
	_retry_timer.one_shot = true
	add_child(_retry_timer)
	
	print("[WebSocketManager] Mécanisme de retry initialisé (interval: ", _retry_interval, "s)")

func connect_with_auth(token: String):
	auth_token = token
	_connect_to_server()

func connect_with_auth_retry(token: String, enable_retry: bool = true, retry_interval: float = 3.0, max_attempts: int = 0):
	"""
	Connecte au serveur avec retry automatique si la connexion échoue
	
	Args:
		token: Token d'authentification JWT
		enable_retry: Active le retry automatique (défaut: true)
		retry_interval: Interval entre les tentatives en secondes (défaut: 3.0)
		max_attempts: Nombre max de tentatives (0 = infini, défaut: 0)
	"""
	auth_token = token
	_retry_enabled = enable_retry
	_retry_interval = retry_interval
	_max_retry_attempts = max_attempts
	_current_retry_count = 0
	
	if _retry_timer:
		_retry_timer.wait_time = _retry_interval
	
	print("[WebSocketManager] Connexion avec retry - Enabled: ", enable_retry, ", Interval: ", retry_interval, "s, Max: ", max_attempts)
	_connect_to_server()

func _connect_to_server():
	if auth_token == "":
		print("[WebSocketManager] Pas de token d'authentification, connexion annulée")
		emit_signal("connection_error", "Pas de token d'authentification")
		return
	
	_current_retry_count += 1
	var retry_text = ""
	if _retry_enabled and _current_retry_count > 1:
		retry_text = " (Tentative " + str(_current_retry_count)
		if _max_retry_attempts > 0:
			retry_text += "/" + str(_max_retry_attempts)
		retry_text += ")"
	
	print("[WebSocketManager] Tentative de connexion WebSocket...", retry_text)
	
	var full_url = url + "?token=" + auth_token
	print("[WebSocketManager] Connexion à l'URL: ", full_url)
	print("[WebSocketManager] Token (premiers 20 chars): ", auth_token.substr(0, 20), "...")
	
	# Dans Godot 4, connect_to_url ne prend que l'URL
	var err = ws.connect_to_url(full_url)
	
	if err != OK:
		print("[WebSocketManager] Erreur de connexion au WebSocket :", err)
		emit_signal("connection_error", "Erreur de connexion: " + str(err))
		_schedule_retry_if_enabled()
	else:
		print("[WebSocketManager] connect_to_url() appelé avec succès, attente de la connexion...")

func _schedule_retry_if_enabled():
	"""
	Programme une nouvelle tentative si le retry est activé
	"""
	if not _retry_enabled:
		print("[WebSocketManager] Retry désactivé, arrêt des tentatives")
		return
	
	if _max_retry_attempts > 0 and _current_retry_count >= _max_retry_attempts:
		print("[WebSocketManager] Nombre maximum de tentatives atteint (", _max_retry_attempts, "), arrêt du retry")
		_retry_enabled = false
		return
	
	print("[WebSocketManager] Nouvelle tentative programmée dans ", _retry_interval, " secondes...")
	if _retry_timer:
		_retry_timer.start()

func _retry_connection():
	"""
	Appelé par le timer pour tenter une nouvelle connexion
	"""
	print("[WebSocketManager] === TENTATIVE DE RECONNEXION ===")
	_connect_to_server()

func stop_retry():
	"""
	Arrête le mécanisme de retry
	"""
	_retry_enabled = false
	if _retry_timer:
		_retry_timer.stop()
	print("[WebSocketManager] Mécanisme de retry arrêté")

func _process(_delta):
	if ws == null:
		return

	ws.poll()

	match ws.get_ready_state():
		WebSocketPeer.STATE_CONNECTING:
			pass
		WebSocketPeer.STATE_OPEN:
			if not _is_connected:
				_is_connected = true
				_retry_enabled = false  # Arrêter le retry quand connexion réussie
				if _retry_timer:
					_retry_timer.stop()
				print("[WebSocketManager] ✅ Connecté avec succès!")
				emit_signal("connected")
			
			while ws.get_available_packet_count() > 0:
				var packet = ws.get_packet()
				var message = packet.get_string_from_utf8()
				_on_message_received(message)
		WebSocketPeer.STATE_CLOSING:
			pass # Ne rien faire
		WebSocketPeer.STATE_CLOSED:
			var code = ws.get_close_code()
			var reason = ws.get_close_reason()
			if _is_connected: # Ne traiter la déconnexion qu'une seule fois
				_is_connected = false
				print("[WebSocketManager] Connexion fermée, code: ", code, ", raison: ", reason)
				emit_signal("disconnected")
			
				if code != 1000: # 1000 = Close normal
					emit_signal("connection_error", "Connexion perdue (code: " + str(code) + ")")
					# Programmer un retry si la connexion était établie puis perdue
					if _retry_enabled:
						_schedule_retry_if_enabled()
			else: # La connexion n'a jamais été établie
				var now := Time.get_ticks_msec()
				if now - _last_error_log_time > 1000:
					print("[WebSocketManager] Connexion WebSocket échouée, code: ", code, ", raison: ", reason)
					_last_error_log_time = now
					emit_signal("connection_error", "Échec de la connexion WebSocket (code: %s)" % str(code))
				
				# Programmer un retry pour cette tentative échouée
				_schedule_retry_if_enabled()

func _on_message_received(message: String):
	print("[WebSocketManager] Message reçu: ", message)
	
	# Parser le message JSON
	var json = JSON.new()
	if json.parse(message) != OK:
		print("[WebSocketManager] Erreur de parsing JSON: ", message)
		return
	
	var data = json.data
	if not data.has("type"):
		print("[WebSocketManager] Message sans type: ", message)
		return
	
	match data.type:
		"player_move":
			_handle_player_move(data.data)
		"player_join":
			_handle_player_join(data.data)
		"player_leave":
			_handle_player_leave(data.data)
		"players_list":
			_handle_players_list(data.data)
		"map_changed":
			_handle_map_changed(data.data)
		"combat_started":
			_handle_combat_started(data.data)
		"combat_update":
			_handle_combat_update(data.data)
		"combat_action_response":
			_handle_combat_action_response(data.data)
		"combat_ended":
			_handle_combat_ended(data.data)
		# Messages de personnages
		"characters_list":
			_handle_characters_list(data.data)
		"character_selected":
			_handle_character_selected(data.data)
		"character_created":
			_handle_character_created(data.data)
		"character_deleted":
			_handle_character_deleted(data.data)
		"error":
			_handle_error(data.data)
		_:
			# Anciens messages (MAP_CHANGED, etc.)
			if message.begins_with("MAP_CHANGED:"):
				var parts = message.split(":")
				if parts.size() == 4: 
					var map_id = parts[1]
					var spawn_x = float(parts[2])
					var spawn_y = float(parts[3])
					print("[WebSocketManager] Confirmation de changement de map reçue pour: ", map_id, " à (", spawn_x, ", ", spawn_y, ")")
					emit_signal("map_changed", map_id, spawn_x, spawn_y)

func _handle_player_move(data):
	if data.has("user_id") and data.has("x") and data.has("y"):
		emit_signal("player_moved", data.user_id, data.x, data.y)

func _handle_player_join(data):
	if data.has("user_id"):
		emit_signal("player_joined", data)

func _handle_player_leave(data):
	if data.has("user_id"):
		emit_signal("player_left", data.user_id)

func _handle_players_list(players_array):
	emit_signal("players_list_received", players_array)

func _handle_map_changed(data):
	if data.has("map_id") and data.has("spawn_x") and data.has("spawn_y"):
		var map_id = data.map_id
		var spawn_x = data.spawn_x
		var spawn_y = data.spawn_y
		print("[WebSocketManager] ✅ Confirmation de changement de map reçue: ", map_id, " à (", spawn_x, ", ", spawn_y, ")")
		emit_signal("map_changed", map_id, spawn_x, spawn_y)
	else:
		print("[WebSocketManager] ⚠️ Données de changement de map invalides: ", data)

func _handle_combat_started(data):
	"""Gère la réception des données initiales d'un combat."""
	print("[WebSocketManager] Combat reçu du serveur")
	emit_signal("combat_started", data)

func _handle_combat_update(data):
	"""Gère les mises à jour d'état du combat."""
	emit_signal("combat_update", data)

func _handle_combat_action_response(data):
	"""Gère les réponses aux actions de combat."""
	emit_signal("combat_action_response", data)

func _handle_combat_ended(data):
	"""Gère la fin d'un combat."""
	print("[WebSocketManager] Combat terminé")
	emit_signal("combat_ended", data)

func send_text(message: String):
	if ws != null and ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		ws.send_text(message)
		# Message envoyé
	else:
		var ws_state = str(ws.get_ready_state()) if ws != null else "null"
		print("[WebSocketManager] Erreur: Impossible d'envoyer le message, WebSocket non ouvert (état: ", ws_state, ")")
		emit_signal("connection_error", "WebSocket non connecté, impossible d'envoyer le message")

func send_player_move(x: float, y: float, map_id: String):
	"""Envoie la position du joueur au serveur"""
	var move_data = {
		"type": "player_move",
		"data": {
			"x": x,
			"y": y,
			"map_id": map_id
		}
	}
	
	var json_string = JSON.stringify(move_data)
	if ws != null and ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		ws.send_text(json_string)
		print("[WebSocketManager] Position envoyée: ", x, ", ", y)
	else:
		print("[WebSocketManager] Impossible d'envoyer la position, WebSocket non connecté")

func send_change_map_request(map_id: String):
	print("[WebSocketManager] DÉBUT DE send_change_map_request pour :", map_id)
	
	if ws != null and ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		# Créer un message JSON pour le changement de map
		var change_map_data = {
			"type": "change_map",
			"data": {
				"map_id": map_id
			}
		}
		
		var json_string = JSON.stringify(change_map_data)
		# Envoi du message changement de map
		ws.send_text(json_string)
		# Message changement de map envoyé
	else:
		var ws_state = str(ws.get_ready_state()) if ws != null else "null"
		print("[WebSocketManager] WebSocket non connecté (état: ", ws_state, ") - Ne peut pas envoyer.")
		emit_signal("connection_error", "WebSocket non connecté, impossible de changer de map")

func disconnect_from_server():
	print("[WebSocketManager] Déconnexion volontaire.")
	auth_token = ""
	if ws != null:
		ws.close()
	_is_connected = false

func get_current_user() -> String:
	return "N/A" # Doit maintenant être lu depuis le token

func is_user_connected() -> bool:
	return _is_connected

func _exit_tree():
	if ws != null:
		ws.close()

## GESTION DES MESSAGES DE PERSONNAGES
## ====================================

func _handle_characters_list(data):
	"""Gère la réception de la liste des personnages"""
	print("[WebSocketManager] Liste des personnages reçue")
	emit_signal("characters_list_received", data)

func _handle_character_selected(data):
	"""Gère la confirmation de sélection d'un personnage"""
	print("[WebSocketManager] Sélection de personnage confirmée")
	emit_signal("character_selected", data)

func _handle_character_created(data):
	"""Gère la confirmation de création d'un personnage"""
	print("[WebSocketManager] Création de personnage confirmée")
	emit_signal("character_created", data)

func _handle_character_deleted(data):
	"""Gère la confirmation de suppression d'un personnage"""
	print("[WebSocketManager] Suppression de personnage confirmée")
	emit_signal("character_deleted", data)

func _handle_error(data):
	"""Gère les messages d'erreur"""
	var error_message = data.get("error", "Erreur inconnue")
	print("[WebSocketManager] Erreur reçue: ", error_message)
	emit_signal("character_error", error_message)

## ENVOI DE MESSAGES DE PERSONNAGES
## =================================

func send_get_characters():
	"""Demande la liste des personnages"""
	var message = {
		"type": "get_characters",
		"data": {},
		"timestamp": Time.get_unix_time_from_system()
	}
	send_text(JSON.stringify(message))

func send_create_character(character_name: String, character_class: String):
	"""Envoie une demande de création de personnage"""
	var message = {
		"type": "create_character",
		"data": {
			"name": character_name,
			"class": character_class
		},
		"timestamp": Time.get_unix_time_from_system()
	}
	send_text(JSON.stringify(message))

func send_select_character(character_id: int):
	"""Envoie une demande de sélection de personnage"""
	var message = {
		"type": "select_character",
		"data": {
			"character_id": character_id
		},
		"timestamp": Time.get_unix_time_from_system()
	}
	send_text(JSON.stringify(message))

func send_delete_character(character_id: int):
	"""Envoie une demande de suppression de personnage"""
	var message = {
		"type": "delete_character",
		"data": {
			"character_id": character_id
		},
		"timestamp": Time.get_unix_time_from_system()
	}
	send_text(JSON.stringify(message))

## ENVOI DE MESSAGES DE COMBAT
## ============================

func send_combat_action(action_data: Dictionary):
	"""Envoie une action de combat au serveur"""
	var message = {
		"type": "combat_action",
		"data": action_data,
		"timestamp": Time.get_unix_time_from_system()
	}
	send_text(JSON.stringify(message))
	# Action de combat envoyée
 
