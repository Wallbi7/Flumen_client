extends Node

## Script simple pour tester le combat automatiquement au lieu de l'interface utilisateur

func _ready():
	print("[TestCombat] === TEST COMBAT AUTOMATIQUE ===")
	print("[TestCombat] Forcer le démarrage sans interface utilisateur")
	
	# Attendre un peu puis forcer le démarrage du jeu
	await get_tree().create_timer(2.0).timeout
	force_game_start()

func force_game_start():
	"""Forcer le démarrage du jeu sans passer par les interfaces"""
	print("[TestCombat] 🚀 Forcer le démarrage du jeu...")
	
	var game_manager = get_node_or_null("/root/GameManager")
	if not game_manager:
		print("[TestCombat] ❌ GameManager non trouvé")
		return
	
	# Simuler les données de personnage nécessaires
	var fake_character_data = {
		"id": "test-character-123",
		"name": "TestWarrior", 
		"class": "warrior",
		"pos_x": 758.0,
		"pos_y": 605.0
	}
	
	print("[TestCombat] 📋 Configuration du personnage de test...")
	
	# Simuler l'authentification réussie
	print("[TestCombat] ✅ Test de connexion au serveur...")
	await test_websocket_connection()

func test_websocket_connection():
	"""Tester la connexion WebSocket directement"""
	print("[TestCombat] 🌐 Test de connexion WebSocket...")
	
	var game_manager = get_node_or_null("/root/GameManager")
	if not game_manager:
		print("[TestCombat] ❌ GameManager non trouvé")
		return
		
	# Forcer la connexion WebSocket 
	print("[TestCombat] 📞 Tentative de connexion WebSocket...")
	game_manager.connect_to_game_server()
	
	# Attendre que la connexion s'établisse
	await get_tree().create_timer(5.0).timeout
	
	# Vérifier le statut de connexion
	check_connection_status()

func check_connection_status():
	"""Vérifier si la connexion WebSocket est établie"""
	print("[TestCombat] 🔍 Vérification du statut de connexion...")
	
	var main_scene = get_tree().current_scene
	if not main_scene:
		print("[TestCombat] ❌ Scène principale non trouvée")
		return
		
	var ws_manager = main_scene.get_node_or_null("WebSocketManager")
	if not ws_manager:
		print("[TestCombat] ❌ WebSocketManager non trouvé dans la scène")
		return
		
	print("[TestCombat] ✅ WebSocketManager trouvé")
	
	# Vérifier si connecté
	if ws_manager.has_method("is_connected"):
		var is_connected = ws_manager.is_connected()
		print("[TestCombat] 📡 Statut connexion: ", is_connected)
		
		if is_connected:
			print("[TestCombat] ✅ Connexion établie ! Test du combat...")
			await test_combat_initiation()
		else:
			print("[TestCombat] ❌ Connexion échouée - Vérification des logs serveur nécessaire")
			debug_connection_failure()
	else:
		print("[TestCombat] ⚠️ Impossible de vérifier le statut de connexion")

func debug_connection_failure():
	"""Debug en cas d'échec de connexion"""
	print("[TestCombat] 🔧 DEBUG: Analyse de l'échec de connexion...")
	
	print("[TestCombat] 💡 Vérifications suggérées:")
	print("[TestCombat] 1. Le serveur est-il démarré sur le port 9091 ?")
	print("[TestCombat] 2. Le WebSocket écoute-t-il sur /ws/game ?")
	print("[TestCombat] 3. Y a-t-il des erreurs de token JWT ?")
	print("[TestCombat] 4. Le serveur accepte-t-il les connexions WebSocket ?")
	
	# Essayer de pinguer le serveur HTTP d'abord
	test_http_connection()

func test_http_connection():
	"""Tester la connexion HTTP basique"""
	print("[TestCombat] 🌐 Test de connexion HTTP au serveur...")
	
	var http = HTTPRequest.new()
	add_child(http)
	
	# Test basique de l'API
	var error = http.request("http://127.0.0.1:9091/api/v1/health")
	if error == OK:
		print("[TestCombat] ✅ Requête HTTP envoyée")
	else:
		print("[TestCombat] ❌ Échec de la requête HTTP: ", error)

func test_combat_initiation():
	print("[TestCombat] 🚀 Démarrage du test de combat...")
	
	var game_manager = get_node_or_null("/root/GameManager")
	if not game_manager:
		print("[TestCombat] ❌ GameManager non trouvé")
		return
		
	print("[TestCombat] ✅ GameManager trouvé")
	print("[TestCombat] État actuel: ", game_manager.current_state)
	print("[TestCombat] Monstres disponibles: ", game_manager.monsters.size())
	
	# Essayer de lancer un combat avec le premier monstre
	if game_manager.monsters.size() > 0:
		var monster_id = game_manager.monsters.keys()[0]
		var monster = game_manager.monsters[monster_id]
		
		print("[TestCombat] 🎯 Test avec monstre: ", monster.monster_name, " (", monster_id, ")")
		print("[TestCombat] Position monstre: ", monster.global_position)
		
		# Placer le joueur près du monstre
		if game_manager.current_player:
			game_manager.current_player.global_position = monster.global_position + Vector2(50, 0)
			print("[TestCombat] 📍 Joueur positionné près du monstre")
		
		# Lancer le combat
		print("[TestCombat] 📤 Envoi de la requête de combat...")
		game_manager.send_websocket_message("initiate_combat", {
			"monster_id": monster.monster_id
		})
		
		# Attendre la réponse
		await wait_for_combat_response()
	else:
		print("[TestCombat] ❌ Aucun monstre disponible pour le test")

func wait_for_combat_response():
	print("[TestCombat] ⏳ Attente de la réponse combat_started (10 secondes max)...")
	
	var ws_manager = get_tree().current_scene.get_node_or_null("WebSocketManager")
	if not ws_manager:
		print("[TestCombat] ❌ WebSocketManager non trouvé")
		return
		
	if not ws_manager.has_signal("combat_started"):
		print("[TestCombat] ❌ Signal combat_started non disponible")
		return
	
	# Connecter temporairement au signal
	ws_manager.combat_started.connect(_on_combat_response_received)
	
	# Attendre 10 secondes maximum
	await get_tree().create_timer(10.0).timeout
	
	# Déconnecter le signal
	if ws_manager.combat_started.is_connected(_on_combat_response_received):
		ws_manager.combat_started.disconnect(_on_combat_response_received)
		
	print("[TestCombat] ⏰ Timeout - Test terminé")

func _on_combat_response_received(combat_data):
	print("[TestCombat] 🎉 ✅ SUCCÈS ! Réponse combat_started reçue !")
	print("[TestCombat] 📋 Données reçues: ", combat_data)
	
	# Analyser les données
	if combat_data is Dictionary:
		print("[TestCombat] 🔍 ID Combat: ", combat_data.get("id", "N/A"))
		print("[TestCombat] 🔍 Status: ", combat_data.get("status", "N/A"))
		print("[TestCombat] 🔍 Combattants: ", combat_data.get("combatants", []).size() if combat_data.has("combatants") else 0)