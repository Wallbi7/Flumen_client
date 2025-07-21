extends Node
## Script de test manuel pour le système de placement style Dofus

# ================================
# TEST MANUEL DU SYSTÈME DE PLACEMENT
# ================================

func _ready():
	print("=== TEST PLACEMENT STYLE DOFUS ===")
	print("Appuyez sur ESPACE pour lancer le test de placement")
	print("Appuyez sur G pour afficher/masquer la grille")
	print("Appuyez sur ESCAPE pour retourner au jeu principal")
	
	# Attendre un peu puis afficher la grille par défaut
	await get_tree().create_timer(0.5).timeout
	show_grid_immediately()

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:
				test_placement_system()
			KEY_G:
				toggle_grid_visibility()
			KEY_ESCAPE:
				get_tree().change_scene_to_file("res://game/main.tscn")

func test_placement_system():
	print("[TEST] 🧪 Lancement du test de placement style Dofus...")
	
	# Obtenir le gestionnaire de combat
	var game_manager = get_node_or_null("/root/GameManager")
	if not game_manager or not game_manager.combat_manager:
		print("[TEST] ❌ Gestionnaire de combat non trouvé")
		return
	
	var combat_manager = game_manager.combat_manager
	
	# Afficher explicitement la grille de combat
	if combat_manager.combat_grid:
		combat_manager.combat_grid.show_grid()
		print("[TEST] ✅ Grille de combat affichée")
		
		# Forcer la création des zones de placement style Dofus
		combat_manager.combat_grid._create_default_dofus_placement_zones()
		print("[TEST] ✅ Zones de placement Dofus créées")
	
	# Démarrer un combat simple 1v1
	var allies = [{
		"id": "test_player",
		"name": "Joueur Test",
		"stats": {
			"health": 100,
			"initiative": 15,
			"action_points": 6,
			"movement_points": 3
		}
	}]
	
	var enemies = [{
		"id": "test_monster", 
		"name": "Monstre Test",
		"stats": {
			"health": 80,
			"initiative": 12,
			"action_points": 4,
			"movement_points": 2
		}
	}]
	
	print("[TEST] 🎯 Création du combat de test...")
	combat_manager.start_combat("test_map", allies, enemies)
	
	# Attendre un peu puis afficher la grille à nouveau
	await get_tree().create_timer(0.1).timeout
	if combat_manager.combat_grid:
		combat_manager.combat_grid.show_grid()
	
	# Ne pas placer automatiquement pour tester le placement manuel
	print("[TEST] ✅ Combat créé - Testez maintenant le placement manuel!")
	print("[TEST] 💡 Cliquez sur les zones bleues pour placer votre personnage")
	print("[TEST] 🎨 Grille isométrique 17x15 visible avec zones de placement style Dofus")

func show_grid_immediately():
	"""Affiche la grille immédiatement pour les tests"""
	var game_manager = get_node_or_null("/root/GameManager")
	if not game_manager or not game_manager.combat_manager:
		print("[TEST] ❌ Impossible d'afficher la grille - gestionnaire non trouvé")
		return
	
	var combat_manager = game_manager.combat_manager
	if combat_manager.combat_grid:
		combat_manager.combat_grid.show_grid()
		# Créer les zones par défaut pour voir la grille en action
		combat_manager.combat_grid._create_default_dofus_placement_zones()
		print("[TEST] 🎨 Grille de combat visible avec zones Dofus par défaut")
		print("[TEST] 💡 Zones bleues (alliés) à gauche, zones rouges (ennemis) à droite")

func toggle_grid_visibility():
	"""Bascule la visibilité de la grille"""
	var game_manager = get_node_or_null("/root/GameManager")
	if not game_manager or not game_manager.combat_manager:
		return
	
	var combat_manager = game_manager.combat_manager
	if combat_manager.combat_grid:
		if combat_manager.combat_grid.visible:
			combat_manager.combat_grid.hide_grid()
			print("[TEST] 🙈 Grille masquée")
		else:
			combat_manager.combat_grid.show_grid()
			combat_manager.combat_grid._create_default_dofus_placement_zones()
			print("[TEST] 👁️ Grille affichée avec zones de placement")