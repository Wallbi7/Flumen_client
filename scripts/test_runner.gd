extends SceneTree

# Script de lancement des tests pour Godot CLI
# Utilisé par le script PowerShell run_tests.ps1

var test_directory = "res://test/"
var verbose = false
var exit_code = 0

func _init():
	# Parser les arguments de la ligne de commande
	parse_arguments()
	
	# Lancer les tests
	run_all_tests()
	
	# Quitter avec le code approprié
	quit(exit_code)

func parse_arguments():
	var args = OS.get_cmdline_args()
	var found_separator = false
	
	for i in range(args.size()):
		var arg = args[i]
		
		# Chercher le séparateur "--"
		if arg == "--":
			found_separator = true
			continue
		
		# Traiter les arguments après le séparateur
		if found_separator:
			if arg == "--test-dir" and i + 1 < args.size():
				test_directory = args[i + 1]
			elif arg == "--verbose":
				verbose = true
	
	if verbose:
		print("GUT CLI: Test directory = ", test_directory)
		print("GUT CLI: Verbose mode = ", verbose)

func run_all_tests():
	print("🎮 FLUMEN MMORPG - Tests via Godot CLI")
	print("======================================")
	
	# Lancer les tests directement sans GUT pour le moment
	var results = run_simple_tests()
	
	# Afficher les résultats finaux
	print_final_results(results)
	
	# Définir le code de sortie
	if results.failed > 0:
		exit_code = 1
	else:
		exit_code = 0

func run_simple_tests() -> Dictionary:
	print("🔍 Recherche des fichiers de test...")
	
	var test_files = find_test_files(test_directory)
	var total_tests = 0
	var passed_tests = 0
	var failed_tests = 0
	var test_results = []
	
	print("📁 Fichiers de test trouvés: ", test_files.size())
	
	for test_file in test_files:
		print("🧪 Chargement: ", test_file)
		
		var script = load(test_file)
		if script == null:
			print("❌ Impossible de charger: ", test_file)
			failed_tests += 1
			continue
		
		# Créer une instance du test
		var test_instance = script.new()
		if test_instance == null:
			print("❌ Impossible de créer une instance: ", test_file)
			failed_tests += 1
			continue
		
		# Exécuter les tests
		var suite_result = run_test_suite(test_instance, test_file)
		test_results.append(suite_result)
		
		total_tests += suite_result.total
		passed_tests += suite_result.passed
		failed_tests += suite_result.failed
		
		# Nettoyer
		test_instance.queue_free()
	
	return {
		"total": total_tests,
		"passed": passed_tests,
		"failed": failed_tests,
		"suites": test_results
	}

func find_test_files(directory: String) -> Array:
	var files = []
	
	# Si c'est un fichier spécifique, le retourner directement
	if directory.ends_with(".gd"):
		files.append(directory)
		return files
	
	# Sinon, chercher tous les fichiers test_*.gd
	var dir = DirAccess.open(directory)
	if dir == null:
		print("❌ Impossible d'ouvrir le répertoire: ", directory)
		return files
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.begins_with("test_") and file_name.ends_with(".gd"):
			files.append(directory + "/" + file_name)
		file_name = dir.get_next()
	
	return files

func run_test_suite(test_instance: Object, suite_name: String) -> Dictionary:
	print("🏃 Exécution: ", suite_name)
	
	var test_methods = get_test_methods(test_instance)
	var suite_result = {
		"name": suite_name,
		"total": test_methods.size(),
		"passed": 0,
		"failed": 0,
		"tests": []
	}
	
	# Setup
	if test_instance.has_method("before_each"):
		test_instance.before_each()
	
	# Exécuter chaque test
	for method_name in test_methods:
		var test_result = run_single_test(test_instance, method_name)
		suite_result.tests.append(test_result)
		
		if test_result.passed:
			suite_result.passed += 1
			print("  ✅ ", method_name)
		else:
			suite_result.failed += 1
			print("  ❌ ", method_name, ": ", test_result.message)
	
	# Teardown
	if test_instance.has_method("after_each"):
		test_instance.after_each()
	
	return suite_result

func get_test_methods(test_instance: Object) -> Array:
	var methods = []
	for method in test_instance.get_method_list():
		if method.name.begins_with("test_"):
			methods.append(method.name)
	return methods

func run_single_test(test_instance: Object, method_name: String) -> Dictionary:
	var test_result = {
		"name": method_name,
		"passed": false,
		"message": ""
	}
	
	# Réinitialiser les assertions
	if test_instance.has_method("_reset_assertions"):
		test_instance._reset_assertions()
	
	# Exécuter le test
	test_instance.call(method_name)
	
	# Vérifier s'il y a eu des échecs
	if test_instance.has_method("_has_failures"):
		if test_instance._has_failures():
			test_result.passed = false
			var failures = test_instance._get_failed_assertions()
			test_result.message = failures[0] if failures.size() > 0 else "Test failed"
		else:
			test_result.passed = true
			test_result.message = "Test passed"
	else:
		test_result.passed = true
		test_result.message = "Test completed"
	
	return test_result

func _on_test_suite_finished(suite_name: String, results: Dictionary):
	if verbose:
		print("📁 Suite terminée: ", suite_name)
		print("   - Total: ", results.total)
		print("   - Réussis: ", results.passed)
		print("   - Échoués: ", results.failed)
		
		# Afficher les détails des tests échoués
		if results.failed > 0:
			print("   ❌ Tests échoués:")
			for test in results.tests:
				if not test.passed:
					print("      - ", test.name, ": ", test.message)

func print_final_results(results: Dictionary):
	print("\n📊 RÉSULTATS FINAUX")
	print("==================")
	print("Total: ", results.total)
	print("Passed: ", results.passed)
	print("Failed: ", results.failed)
	
	if results.failed == 0:
		print("✅ Tous les tests ont réussi!")
	else:
		print("❌ ", results.failed, " test(s) ont échoué")
		
		# Afficher les détails des échecs
		print("\n🔍 DÉTAILS DES ÉCHECS:")
		for suite in results.suites:
			if suite.failed > 0:
				print("📁 ", suite.name, " (", suite.failed, " échec(s))")
				for test in suite.tests:
					if not test.passed:
						print("   ❌ ", test.name, ": ", test.message)
	
	var success_rate = 0.0
	if results.total > 0:
		success_rate = (float(results.passed) / float(results.total)) * 100.0
	
	print("📈 Taux de réussite: ", "%.2f" % success_rate, "%")
	print("==================")

func has_node(path: String) -> bool:
	# Vérifier si un nœud existe
	return false  # Simplifié pour éviter les erreurs 