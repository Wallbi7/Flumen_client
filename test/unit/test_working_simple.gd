extends RefCounted
class_name TestWorkingSimple

# Test simple qui fonctionne sans dépendances GUT
# Ce test peut être chargé par Godot sans erreurs

var test_name = "TestWorkingSimple"
var assertion_count = 0
var failed_assertions = []

func _init():
	print("Initialisation du test: ", test_name)

# Assertions de base
func assert_eq(actual, expected, message: String = ""):
	assertion_count += 1
	if actual != expected:
		var error_msg = "Expected <%s> but got <%s>" % [expected, actual]
		if message != "":
			error_msg = message + " - " + error_msg
		failed_assertions.append(error_msg)
		print("ASSERTION FAILED: ", error_msg)
		return false
	return true

func assert_true(value, message: String = ""):
	assertion_count += 1
	if not value:
		var error_msg = "Expected true but got <%s>" % value
		if message != "":
			error_msg = message + " - " + error_msg
		failed_assertions.append(error_msg)
		print("ASSERTION FAILED: ", error_msg)
		return false
	return true

func assert_false(value, message: String = ""):
	assertion_count += 1
	if value:
		var error_msg = "Expected false but got <%s>" % value
		if message != "":
			error_msg = message + " - " + error_msg
		failed_assertions.append(error_msg)
		print("ASSERTION FAILED: ", error_msg)
		return false
	return true

# Tests concrets
func test_basic_math():
	print("Running test_basic_math...")
	assert_eq(1 + 1, 2, "Basic addition")
	assert_eq(5 * 3, 15, "Basic multiplication")
	assert_true(10 > 5, "Comparison")

func test_string_operations():
	print("Running test_string_operations...")
	var test_string = "Flumen MMORPG"
	assert_true("Flumen" in test_string, "String contains Flumen")
	assert_true("MMORPG" in test_string, "String contains MMORPG")
	assert_false("WoW" in test_string, "String does not contain WoW")

func test_vector_math():
	print("Running test_vector_math...")
	var vec1 = Vector2(10, 20)
	var vec2 = Vector2(10, 20)
	assert_eq(vec1, vec2, "Vectors should be equal")
	assert_eq(vec1.x, 10, "Vector X component")
	assert_eq(vec1.y, 20, "Vector Y component")

func test_coordinate_system():
	print("Running test_coordinate_system...")
	var origin = Vector2i(0, 0)
	var right = Vector2i(1, 0)
	var up = Vector2i(0, 1)
	
	assert_eq(origin + Vector2i(1, 0), right, "Move right")
	assert_eq(origin + Vector2i(0, 1), up, "Move up")
	
	# Test de génération de nom de carte
	var map_name = "map_%d_%d" % [right.x, right.y]
	assert_eq(map_name, "map_1_0", "Map name generation")

func run_all_tests():
	print("=== Démarrage des tests ===")
	
	test_basic_math()
	test_string_operations()
	test_vector_math()
	test_coordinate_system()
	
	print("=== Résultats ===")
	print("Assertions: ", assertion_count)
	print("Échecs: ", failed_assertions.size())
	
	if failed_assertions.size() == 0:
		print("✅ Tous les tests ont réussi!")
		return true
	else:
		print("❌ Tests échoués:")
		for failure in failed_assertions:
			print("  - ", failure)
		return false 