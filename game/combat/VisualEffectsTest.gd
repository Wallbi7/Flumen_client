extends Node2D

## SCRIPT DE TEST POUR LES EFFETS VISUELS DE COMBAT
## =================================================
## Permet de tester rapidement tous les effets visuels sans serveur

var visual_effects_manager: VisualEffectsManager
var combat_grid: CombatGrid

func _ready():
	print("[VisualEffectsTest] 🧪 Test des effets visuels initialisé")
	
	# Créer une grille de test simple
	setup_test_grid()
	
	# Créer le gestionnaire d'effets
	setup_visual_effects()
	
	print("[VisualEffectsTest] ✅ Appuyez sur les touches 1-6 pour tester les effets")
	print("1 - Sort de base  |  2 - Dégâts  |  3 - Soins")
	print("4 - Poison        |  5 - Boost PA |  6 - Réduction PM")

func setup_test_grid():
	"""Crée une grille simplifiée pour les tests."""
	combat_grid = CombatGrid.new()
	add_child(combat_grid)
	
	# Position au centre de l'écran
	var screen_center = get_viewport().get_visible_rect().size / 2
	combat_grid.position = screen_center - Vector2(400, 300)

func setup_visual_effects():
	"""Crée et configure le gestionnaire d'effets visuels."""
	visual_effects_manager = VisualEffectsManager.new()
	add_child(visual_effects_manager)
	
	# Configurer la référence à la grille
	visual_effects_manager.setup_grid_reference(combat_grid)

func _input(event):
	if not event.is_pressed():
		return
	
	# Positions de test
	var caster_pos = Vector2(5, 5)
	var target_pos = Vector2(8, 8)
	
	match event.keycode:
		KEY_1:
			test_spell_effect(caster_pos, target_pos)
		KEY_2:
			test_damage_effect(target_pos, 45)
		KEY_3:
			test_heal_effect(target_pos, 28)
		KEY_4:
			test_poison_effect(target_pos)
		KEY_5:
			test_boost_pa_effect(caster_pos)
		KEY_6:
			test_reduce_pm_effect(target_pos)
		KEY_ESCAPE:
			get_tree().quit()

func test_spell_effect(caster_pos: Vector2, target_pos: Vector2):
	"""Test de l'effet visuel d'un sort."""
	visual_effects_manager.play_spell_cast_effect(caster_pos, target_pos, "Épée Céleste")
	print("[Test] ✨ Effet sort lancé")

func test_damage_effect(position: Vector2, damage: int):
	"""Test de l'affichage de dégâts."""
	visual_effects_manager.show_damage_text(position, damage, "damage")
	print("[Test] 💥 Dégâts affichés: %s" % damage)

func test_heal_effect(position: Vector2, heal: int):
	"""Test de l'affichage de soins."""
	visual_effects_manager.show_damage_text(position, heal, "heal")
	print("[Test] 💚 Soins affichés: %s" % heal)

func test_poison_effect(position: Vector2):
	"""Test de l'affichage d'un effet de poison."""
	var poison_effect = CombatState.TemporaryEffect.new()
	poison_effect.id = "test_poison"
	poison_effect.type = CombatState.EffectType.POISON
	poison_effect.value = 15
	poison_effect.duration = 3
	poison_effect.description = "Poison (3 tours)"
	
	visual_effects_manager.show_temporary_effect(position, poison_effect)
	print("[Test] 🐍 Effet poison affiché")

func test_boost_pa_effect(position: Vector2):
	"""Test de l'affichage d'un boost de PA."""
	var boost_effect = CombatState.TemporaryEffect.new()
	boost_effect.id = "test_boost_pa"
	boost_effect.type = CombatState.EffectType.BOOST_PA
	boost_effect.value = 2
	boost_effect.duration = 4
	boost_effect.description = "Boost PA +2 (4 tours)"
	
	visual_effects_manager.show_temporary_effect(position, boost_effect)
	print("[Test] ⚡ Boost PA affiché")

func test_reduce_pm_effect(position: Vector2):
	"""Test de l'affichage d'une réduction de PM."""
	var reduce_effect = CombatState.TemporaryEffect.new()
	reduce_effect.id = "test_reduce_pm"
	reduce_effect.type = CombatState.EffectType.REDUCE_PM
	reduce_effect.value = 1
	reduce_effect.duration = 2
	reduce_effect.description = "Entrave -1 PM (2 tours)"
	
	visual_effects_manager.show_temporary_effect(position, reduce_effect)
	print("[Test] 🔒 Réduction PM affichée") 