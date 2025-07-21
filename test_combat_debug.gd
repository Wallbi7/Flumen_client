extends Node

## SCRIPT DE DEBUG POUR LE SYSTÈME DE COMBAT
## ===========================================
## Ce script permet de diagnostiquer pourquoi le combat ne se lance pas

func _ready():
	print("\n[CombatDebug] === DIAGNOSTIC SYSTÈME DE COMBAT ===")
	
	# Attendre que les systèmes soient initialisés
	await get_tree().create_timer(2.0).timeout
	
	run_diagnostic()

func run_diagnostic():
	print("\n[CombatDebug] 🔍 Démarrage du diagnostic...")
	
	# 1. Vérifier GameManager
	check_game_manager()
	
	# 2. Vérifier WebSocketManager  
	check_websocket_manager()
	
	# 3. Vérifier CombatManager
	check_combat_manager()
	
	# 4. Vérifier les monstres
	check_monsters()
	
	# 5. Test du flux de combat
	test_combat_flow()

func check_game_manager():
	print("\n[CombatDebug] 📋 Vérification GameManager...")
	
	var game_manager = get_node_or_null("/root/GameManager")
	if not game_manager:
		print("[CombatDebug] ❌ GameManager non trouvé")
		return
	
	print("[CombatDebug] ✅ GameManager trouvé")
	print("[CombatDebug] État actuel: ", game_manager.current_state)
	print("[CombatDebug] Map actuelle: ", game_manager.current_map_id)
	print("[CombatDebug] Joueur actuel: ", game_manager.current_player != null)
	print("[CombatDebug] Nombre de monstres: ", game_manager.monsters.size())

func check_websocket_manager():
	print("\n[CombatDebug] 🌐 Vérification WebSocketManager...")
	
	var main_scene = get_tree().current_scene
	var ws_manager = null
	
	if main_scene:
		ws_manager = main_scene.get_node_or_null("WebSocketManager")
	
	if not ws_manager:
		print("[CombatDebug] ❌ WebSocketManager non trouvé")
		return
	
	print("[CombatDebug] ✅ WebSocketManager trouvé")
	print("[CombatDebug] État connexion: ", ws_manager.is_connected if ws_manager.has_method("is_connected") else "Inconnu")
	
	# Vérifier les signaux
	check_websocket_signals(ws_manager)

func check_websocket_signals(ws_manager):
	print("\n[CombatDebug] 🔗 Vérification des signaux WebSocket...")
	
	var required_signals = [
		"combat_started",
		"combat_update", 
		"combat_ended",
		"combat_action_response"
	]
	
	for signal_name in required_signals:
		if ws_manager.has_signal(signal_name):
			print("[CombatDebug] ✅ Signal '", signal_name, "' disponible")
		else:
			print("[CombatDebug] ❌ Signal '", signal_name, "' MANQUANT")

func check_combat_manager():
	print("\n[CombatDebug] ⚔️ Vérification CombatManager...")
	
	var game_manager = get_node_or_null("/root/GameManager")
	if not game_manager:
		return
	
	var combat_manager = game_manager.combat_manager
	if not combat_manager:
		print("[CombatDebug] ❌ CombatManager non trouvé dans GameManager")
		return
	
	print("[CombatDebug] ✅ CombatManager trouvé")
	print("[CombatDebug] Combat actif: ", combat_manager.is_combat_active)
	print("[CombatDebug] Grille initialisée: ", combat_manager.combat_grid != null)
	print("[CombatDebug] UI initialisée: ", combat_manager.combat_ui != null)

func check_monsters():
	print("\n[CombatDebug] 👹 Vérification des monstres...")
	
	var game_manager = get_node_or_null("/root/GameManager")
	if not game_manager:
		return
	
	print("[CombatDebug] Monstres disponibles: ", game_manager.monsters.size())
	
	for monster_id in game_manager.monsters.keys():
		var monster = game_manager.monsters[monster_id]
		if monster and is_instance_valid(monster):
			print("[CombatDebug] - ", monster.monster_name, " (", monster_id, ") Position: ", monster.position)
			
			# Vérifier les signaux du monstre
			check_monster_signals(monster)
		else:
			print("[CombatDebug] - Monstre invalide: ", monster_id)

func check_monster_signals(monster):
	var signals_to_check = ["monster_clicked", "monster_right_clicked", "monster_hovered", "monster_died"]
	
	for signal_name in signals_to_check:
		if monster.has_signal(signal_name):
			print("[CombatDebug]   ✅ Signal '", signal_name, "' disponible")
		else:
			print("[CombatDebug]   ❌ Signal '", signal_name, "' MANQUANT")

func test_combat_flow():
	print("\n[CombatDebug] 🧪 Test du flux de combat...")
	
	var game_manager = get_node_or_null("/root/GameManager")
	if not game_manager:
		print("[CombatDebug] ❌ Impossible de tester - GameManager manquant")
		return
	
	# Simuler un clic sur monstre
	if game_manager.monsters.size() > 0:
		var first_monster_id = game_manager.monsters.keys()[0]
		var first_monster = game_manager.monsters[first_monster_id]
		
		print("[CombatDebug] 🎯 Test avec le monstre: ", first_monster.monster_name)
		print("[CombatDebug] ID du monstre: ", first_monster.monster_id)
		
		# Simuler l'envoi de initiate_combat
		simulate_combat_initiation(first_monster)
	else:
		print("[CombatDebug] ❌ Aucun monstre disponible pour le test")

func simulate_combat_initiation(monster):
	print("\n[CombatDebug] 🚀 Simulation de l'initiation de combat...")
	
	var game_manager = get_node_or_null("/root/GameManager")
	
	# Test 1: Envoyer le message WebSocket
	print("[CombatDebug] Test 1: Envoi du message initiate_combat")
	game_manager.send_websocket_message("initiate_combat", {
		"monster_id": monster.monster_id
	})
	
	# Test 2: Attendre une réponse pendant 5 secondes
	print("[CombatDebug] Test 2: Attente de la réponse combat_started (5 secondes)...")
	
	var ws_manager = get_tree().current_scene.get_node_or_null("WebSocketManager")
	if ws_manager and ws_manager.has_signal("combat_started"):
		# Connecter temporairement pour vérifier la réception
		ws_manager.combat_started.connect(_on_combat_started_received)
		
		await get_tree().create_timer(5.0).timeout
		
		# Déconnecter le signal temporaire
		if ws_manager.combat_started.is_connected(_on_combat_started_received):
			ws_manager.combat_started.disconnect(_on_combat_started_received)
		
		print("[CombatDebug] ⏰ Timeout - Aucune réponse reçue")
	else:
		print("[CombatDebug] ❌ Impossible de connecter au signal combat_started")

func _on_combat_started_received(combat_data):
	print("[CombatDebug] 🎉 RÉPONSE REÇUE ! combat_started avec données: ", combat_data)

func _input(event):
	# Raccourci clavier pour relancer le diagnostic
	if event is InputEventKey and event.pressed and event.keycode == KEY_D:
		print("\n[CombatDebug] 🔄 Relancement du diagnostic (touche D)")
		run_diagnostic()