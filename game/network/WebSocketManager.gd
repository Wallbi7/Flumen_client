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

func _ready():
	print("[WebSocketManager] _ready() appelé.")
	# Utiliser l'URL depuis la configuration
	url = ServerConfig.websocket_url
	print("[WebSocketManager] Using WebSocket URL: ", url)
	# Ne pas se connecter automatiquement, attendre l'authentification

func connect_with_auth(token: String):
	auth_token = token
	_connect_to_server()

func _connect_to_server():
	if auth_token == "":
		print("[WebSocketManager] Pas de token d'authentification, connexion annulée")
		emit_signal("connection_error", "Pas de token d'authentification")
		return
	
	print("[WebSocketManager] Tentative de connexion WebSocket...")
	
	var full_url = url + "?token=" + auth_token
	print("[WebSocketManager] Connexion à l'URL: ", full_url)
	print("[WebSocketManager] Token (premiers 20 chars): ", auth_token.substr(0, 20), "...")
	
	# Dans Godot 4, connect_to_url ne prend que l'URL
	var err = ws.connect_to_url(full_url)
	
	if err != OK:
		print("[WebSocketManager] Erreur de connexion au WebSocket :", err)
		emit_signal("connection_error", "Erreur de connexion: " + str(err))
	else:
		print("[WebSocketManager] connect_to_url() appelé avec succès, attente de la connexion...")

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
			else: # La connexion n'a jamais été établie
				var now := Time.get_ticks_msec()
				if now - _last_error_log_time > 1000:
					print("[WebSocketManager] Connexion WebSocket échouée, code: ", code, ", raison: ", reason)
					_last_error_log_time = now
					emit_signal("connection_error", "Échec de la connexion WebSocket (code: %s)" % str(code))

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
	print("[WebSocketManager] ✅ Ordre de démarrage de combat reçu du serveur.")
	emit_signal("combat_started", data)

func send_text(message: String):
	if ws != null and ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		ws.send_text(message)
		print("[WebSocketManager] Message envoyé: ", message)
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
		print("[WebSocketManager] Envoi du message changement de map: ", json_string)
		ws.send_text(json_string)
		print("[WebSocketManager] Message CHANGE_MAP envoyé au serveur")
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

func send_message(message: String):
	"""Envoie un message générique au serveur"""
	if ws != null and ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		ws.send_text(message)
		print("[WebSocketManager] Message envoyé: ", message)
	else:
		var ws_state = str(ws.get_ready_state()) if ws != null else "null"
		print("[WebSocketManager] Erreur: Impossible d'envoyer le message, WebSocket non ouvert (état: ", ws_state, ")")
		emit_signal("connection_error", "WebSocket non connecté, impossible d'envoyer le message")

func send_get_characters():
	"""Demande la liste des personnages"""
	var message = {
		"type": "get_characters",
		"data": {},
		"timestamp": Time.get_unix_time_from_system()
	}
	send_message(JSON.stringify(message))

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
	send_message(JSON.stringify(message))

func send_select_character(character_id: int):
	"""Envoie une demande de sélection de personnage"""
	var message = {
		"type": "select_character",
		"data": {
			"character_id": character_id
		},
		"timestamp": Time.get_unix_time_from_system()
	}
	send_message(JSON.stringify(message))

func send_delete_character(character_id: int):
	"""Envoie une demande de suppression de personnage"""
	var message = {
		"type": "delete_character",
		"data": {
			"character_id": character_id
		},
		"timestamp": Time.get_unix_time_from_system()
	}
	send_message(JSON.stringify(message))
 
