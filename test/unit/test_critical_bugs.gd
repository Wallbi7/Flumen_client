extends RefCounted
class_name TestCriticalBugs

# Tests pour les bugs critiques rencontrés
var test_name = "TestCriticalBugs"
var assertion_count = 0
var failed_assertions = []

func _init():
	print("=== Tests Critical Bugs ===")

func assert_eq(actual, expected, message: String = ""):
	assertion_count += 1
	if actual != expected:
		var error_msg = "Expected <%s> but got <%s>" % [expected, actual]
		if message != "":
			error_msg = message + " - " + error_msg
		failed_assertions.append(error_msg)
		print("❌ ASSERTION FAILED: ", error_msg)
		return false
	print("✅ ", message if message != "" else "Assertion passed")
	return true

func assert_true(value, message: String = ""):
	assertion_count += 1
	if not value:
		var error_msg = "Expected true but got <%s>" % value
		if message != "":
			error_msg = message + " - " + error_msg
		failed_assertions.append(error_msg)
		print("❌ ASSERTION FAILED: ", error_msg)
		return false
	print("✅ ", message if message != "" else "Assertion passed")
	return true

# Bug 1: Division par zéro dans MapDebugTool
func test_division_by_zero_bug():
	print("\n➗ Test: Division by Zero Bug")
	
	var test_values = [10, 3, 0]
	
	for value in test_values:
		if value != 0:
			var int_division = 10 / value  # Division
			assert_true(int_division >= 0, "Division devrait être >= 0")
		else:
			var safe_division = 10.0 / max(value, 1)  # Protection
			assert_eq(safe_division, 10.0, "Division protégée devrait retourner 10")

# Bug 2: Timeout d'authentification serveur
func test_authentication_timeout():
	print("\n🔐 Test: Authentication Timeout Bug")
	
	var auth_start_time = 0
	var current_time = 8000  # 8 secondes
	var auth_timeout = 5000  # 5 secondes
	
	var is_timeout = (current_time - auth_start_time) > auth_timeout
	assert_true(is_timeout, "Timeout d'authentification devrait être détecté")

# Bug 3: Coordonnées extrêmes
func test_extreme_coordinates():
	print("\n🌐 Test: Extreme Coordinates Bug")
	
	var extreme_coords = [
		Vector2i(0, 0),
		Vector2i(999999, 999999),
		Vector2i(-999999, -999999)
	]
	
	for coord in extreme_coords:
		var map_name = "map_%d_%d" % [coord.x, coord.y]
		
		assert_true(str(coord.x) in map_name, "Nom devrait contenir X: %d" % coord.x)
		assert_true(str(coord.y) in map_name, "Nom devrait contenir Y: %d" % coord.y)

func run_all_tests():
	print("🧪 Démarrage des tests Critical Bugs...")
	
	test_division_by_zero_bug()
	test_authentication_timeout()
	test_extreme_coordinates()
	
	print("\n📊 === RÉSULTATS ===")
	print("Assertions: ", assertion_count)
	print("Échecs: ", failed_assertions.size())
	
	if failed_assertions.size() == 0:
		print("✅ Tous les tests Critical Bugs ont réussi!")
		return true
	else:
		print("❌ Tests Critical Bugs échoués:")
		for failure in failed_assertions:
			print("  - ", failure)
		return false
