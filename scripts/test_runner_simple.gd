extends SceneTree

# Script de lancement des tests pour Godot CLI - Version avec tests de bugs + gameplay

var test_directory = "res://test/"
var verbose = false
var exit_code = 0

func _init():
	print("🎮 FLUMEN MMORPG - Tests via Godot CLI")
	print("======================================")
	
	# Parser les arguments
	parse_arguments()
	
	# Lancer tous nos tests
	run_comprehensive_tests()
	
	# Quitter
	quit(exit_code)

func parse_arguments():
	var args = OS.get_cmdline_args()
	print("📋 Arguments reçus: ", args.size())
	
	for i in range(args.size()):
		var arg = args[i]
		if arg == "--test-dir" and i + 1 < args.size():
			test_directory = args[i + 1]
		elif arg == "--verbose":
			verbose = true
	
	print("📁 Répertoire de test: ", test_directory)

func run_comprehensive_tests():
	print("\n🧪 EXÉCUTION DES TESTS COMPLETS FLUMEN")
	print("=====================================")
	
	var total_tests = 0
	var passed_tests = 0
	var failed_tests = 0
	var all_results = []
	
	# 1. Tests de base (démonstration)
	print("\n📚 === TESTS DE BASE ===")
	var basic_result = run_basic_demo_tests()
	all_results.append(basic_result)
	total_tests += basic_result.total
	passed_tests += basic_result.passed
	failed_tests += basic_result.failed
	
	# 2. Tests de bugs WebSocket
	print("\n🌐 === TESTS BUGS WEBSOCKET ===")
	var websocket_result = run_websocket_bug_tests()
	all_results.append(websocket_result)
	total_tests += websocket_result.total
	passed_tests += websocket_result.passed
	failed_tests += websocket_result.failed
	
	# 3. Tests de bugs de transition de cartes
	print("\n🗺️ === TESTS BUGS MAP TRANSITION ===")
	var map_result = run_map_transition_bug_tests()
	all_results.append(map_result)
	total_tests += map_result.total
	passed_tests += map_result.passed
	failed_tests += map_result.failed
	
	# 4. Tests de bugs critiques
	print("\n🚨 === TESTS BUGS CRITIQUES ===")
	var critical_result = run_critical_bug_tests()
	all_results.append(critical_result)
	total_tests += critical_result.total
	passed_tests += critical_result.passed
	failed_tests += critical_result.failed
	
	# 5. Tests du système de test lui-même
	print("\n🔧 === TESTS WORKING SIMPLE ===")
	var working_result = run_working_simple_tests()
	all_results.append(working_result)
	total_tests += working_result.total
	passed_tests += working_result.passed
	failed_tests += working_result.failed
	
	# 6. NOUVEAUX TESTS - Authentification
	print("\n🔐 === TESTS AUTHENTIFICATION ===")
	var auth_result = run_authentication_tests()
	all_results.append(auth_result)
	total_tests += auth_result.total
	passed_tests += auth_result.passed
	failed_tests += auth_result.failed
	
	# 7. NOUVEAUX TESTS - Changement de carte
	print("\n🗺️ === TESTS CHANGEMENT DE CARTE ===")
	var map_change_result = run_map_change_tests()
	all_results.append(map_change_result)
	total_tests += map_change_result.total
	passed_tests += map_change_result.passed
	failed_tests += map_change_result.failed
	
	# 8. NOUVEAUX TESTS - Déplacement du joueur
	print("\n🎯 === TESTS DÉPLACEMENT JOUEUR ===")
	var movement_result = run_player_movement_tests()
	all_results.append(movement_result)
	total_tests += movement_result.total
	passed_tests += movement_result.passed
	failed_tests += movement_result.failed
	
	# Afficher les résultats finaux
	print_comprehensive_results(total_tests, passed_tests, failed_tests, all_results)
	
	# Définir le code de sortie
	if failed_tests == 0:
		exit_code = 0
	else:
		exit_code = 1

func run_basic_demo_tests() -> Dictionary:
	var total = 4
	var passed = 0
	var failed = 0
	
	# Test 1: Mathématiques de base
	if test_basic_math():
		print("  ✅ test_basic_math - PASSED")
		passed += 1
	else:
		print("  ❌ test_basic_math - FAILED")
		failed += 1
	
	# Test 2: Opérations sur les strings
	if test_string_operations():
		print("  ✅ test_string_operations - PASSED")
		passed += 1
	else:
		print("  ❌ test_string_operations - FAILED")
		failed += 1
	
	# Test 3: Coordonnées de carte
	if test_map_coordinates():
		print("  ✅ test_map_coordinates - PASSED")
		passed += 1
	else:
		print("  ❌ test_map_coordinates - FAILED")
		failed += 1
	
	# Test 4: Positions de spawn
	if test_spawn_positions():
		print("  ✅ test_spawn_positions - PASSED")
		passed += 1
	else:
		print("  ❌ test_spawn_positions - FAILED")
		failed += 1
	
	return {"name": "Basic Demo", "total": total, "passed": passed, "failed": failed}

func run_websocket_bug_tests() -> Dictionary:
	# Charger et exécuter les tests WebSocket
	var websocket_script = load("res://test/unit/test_websocket_bugs.gd")
	if websocket_script == null:
		print("❌ Impossible de charger test_websocket_bugs.gd")
		return {"name": "WebSocket Bugs", "total": 0, "passed": 0, "failed": 1}
	
	var websocket_test = websocket_script.new()
	var success = websocket_test.run_all_tests()
	
	return {
		"name": "WebSocket Bugs",
		"total": websocket_test.assertion_count,
		"passed": websocket_test.assertion_count - websocket_test.failed_assertions.size(),
		"failed": websocket_test.failed_assertions.size()
	}

func run_map_transition_bug_tests() -> Dictionary:
	# Charger et exécuter les tests de transition de cartes
	var map_script = load("res://test/unit/test_map_transition_bugs.gd")
	if map_script == null:
		print("❌ Impossible de charger test_map_transition_bugs.gd")
		return {"name": "Map Transition Bugs", "total": 0, "passed": 0, "failed": 1}
	
	var map_test = map_script.new()
	var success = map_test.run_all_tests()
	
	return {
		"name": "Map Transition Bugs",
		"total": map_test.assertion_count,
		"passed": map_test.assertion_count - map_test.failed_assertions.size(),
		"failed": map_test.failed_assertions.size()
	}

func run_critical_bug_tests() -> Dictionary:
	# Charger et exécuter les tests critiques
	var critical_script = load("res://test/unit/test_critical_bugs.gd")
	if critical_script == null:
		print("❌ Impossible de charger test_critical_bugs.gd")
		return {"name": "Critical Bugs", "total": 0, "passed": 0, "failed": 1}
	
	var critical_test = critical_script.new()
	var success = critical_test.run_all_tests()
	
	return {
		"name": "Critical Bugs",
		"total": critical_test.assertion_count,
		"passed": critical_test.assertion_count - critical_test.failed_assertions.size(),
		"failed": critical_test.failed_assertions.size()
	}

func run_working_simple_tests() -> Dictionary:
	# Charger et exécuter les tests working simple
	var working_script = load("res://test/unit/test_working_simple.gd")
	if working_script == null:
		print("❌ Impossible de charger test_working_simple.gd")
		return {"name": "Working Simple", "total": 0, "passed": 0, "failed": 1}
	
	var working_test = working_script.new()
	var success = working_test.run_all_tests()
	
	return {
		"name": "Working Simple",
		"total": working_test.assertion_count,
		"passed": working_test.assertion_count - working_test.failed_assertions.size(),
		"failed": working_test.failed_assertions.size()
	}

# NOUVEAUX TESTS - Authentification
func run_authentication_tests() -> Dictionary:
	var auth_script = load("res://test/unit/test_authentication_flow.gd")
	if auth_script == null:
		print("❌ Impossible de charger test_authentication_flow.gd")
		return {"name": "Authentication Flow", "total": 0, "passed": 0, "failed": 1}
	
	var auth_test = auth_script.new()
	var success = auth_test.run_all_tests()
	
	return {
		"name": "Authentication Flow",
		"total": auth_test.assertion_count,
		"passed": auth_test.assertion_count - auth_test.failed_assertions.size(),
		"failed": auth_test.failed_assertions.size()
	}

# NOUVEAUX TESTS - Changement de carte
func run_map_change_tests() -> Dictionary:
	var map_change_script = load("res://test/unit/test_map_change_flow.gd")
	if map_change_script == null:
		print("❌ Impossible de charger test_map_change_flow.gd")
		return {"name": "Map Change Flow", "total": 0, "passed": 0, "failed": 1}
	
	var map_change_test = map_change_script.new()
	var success = map_change_test.run_all_tests()
	
	return {
		"name": "Map Change Flow",
		"total": map_change_test.assertion_count,
		"passed": map_change_test.assertion_count - map_change_test.failed_assertions.size(),
		"failed": map_change_test.failed_assertions.size()
	}

# NOUVEAUX TESTS - Déplacement du joueur
func run_player_movement_tests() -> Dictionary:
	var movement_script = load("res://test/unit/test_player_movement.gd")
	if movement_script == null:
		print("❌ Impossible de charger test_player_movement.gd")
		return {"name": "Player Movement", "total": 0, "passed": 0, "failed": 1}
	
	var movement_test = movement_script.new()
	var success = movement_test.run_all_tests()
	
	return {
		"name": "Player Movement",
		"total": movement_test.assertion_count,
		"passed": movement_test.assertion_count - movement_test.failed_assertions.size(),
		"failed": movement_test.failed_assertions.size()
	}

# Tests de base (gardés pour compatibilité)
func test_basic_math() -> bool:
	if 1 + 1 != 2: return false
	if 5 * 3 != 15: return false
	if 10 - 4 != 6: return false
	return true

func test_string_operations() -> bool:
	var test_string = "Flumen MMORPG"
	if not "Flumen" in test_string: return false
	if not "MMORPG" in test_string: return false
	if "WoW" in test_string: return false
	return true

func test_map_coordinates() -> bool:
	var origin = Vector2i(0, 0)
	var right = Vector2i(1, 0)
	var left = Vector2i(-1, 0)
	
	if origin + Vector2i(1, 0) != right: return false
	if origin + Vector2i(-1, 0) != left: return false
	
	var coord_str = "%d_%d" % [right.x, right.y]
	if coord_str != "1_0": return false
	
	return true

func test_spawn_positions() -> bool:
	var map_width = 1000
	var map_height = 600
	
	var spawn_left = Vector2(100, map_height / 2)
	var spawn_right = Vector2(map_width - 100, map_height / 2)
	
	if spawn_left.x >= map_width / 2: return false
	if spawn_right.x <= map_width / 2: return false
	
	return true

func print_comprehensive_results(total: int, passed: int, failed: int, results: Array):
	print("\n" + "=".repeat(50))
	print("📊 RÉSULTATS FINAUX COMPLETS")
	print("=".repeat(50))
	
	# Résumé par catégorie
	for result in results:
		var status = "✅" if result.failed == 0 else "❌"
		var rate = 0.0
		if result.total > 0:
			rate = (float(result.passed) / float(result.total)) * 100.0
		
		print("%s %s: %d/%d (%.1f%%)" % [status, result.name, result.passed, result.total, rate])
	
	print("-".repeat(50))
	print("📈 TOTAL GÉNÉRAL:")
	print("   Tests: %d" % total)
	print("   Réussis: %d" % passed)
	print("   Échoués: %d" % failed)
	
	var success_rate = 0.0
	if total > 0:
		success_rate = (float(passed) / float(total)) * 100.0
	
	print("   Taux de réussite: %.2f%%" % success_rate)
	
	if failed == 0:
		print("\n🎉 TOUS LES TESTS ONT RÉUSSI!")
		print("   Le système Flumen est stable et sans régressions!")
	else:
		print("\n⚠️ %d TEST(S) ONT ÉCHOUÉ" % failed)
		print("   Vérifiez les logs ci-dessus pour les détails")
	
	print("=".repeat(50)) 