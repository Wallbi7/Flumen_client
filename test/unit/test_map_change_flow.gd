extends RefCounted
class_name TestMapChangeFlow

# Tests pour le flow de changement de carte Flumen MMORPG
var test_name = "TestMapChangeFlow"
var assertion_count = 0
var failed_assertions = []

func _init():
	print("=== Tests Map Change Flow ===")

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

func assert_false(value, message: String = ""):
	assertion_count += 1
	if value:
		var error_msg = "Expected false but got <%s>" % value
		if message != "":
			error_msg = message + " - " + error_msg
		failed_assertions.append(error_msg)
		print("❌ ASSERTION FAILED: ", error_msg)
		return false
	print("✅ ", message if message != "" else "Assertion passed")
	return true

func assert_not_null(value, message: String = ""):
	assertion_count += 1
	if value == null:
		var error_msg = "Expected non-null value but got null"
		if message != "":
			error_msg = message + " - " + error_msg
		failed_assertions.append(error_msg)
		print("❌ ASSERTION FAILED: ", error_msg)
		return false
	print("✅ ", message if message != "" else "Assertion passed")
	return true

# Test 1: Validation des transitions de carte
func test_map_transition_validation():
	print("\n🗺️ Test: Map Transition Validation")
	
	var valid_transitions = [
		{"from": Vector2i(0, 0), "to": Vector2i(1, 0), "direction": "right"},
		{"from": Vector2i(0, 0), "to": Vector2i(-1, 0), "direction": "left"},
		{"from": Vector2i(0, 0), "to": Vector2i(0, 1), "direction": "up"},
		{"from": Vector2i(0, 0), "to": Vector2i(0, -1), "direction": "down"}
	]
	
	for transition in valid_transitions:
		var is_valid = validate_map_transition(transition.from, transition.to)
		assert_true(is_valid, "Transition %s vers %s devrait être valide" % [transition.from, transition.to])
		
		var calculated_direction = calculate_transition_direction(transition.from, transition.to)
		assert_eq(calculated_direction, transition.direction, "Direction calculée devrait être %s" % transition.direction)

# Test 2: États de changement de carte
func test_map_change_states():
	print("\n📊 Test: Map Change States")
	
	var map_states = {"IDLE": 0, "REQUESTING": 1, "WAITING_SERVER": 2, "COMPLETED": 5}
	
	var current_state = map_states.IDLE
	assert_eq(current_state, 0, "État initial devrait être IDLE")
	
	current_state = map_states.REQUESTING
	assert_eq(current_state, 1, "État devrait passer à REQUESTING")
	
	current_state = map_states.COMPLETED
	assert_eq(current_state, 5, "État devrait passer à COMPLETED")

# Test 3: Calcul des positions de spawn
func test_spawn_position_calculation():
	print("\n📍 Test: Spawn Position Calculation")
	
	var map_dimensions = {"width": 1000, "height": 600}
	var spawn_margin = 50
	
	var spawn_tests = [
		{"direction": "right", "expected_x": spawn_margin},
		{"direction": "left", "expected_x": map_dimensions.width - spawn_margin},
		{"direction": "up", "expected_y": map_dimensions.height - spawn_margin},
		{"direction": "down", "expected_y": spawn_margin}
	]
	
	for test in spawn_tests:
		var spawn_pos = calculate_spawn_position(test.direction, map_dimensions, spawn_margin)
		
		if test.has("expected_x"):
			assert_eq(spawn_pos.x, test.expected_x, "Position X pour direction %s" % test.direction)
		if test.has("expected_y"):
			assert_eq(spawn_pos.y, test.expected_y, "Position Y pour direction %s" % test.direction)
		
		assert_true(spawn_pos.x >= 0 and spawn_pos.x <= map_dimensions.width, "Position X dans les limites")
		assert_true(spawn_pos.y >= 0 and spawn_pos.y <= map_dimensions.height, "Position Y dans les limites")

# Fonctions utilitaires
func validate_map_transition(from: Vector2i, to: Vector2i) -> bool:
	var diff = to - from
	var abs_diff = Vector2i(abs(diff.x), abs(diff.y))
	return (abs_diff.x == 1 and abs_diff.y == 0) or (abs_diff.x == 0 and abs_diff.y == 1)

func calculate_transition_direction(from: Vector2i, to: Vector2i) -> String:
	var diff = to - from
	
	if diff.x > 0:
		return "right"
	elif diff.x < 0:
		return "left"
	elif diff.y > 0:
		return "up"
	elif diff.y < 0:
		return "down"
	else:
		return "none"

func calculate_spawn_position(direction: String, map_dimensions: Dictionary, margin: int) -> Vector2:
	match direction:
		"right":
			return Vector2(margin, map_dimensions.height / 2)
		"left":
			return Vector2(map_dimensions.width - margin, map_dimensions.height / 2)
		"up":
			return Vector2(map_dimensions.width / 2, map_dimensions.height - margin)
		"down":
			return Vector2(map_dimensions.width / 2, margin)
		_:
			return Vector2(map_dimensions.width / 2, map_dimensions.height / 2)

func run_all_tests():
	print("🧪 Démarrage des tests Map Change Flow...")
	
	test_map_transition_validation()
	test_map_change_states()
	test_spawn_position_calculation()
	
	print("\n📊 === RÉSULTATS ===")
	print("Assertions: ", assertion_count)
	print("Échecs: ", failed_assertions.size())
	
	if failed_assertions.size() == 0:
		print("✅ Tous les tests Map Change Flow ont réussi!")
		return true
	else:
		print("❌ Tests Map Change Flow échoués:")
		for failure in failed_assertions:
			print("  - ", failure)
		return false
