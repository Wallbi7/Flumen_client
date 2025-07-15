extends Node
class_name CombatTest

## SYSTÈME DE TEST POUR LE COMBAT TACTIQUE
## ========================================
## Cette classe fournit des outils de test et de démonstration pour le système de combat.
## Elle permet de tester rapidement différents scénarios et de valider les fonctionnalités.
##
## FONCTIONNALITÉS:
## - Scénarios de test prédéfinis
## - Tests automatisés avec validation
## - Benchmarks de performance
## - Outils de debug interactifs

# ================================
# RÉFÉRENCES ET VARIABLES
# ================================

## Référence au gestionnaire de combat
var combat_manager: CombatManager = null

## Scénarios de test disponibles
var test_scenarios: Dictionary = {}

## Mode automatique de test
var auto_test_mode: bool = false
var auto_test_delay: float = 2.0

## Statistiques de test
var test_stats: Dictionary = {
	"tests_run": 0,
	"tests_passed": 0,
	"tests_failed": 0,
	"average_init_time": 0.0,
	"average_turn_time": 0.0
}

# ================================
# SIGNAUX
# ================================

## Émis quand un test commence
signal test_started(scenario_name: String)

## Émis quand un test se termine
signal test_completed(scenario_name: String, success: bool, details: Dictionary)

## Émis quand tous les tests automatiques sont terminés
signal auto_test_finished(results: Dictionary)

# ================================
# INITIALISATION
# ================================

func _ready():
	print("[CombatTest] === INITIALISATION DU SYSTÈME DE TEST ===")
	
	# Définir les scénarios de test
	_setup_test_scenarios()
	
	# Connecter les signaux d'entrée
	_setup_input_handlers()
	
	print("[CombatTest] ✅ Système de test prêt")
	print("[CombatTest] 💡 Utilisez F1-F9 pour lancer les tests")

## Configure les scénarios de test
func _setup_test_scenarios():
	test_scenarios = {
		"basic_1v1": {
			"name": "Combat 1v1 Basique",
			"description": "Un joueur contre un monstre simple",
			"allies": [
				{
					"id": "player_1",
					"name": "Héros",
					"stats": {
						"health": 100,
						"initiative": 15,
						"action_points": 6,
						"movement_points": 3
					}
				}
			],
			"enemies": [
				{
					"id": "monster_1",
					"name": "Bouftou",
					"stats": {
						"health": 80,
						"initiative": 12,
						"action_points": 4,
						"movement_points": 2
					}
				}
			]
		},
		
		"balanced_2v2": {
			"name": "Combat 2v2 Équilibré",
			"description": "Deux joueurs contre deux monstres",
			"allies": [
				{
					"id": "player_1",
					"name": "Guerrier",
					"stats": {
						"health": 120,
						"initiative": 12,
						"action_points": 6,
						"movement_points": 3
					}
				},
				{
					"id": "player_2",
					"name": "Mage",
					"stats": {
						"health": 80,
						"initiative": 18,
						"action_points": 8,
						"movement_points": 2
					}
				}
			],
			"enemies": [
				{
					"id": "monster_1",
					"name": "Bouftou Chef",
					"stats": {
						"health": 100,
						"initiative": 14,
						"action_points": 5,
						"movement_points": 3
					}
				},
				{
					"id": "monster_2",
					"name": "Larve Bleue",
					"stats": {
						"health": 60,
						"initiative": 20,
						"action_points": 6,
						"movement_points": 4
					}
				}
			]
		},
		
		"boss_fight": {
			"name": "Combat de Boss 3v1",
			"description": "Trois joueurs contre un boss puissant",
			"allies": [
				{
					"id": "player_1",
					"name": "Tank",
					"stats": {
						"health": 150,
						"initiative": 10,
						"action_points": 5,
						"movement_points": 2
					}
				},
				{
					"id": "player_2",
					"name": "DPS",
					"stats": {
						"health": 90,
						"initiative": 16,
						"action_points": 7,
						"movement_points": 3
					}
				},
				{
					"id": "player_3",
					"name": "Support",
					"stats": {
						"health": 70,
						"initiative": 14,
						"action_points": 8,
						"movement_points": 3
					}
				}
			],
			"enemies": [
				{
					"id": "boss_1",
					"name": "Dragon Doré",
					"stats": {
						"health": 300,
						"initiative": 18,
						"action_points": 10,
						"movement_points": 4
					}
				}
			]
		}
	}
	
	print("[CombatTest] ✅ ", test_scenarios.size(), " scénarios de test configurés")

## Configure les gestionnaires d'entrée
func _setup_input_handlers():
	# Les inputs seront gérés dans _input()
	pass

# ================================
# GESTION DES ENTRÉES
# ================================

func _input(event):
	if not event.pressed:
		return
	
	# Tests de combat avec des touches non utilisées
	if event is InputEventKey:
		var ctrl_pressed = event.ctrl_pressed
		
		match event.keycode:
			KEY_1:
				if ctrl_pressed:
					run_test_scenario("basic_1v1")
			KEY_2:
				if ctrl_pressed:
					run_test_scenario("balanced_2v2")
			KEY_3:
				if ctrl_pressed:
					run_test_scenario("boss_fight")
			KEY_B:
				if ctrl_pressed:
					run_performance_benchmark()
			KEY_T:
				if ctrl_pressed:
					run_all_tests()
			KEY_A:
				if ctrl_pressed:
					toggle_auto_test_mode()
			KEY_C:
				if not ctrl_pressed:  # C seul pour Combat simple
					run_test_scenario("basic_1v1")
			KEY_H:
				if not ctrl_pressed:  # H seul pour aide
					show_test_help()

# ================================
# EXÉCUTION DES TESTS
# ================================

## Initialise le gestionnaire de combat pour les tests
func setup_combat_manager():
	if combat_manager:
		return
	
	print("[CombatTest] 🔧 Initialisation du gestionnaire de combat pour test...")
	
	# Créer le gestionnaire de combat
	combat_manager = CombatManager.new()
	combat_manager.name = "TestCombatManager"
	add_child(combat_manager)
	
	# Initialiser tous les systèmes
	combat_manager.initialize_combat_systems()
	
	# Connecter les signaux pour le monitoring
	combat_manager.combat_started.connect(_on_test_combat_started)
	combat_manager.combat_ended.connect(_on_test_combat_ended)
	
	print("[CombatTest] ✅ Gestionnaire de combat initialisé pour test")

## Lance un scénario de test spécifique
func run_test_scenario(scenario_name: String):
	if not test_scenarios.has(scenario_name):
		print("[CombatTest] ❌ Scénario inconnu: ", scenario_name)
		return
	
	setup_combat_manager()
	
	var scenario = test_scenarios[scenario_name]
	print("[CombatTest] 🧪 Lancement du test: ", scenario.name)
	print("[CombatTest] 📝 Description: ", scenario.description)
	
	var start_time = Time.get_ticks_msec()
	test_started.emit(scenario_name)
	
	# Lancer le combat avec les données du scénario
	combat_manager.start_combat("map_1_0", scenario.allies, scenario.enemies)
	
	# Placement automatique pour les tests
	await get_tree().create_timer(0.5).timeout
	combat_manager.auto_place_all_fighters()
	
	# Démarrer la phase de combat
	await get_tree().create_timer(0.5).timeout
	combat_manager.turn_manager.start_combat()
	
	var init_time = Time.get_ticks_msec() - start_time
	
	# Enregistrer les statistiques
	test_stats.tests_run += 1
	test_stats.average_init_time = (test_stats.average_init_time + init_time) / test_stats.tests_run
	
	print("[CombatTest] ⏱️ Temps d'initialisation: ", init_time, "ms")

## Lance tous les tests automatiquement
func run_all_tests():
	print("[CombatTest] 🔄 Lancement de tous les tests...")
	
	auto_test_mode = true
	var test_names = test_scenarios.keys()
	
	for i in range(test_names.size()):
		var scenario_name = test_names[i]
		print("[CombatTest] 📋 Test ", i + 1, "/", test_names.size(), ": ", scenario_name)
		
		run_test_scenario(scenario_name)
		
		# Attendre entre les tests
		if i < test_names.size() - 1:
			await get_tree().create_timer(auto_test_delay).timeout
	
	auto_test_mode = false
	auto_test_finished.emit(test_stats)
	print("[CombatTest] ✅ Tous les tests terminés")

## Active/désactive le mode de test automatique
func toggle_auto_test_mode():
	auto_test_mode = !auto_test_mode
	print("[CombatTest] 🤖 Mode automatique: ", "ACTIVÉ" if auto_test_mode else "DÉSACTIVÉ")

# ================================
# TESTS DE PERFORMANCE
# ================================

## Test de performance général
func run_performance_benchmark():
	print("[CombatTest] ⚡ Démarrage du benchmark de performance...")
	
	setup_combat_manager()
	
	var iterations = 10
	var total_time = 0
	
	for i in range(iterations):
		var start_time = Time.get_ticks_msec()
		
		# Test d'initialisation de combat
		var allies = test_scenarios["balanced_2v2"].allies
		var enemies = test_scenarios["balanced_2v2"].enemies
		
		combat_manager.start_combat("map_1_0", allies, enemies)
		combat_manager.auto_place_all_fighters()
		
		var end_time = Time.get_ticks_msec()
		total_time += (end_time - start_time)
		
		# Nettoyer pour le prochain test
		if combat_manager.turn_manager:
			combat_manager.turn_manager.reset_for_new_combat()
		
		await get_tree().create_timer(0.1).timeout
	
	var average_time = float(total_time) / iterations
	print("[CombatTest] 📊 Résultats du benchmark:")
	print("  - Itérations: ", iterations)
	print("  - Temps total: ", total_time, "ms")
	print("  - Temps moyen: ", "%.2f" % average_time, "ms")
	var performance_rating = "À AMÉLIORER"
	if average_time < 50:
		performance_rating = "EXCELLENTE"
	elif average_time < 100:
		performance_rating = "BONNE"
	print("  - Performance: ", performance_rating)

## Test de performance du pathfinding
func test_pathfinding_performance():
	print("[CombatTest] 🛤️ Test de performance du pathfinding...")
	
	setup_combat_manager()
	
	if not combat_manager.pathfinding:
		print("[CombatTest] ❌ Pathfinding non disponible")
		return
	
	# Lancer le test de performance intégré
	combat_manager.pathfinding.debug_performance_test(100)

## Test de génération de grille
func test_grid_generation():
	print("[CombatTest] 🏗️ Test de génération de grille...")
	
	setup_combat_manager()
	
	if not combat_manager.combat_grid:
		print("[CombatTest] ❌ Grille de combat non disponible")
		return
	
	var start_time = Time.get_ticks_msec()
	
	# Tester différentes configurations de map
	var test_maps = ["map_0_0", "map_1_0", "map_0_1", "map_0_-1"]
	
	for map_id in test_maps:
		combat_manager._setup_grid_for_map(map_id)
		await get_tree().create_timer(0.1).timeout
	
	var end_time = Time.get_ticks_msec()
	var total_time = end_time - start_time
	
	print("[CombatTest] ✅ Test de grille terminé:")
	print("  - Maps testées: ", test_maps.size())
	print("  - Temps total: ", total_time, "ms")
	print("  - Temps par map: ", "%.2f" % (float(total_time) / test_maps.size()), "ms")

# ================================
# TESTS DE VALIDATION
# ================================

## Valide l'intégrité du système de combat
func validate_combat_system() -> bool:
	print("[CombatTest] 🔍 Validation de l'intégrité du système...")
	
	setup_combat_manager()
	
	var validation_passed = true
	var issues: Array[String] = []
	
	# Vérifier les composants principaux
	if not combat_manager.combat_grid:
		issues.append("CombatGrid manquant")
		validation_passed = false
	
	if not combat_manager.pathfinding:
		issues.append("CombatPathfinding manquant")
		validation_passed = false
	
	if not combat_manager.turn_manager:
		issues.append("CombatTurnManager manquant")
		validation_passed = false
	
	if not combat_manager.combat_ui:
		issues.append("CombatUI manquant")
		validation_passed = false
	
	# Tester une initialisation basique
	if validation_passed:
		var allies = [{"id": "test_ally", "name": "Test", "stats": {}}]
		var enemies = [{"id": "test_enemy", "name": "Test", "stats": {}}]
		# Test d'initialisation de combat (sans try/catch car n'existe pas en GDScript)
		combat_manager.start_combat("map_1_0", allies, enemies)
	
	# Afficher les résultats
	if validation_passed:
		print("[CombatTest] ✅ Validation réussie - Système intègre")
	else:
		print("[CombatTest] ❌ Validation échouée - Problèmes détectés:")
		for issue in issues:
			print("  - ", issue)
	
	return validation_passed

## Teste la cohérence des données de combat
func test_data_consistency():
	print("[CombatTest] 📊 Test de cohérence des données...")
	
	setup_combat_manager()
	
	# Lancer un combat de test
	var scenario = test_scenarios["basic_1v1"]
	combat_manager.start_combat("map_1_0", scenario.allies, scenario.enemies)
	combat_manager.auto_place_all_fighters()
	
	await get_tree().create_timer(0.5).timeout
	
	# Vérifier la cohérence
	var stats = combat_manager.get_combat_stats()
	var issues: Array[String] = []
	
	if stats.total_fighters != 2:
		issues.append("Nombre de combattants incorrect: " + str(stats.total_fighters))
	
	if stats.ally_count != 1:
		issues.append("Nombre d'alliés incorrect: " + str(stats.ally_count))
	
	if stats.enemy_count != 1:
		issues.append("Nombre d'ennemis incorrect: " + str(stats.enemy_count))
	
	if issues.is_empty():
		print("[CombatTest] ✅ Cohérence des données validée")
	else:
		print("[CombatTest] ❌ Problèmes de cohérence détectés:")
		for issue in issues:
			print("  - ", issue)

# ================================
# GESTIONNAIRES D'ÉVÉNEMENTS
# ================================

## Appelé quand un combat de test commence
func _on_test_combat_started():
	print("[CombatTest] ⚔️ Combat de test démarré")

## Appelé quand un combat de test se termine
func _on_test_combat_ended(winning_team: CombatTurnManager.Team):
	print("[CombatTest] 🏁 Combat de test terminé - Gagnant: ", CombatTurnManager.Team.keys()[winning_team])
	
	test_stats.tests_passed += 1
	
	# Si en mode automatique, passer au test suivant
	if auto_test_mode:
		await get_tree().create_timer(auto_test_delay).timeout

# ================================
# UTILITAIRES D'AIDE
# ================================

## Affiche l'aide pour les tests
func show_test_help():
	print("[CombatTest] === AIDE DES TESTS DE COMBAT ===")
	print("Raccourcis clavier disponibles:")
	print("  C - Test 1v1 basique (rapide)")
	print("  H - Afficher cette aide")
	print("")
	print("Avec Ctrl enfoncé:")
	print("  Ctrl+1 - Test 1v1 basique")
	print("  Ctrl+2 - Test 2v2 équilibré")
	print("  Ctrl+3 - Test boss 3v1")
	print("  Ctrl+B - Benchmark de performance")
	print("  Ctrl+T - Lancer tous les tests")
	print("  Ctrl+A - Basculer mode automatique")
	print("")
	print("Scénarios disponibles:")
	for key in test_scenarios.keys():
		var scenario = test_scenarios[key]
		print("  - ", key, ": ", scenario.name)
		print("    ", scenario.description)
	print("==========================================")

## Affiche les statistiques de test
func show_test_statistics():
	print("[CombatTest] === STATISTIQUES DE TEST ===")
	print("Tests exécutés: ", test_stats.tests_run)
	print("Tests réussis: ", test_stats.tests_passed)
	print("Tests échoués: ", test_stats.tests_failed)
	print("Temps d'init moyen: ", "%.2f" % test_stats.average_init_time, "ms")
	print("Temps de tour moyen: ", "%.2f" % test_stats.average_turn_time, "ms")
	print("Taux de réussite: ", "%.1f" % (float(test_stats.tests_passed) / test_stats.tests_run * 100), "%")
	print("======================================")

## Crée un scénario de test personnalisé
func create_custom_scenario(name: String, allies: Array, enemies: Array, description: String = ""):
	test_scenarios[name] = {
		"name": name,
		"description": description,
		"allies": allies,
		"enemies": enemies
	}
	
	print("[CombatTest] ✅ Scénario personnalisé créé: ", name)

## Réinitialise les statistiques de test
func reset_test_statistics():
	test_stats = {
		"tests_run": 0,
		"tests_passed": 0,
		"tests_failed": 0,
		"average_init_time": 0.0,
		"average_turn_time": 0.0
	}
	
	print("[CombatTest] 🔄 Statistiques de test réinitialisées")

# ================================
# TESTS SPÉCIALISÉS
# ================================

## Teste le système de placement automatique
func test_auto_placement():
	print("[CombatTest] 📍 Test du placement automatique...")
	
	setup_combat_manager()
	
	var scenario = test_scenarios["balanced_2v2"]
	combat_manager.start_combat("map_1_0", scenario.allies, scenario.enemies)
	
	# Tester le placement
	var start_time = Time.get_ticks_msec()
	combat_manager.auto_place_all_fighters()
	var end_time = Time.get_ticks_msec()
	
	# Vérifier que tous les combattants sont placés
	var placed_count = combat_manager.placed_fighters.size()
	var total_fighters = scenario.allies.size() + scenario.enemies.size()
	
	if placed_count == total_fighters:
		print("[CombatTest] ✅ Placement automatique réussi (", end_time - start_time, "ms)")
	else:
		print("[CombatTest] ❌ Placement automatique échoué: ", placed_count, "/", total_fighters, " placés")

## Teste les transitions de phase
func test_phase_transitions():
	print("[CombatTest] 🔄 Test des transitions de phase...")
	
	setup_combat_manager()
	
	var scenario = test_scenarios["basic_1v1"]
	combat_manager.start_combat("map_1_0", scenario.allies, scenario.enemies)
	
	# Vérifier la phase initiale
	if combat_manager.turn_manager.current_phase == CombatTurnManager.CombatPhase.PLACEMENT:
		print("[CombatTest] ✅ Phase initiale correcte: PLACEMENT")
	else:
		print("[CombatTest] ❌ Phase initiale incorrecte")
		return
	
	# Passer à la phase de combat
	combat_manager.auto_place_all_fighters()
	combat_manager.turn_manager.start_combat()
	
	await get_tree().create_timer(0.1).timeout
	
	if combat_manager.turn_manager.current_phase == CombatTurnManager.CombatPhase.COMBAT:
		print("[CombatTest] ✅ Transition vers COMBAT réussie")
	else:
		print("[CombatTest] ❌ Transition vers COMBAT échouée")

# ================================
# DEBUG ET MONITORING
# ================================

## Active le mode debug pour tous les systèmes
func enable_debug_mode():
	print("[CombatTest] 🐛 Activation du mode debug...")
	
	setup_combat_manager()
	
	# Afficher les informations de debug de tous les systèmes
	if combat_manager.combat_grid:
		combat_manager.combat_grid.debug_print_grid_info()
	
	if combat_manager.pathfinding:
		combat_manager.pathfinding.debug_print_performance_stats()
	
	if combat_manager.turn_manager:
		combat_manager.turn_manager.debug_print_combat_state()
	
	if combat_manager.combat_ui:
		combat_manager.combat_ui.debug_print_ui_state()

## Génère un rapport de test complet
func generate_test_report() -> Dictionary:
	var report = {
		"timestamp": Time.get_datetime_string_from_system(),
		"statistics": test_stats.duplicate(),
		"scenarios_available": test_scenarios.keys(),
		"system_validation": validate_combat_system(),
		"performance_data": {}
	}
	
	print("[CombatTest] 📋 Rapport de test généré")
	return report 