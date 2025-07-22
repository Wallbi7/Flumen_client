extends Node

## SCRIPT DE DEBUG POUR LES CLICS DE COMBAT
## ==========================================
## Ce script aide à diagnostiquer pourquoi les clics droit ne lancent pas le combat

var debug_active = false

func _ready():
	print("\n[CombatClickDebug] === ACTIVÉ ===")
	print("[CombatClickDebug] Appuyez sur F1 pour activer/désactiver le debug")
	print("[CombatClickDebug] Appuyez sur F2 pour tester le combat manuellement")

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F1:
				debug_active = !debug_active
				print("[CombatClickDebug] Debug ", "ACTIVÉ" if debug_active else "DÉSACTIVÉ")
				
			KEY_F2:
				test_manual_combat()
				
			KEY_F3:
				check_monster_interactions()

func test_manual_combat():
	print("\n[CombatClickDebug] 🚨 TEST MANUEL DÉSACTIVÉ - Utiliser un vrai clic droit sur un monstre")
	print("[CombatClickDebug] ⚠️ Pour un test approprié, cliquez droit sur un monstre dans le jeu")
	return
	
	# Code commenté pour éviter l'interférence avec le serveur
	# var game_manager = get_node_or_null("/root/GameManager")
	# if not game_manager:
	#	print("[CombatClickDebug] ❌ GameManager non trouvé")
	#	return

func check_monster_interactions():
	print("\n[CombatClickDebug] 🔍 VÉRIFICATION INTERACTIONS MONSTRES")
	
	var game_manager = get_node_or_null("/root/GameManager")
	if not game_manager:
		print("[CombatClickDebug] ❌ GameManager non trouvé")
		return
	
	print("[CombatClickDebug] Nombre de monstres: ", game_manager.monsters.size())
	
	for monster_id in game_manager.monsters.keys():
		var monster = game_manager.monsters[monster_id]
		if not monster or not is_instance_valid(monster):
			print("[CombatClickDebug] ❌ Monstre invalide: ", monster_id)
			continue
			
		print("\n[CombatClickDebug] 👹 Monstre: ", monster.monster_name)
		print("[CombatClickDebug]   - Position: ", monster.global_position)
		print("[CombatClickDebug]   - Visible: ", monster.visible)
		print("[CombatClickDebug]   - ID: ", monster.monster_id)
		
		# Vérifier Area2D
		var area = monster.get_node_or_null("Area2D")
		if area:
			print("[CombatClickDebug]   - Area2D: ✅")
			print("[CombatClickDebug]   - input_pickable: ", area.input_pickable)
			print("[CombatClickDebug]   - monitoring: ", area.monitoring)
			print("[CombatClickDebug]   - priority: ", area.priority)
			
			# Vérifier CollisionShape2D
			var collision = area.get_node_or_null("CollisionShape2D")
			if collision:
				print("[CombatClickDebug]   - CollisionShape2D: ✅")
				print("[CombatClickDebug]   - disabled: ", collision.disabled)
				print("[CombatClickDebug]   - shape: ", collision.shape)
			else:
				print("[CombatClickDebug]   - CollisionShape2D: ❌")
		else:
			print("[CombatClickDebug]   - Area2D: ❌")
		
		# Vérifier les signaux
		check_monster_signals(monster)

func check_monster_signals(monster):
	print("[CombatClickDebug]   - Signaux:")
	
	var required_signals = ["monster_clicked", "monster_right_clicked", "monster_hovered"]
	for signal_name in required_signals:
		if monster.has_signal(signal_name):
			var connections = monster.get_signal_connection_list(signal_name)
			print("[CombatClickDebug]     * ", signal_name, ": ✅ (", connections.size(), " connexions)")
			
			for connection in connections:
				print("[CombatClickDebug]       -> ", connection.callable.get_object().name, ".", connection.callable.get_method())
		else:
			print("[CombatClickDebug]     * ", signal_name, ": ❌")

func _on_monster_clicked_debug(monster):
	if debug_active:
		print("[CombatClickDebug] 🖱️ CLIC GAUCHE détecté sur: ", monster.monster_name)

func _on_monster_right_clicked_debug(monster):
	if debug_active:
		print("[CombatClickDebug] 🖱️ CLIC DROIT détecté sur: ", monster.monster_name)

func _on_monster_hovered_debug(monster, is_hovered):
	if debug_active:
		print("[CombatClickDebug] 👁️ SURVOL ", "DÉBUT" if is_hovered else "FIN", " sur: ", monster.monster_name)

# Connecter automatiquement aux monstres existants
func connect_to_existing_monsters():
	var game_manager = get_node_or_null("/root/GameManager")
	if not game_manager:
		return
	
	for monster_id in game_manager.monsters.keys():
		var monster = game_manager.monsters[monster_id]
		if monster and is_instance_valid(monster):
			# Connecter nos handlers de debug
			if monster.has_signal("monster_clicked") and not monster.monster_clicked.is_connected(_on_monster_clicked_debug):
				monster.monster_clicked.connect(_on_monster_clicked_debug)
			
			if monster.has_signal("monster_right_clicked") and not monster.monster_right_clicked.is_connected(_on_monster_right_clicked_debug):
				monster.monster_right_clicked.connect(_on_monster_right_clicked_debug)
			
			if monster.has_signal("monster_hovered") and not monster.monster_hovered.is_connected(_on_monster_hovered_debug):
				monster.monster_hovered.connect(_on_monster_hovered_debug)

# Connecter après un délai pour laisser les monstres se charger
func _enter_tree():
	call_deferred("_delayed_connect")

func _delayed_connect():
	await get_tree().create_timer(3.0).timeout
	connect_to_existing_monsters()
	print("[CombatClickDebug] ✅ Connecté aux monstres existants")