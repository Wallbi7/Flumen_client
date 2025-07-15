extends Node2D
class_name VisualEffectsManager

## GESTIONNAIRE D'EFFETS VISUELS POUR LE COMBAT
## =============================================
## Gère l'affichage des effets de sorts, buffs/debuffs, et animations de combat.
## Système modulaire et performant pour effets visuels temps réel.

# ================================
# CONSTANTES DE CONFIGURATION
# ================================

## Durées d'animation par défaut
const SPELL_ANIMATION_DURATION = 0.8
const DAMAGE_TEXT_DURATION = 1.5
const EFFECT_ICON_DURATION = 0.5
const PARTICLE_LIFETIME = 2.0

## Couleurs pour les différents types d'effets
const EFFECT_COLORS = {
	CombatState.EffectType.POISON: Color.GREEN,
	CombatState.EffectType.BOOST_PA: Color.ORANGE,
	CombatState.EffectType.BOOST_PM: Color.CYAN,
	CombatState.EffectType.BOOST_DAMAGE: Color.RED,
	CombatState.EffectType.REDUCE_PA: Color.DARK_BLUE,
	CombatState.EffectType.REDUCE_PM: Color.PURPLE
}

## Tailles de particules selon le type
const PARTICLE_SIZES = {
	"spell_cast": 8.0,
	"damage": 12.0,
	"heal": 10.0,
	"effect": 6.0
}

# ================================
# VARIABLES D'ÉTAT
# ================================

## Pool d'objets pour optimisation mémoire
var damage_text_pool: Array[Label] = []
var effect_icon_pool: Array[TextureRect] = []
var particle_pool: Array[Node2D] = []

## Effets actuellement actifs
var active_animations: Array[Tween] = []
var active_particles: Array[Node2D] = []

## Référence à la grille de combat pour positionnement
var combat_grid: CombatGrid = null

# ================================
# SIGNAUX
# ================================

## Signal émis quand un effet visuel démarre
signal visual_effect_started(position: Vector2, type: String)

## Signal émis quand une animation d'effet se termine
signal animation_completed(effect_type: String)



# ================================
# MÉTHODES D'INITIALISATION
# ================================

func _ready():
	print("[VisualEffectsManager] 🎨 Système d'effets visuels initialisé")
	_initialize_pools()

func setup_grid_reference(grid: CombatGrid):
	"""Configure la référence à la grille de combat pour le positionnement."""
	combat_grid = grid
	print("[VisualEffectsManager] 🗺️ Référence grille configurée")

func _initialize_pools():
	"""Pré-alloue des objets dans les pools pour optimiser les performances."""
	# Pool de textes de dégâts
	for i in range(10):
		var label = Label.new()
		label.add_theme_font_size_override("font_size", 24)
		label.z_index = 1000
		label.visible = false
		add_child(label)
		damage_text_pool.append(label)
	
	# Pool d'icônes d'effets
	for i in range(15):
		var icon = TextureRect.new()
		icon.custom_minimum_size = Vector2(32, 32)
		icon.z_index = 900
		icon.visible = false
		add_child(icon)
		effect_icon_pool.append(icon)
	
	# Pool de particules
	for i in range(20):
		var particle = Node2D.new()
		particle.z_index = 950
		particle.visible = false
		add_child(particle)
		particle_pool.append(particle)

# ================================
# EFFETS DE SORTS
# ================================

func play_spell_cast_effect(caster_pos: Vector2, target_pos: Vector2, spell_name: String):
	"""Affiche l'effet visuel d'un sort lancé."""
	if not combat_grid:
		print("[VisualEffectsManager] ⚠️ Grille non configurée pour effet sort")
		return
	
	var world_caster_pos = combat_grid.grid_to_world_position(caster_pos)
	var world_target_pos = combat_grid.grid_to_world_position(target_pos)
	
	# Particules du lanceur vers la cible
	_create_spell_trail(world_caster_pos, world_target_pos, spell_name)
	
	# Effet d'impact à la cible
	_create_impact_effect(world_target_pos, spell_name)
	
	visual_effect_started.emit(world_target_pos, "spell_cast")
	print("[VisualEffectsManager] ✨ Effet sort '%s' lancé" % spell_name)

func _create_spell_trail(start_pos: Vector2, end_pos: Vector2, _spell_name: String):
	"""Crée une traînée de particules du lanceur vers la cible."""
	var particle = _get_particle_from_pool()
	if not particle:
		return
		
	particle.position = start_pos
	particle.visible = true
	
	# Animation du projectile
	var tween = create_tween()
	active_animations.append(tween)
	
	tween.tween_method(_update_trail_particle.bind(particle, start_pos, end_pos), 0.0, 1.0, SPELL_ANIMATION_DURATION)
	tween.tween_callback(_return_particle_to_pool.bind(particle))

func _update_trail_particle(particle: Node2D, start_pos: Vector2, end_pos: Vector2, progress: float):
	"""Met à jour la position d'une particule de traînée de sort."""
	if not is_instance_valid(particle):
		return
		
	particle.position = start_pos.lerp(end_pos, progress)
	
	# Effet de fade out progressif
	particle.modulate.a = 1.0 - (progress * 0.3)

func _create_impact_effect(impact_pos: Vector2, _spell_name: String):
	"""Crée un effet d'impact au point de destination du sort."""
	var particle = _get_particle_from_pool()
	if not particle:
		return
		
	particle.position = impact_pos
	particle.visible = true
	particle.modulate = Color.WHITE
	
	# Animation d'explosion
	var tween = create_tween()
	active_animations.append(tween)
	
	tween.parallel().tween_property(particle, "scale", Vector2(2.0, 2.0), 0.3)
	tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.5)
	tween.tween_callback(_return_particle_to_pool.bind(particle))

# ================================
# TEXTES DE DÉGÂTS/SOINS
# ================================

func show_damage_text(grid_position: Vector2, value: int, damage_type: String = "damage"):
	"""Affiche un texte de dégâts ou de soins animé."""
	if not combat_grid:
		return
		
	var world_pos = combat_grid.grid_to_world_position(grid_position)
	var label = _get_damage_text_from_pool()
	if not label:
		return
	
	# Configuration du texte
	label.text = str(abs(value))
	label.position = world_pos + Vector2(-20, -30)  # Offset au-dessus de la cellule
	label.visible = true
	label.modulate = Color.WHITE
	
	# Couleur selon le type
	match damage_type:
		"damage":
			label.modulate = Color.RED
		"heal":
			label.modulate = Color.GREEN
			label.text = "+" + label.text
		"poison":
			label.modulate = Color.PURPLE
		_:
			label.modulate = Color.YELLOW
	
	# Animation
	var tween = create_tween()
	active_animations.append(tween)
	
	tween.parallel().tween_property(label, "position:y", label.position.y - 50, DAMAGE_TEXT_DURATION)
	tween.parallel().tween_property(label, "modulate:a", 0.0, DAMAGE_TEXT_DURATION)
	tween.tween_callback(_return_damage_text_to_pool.bind(label))
	
	print("[VisualEffectsManager] 💥 Texte dégâts affiché: %s" % value)

# ================================
# EFFETS TEMPORAIRES (BUFFS/DEBUFFS)
# ================================

func show_temporary_effect(grid_position: Vector2, effect: CombatState.TemporaryEffect):
	"""Affiche l'icône d'un effet temporaire sur un combattant."""
	if not combat_grid:
		return
		
	var world_pos = combat_grid.grid_to_world_position(grid_position)
	var icon = _get_effect_icon_from_pool()
	if not icon:
		return
	
	# Configuration de l'icône
	icon.position = world_pos + Vector2(20, -40)  # Coin supérieur droit
	icon.visible = true
	icon.modulate = EFFECT_COLORS.get(effect.type, Color.WHITE)
	
	# TODO: Afficher caractère effet via _get_effect_character(effect.type)
	
	# Animation d'apparition
	icon.scale = Vector2.ZERO
	var tween = create_tween()
	active_animations.append(tween)
	
	tween.tween_property(icon, "scale", Vector2(1.0, 1.0), EFFECT_ICON_DURATION)
	tween.tween_delay(2.0)  # Affichage pendant 2 secondes
	tween.tween_property(icon, "modulate:a", 0.0, 0.3)
	tween.tween_callback(_return_effect_icon_to_pool.bind(icon))
	
	print("[VisualEffectsManager] 🔮 Effet temporaire affiché: %s" % effect.type)

func _get_effect_character(effect_type: CombatState.EffectType) -> String:
	"""Retourne un caractère représentant l'effet."""
	match effect_type:
		CombatState.EffectType.POISON: return "P"
		CombatState.EffectType.BOOST_PA: return "+"
		CombatState.EffectType.BOOST_PM: return "M"
		CombatState.EffectType.BOOST_DAMAGE: return "D"
		CombatState.EffectType.REDUCE_PA: return "-"
		CombatState.EffectType.REDUCE_PM: return "X"
		_: return "?"

# ================================
# GESTION DES POOLS D'OBJETS
# ================================

func _get_damage_text_from_pool() -> Label:
	"""Récupère un label de texte du pool ou en crée un nouveau."""
	for label in damage_text_pool:
		if not label.visible:
			return label
	
	# Si aucun disponible, crée un nouveau
	var new_label = Label.new()
	new_label.add_theme_font_size_override("font_size", 24)
	new_label.z_index = 1000
	add_child(new_label)
	damage_text_pool.append(new_label)
	return new_label

func _get_effect_icon_from_pool() -> TextureRect:
	"""Récupère une icône d'effet du pool ou en crée une nouvelle."""
	for icon in effect_icon_pool:
		if not icon.visible:
			return icon
	
	# Si aucune disponible, crée une nouvelle
	var new_icon = TextureRect.new()
	new_icon.custom_minimum_size = Vector2(32, 32)
	new_icon.z_index = 900
	add_child(new_icon)
	effect_icon_pool.append(new_icon)
	return new_icon

func _get_particle_from_pool() -> Node2D:
	"""Récupère une particule du pool ou en crée une nouvelle."""
	for particle in particle_pool:
		if not particle.visible:
			particle.scale = Vector2.ONE
			particle.modulate = Color.WHITE
			return particle
	
	# Si aucune disponible, crée une nouvelle
	var new_particle = Node2D.new()
	new_particle.z_index = 950
	add_child(new_particle)
	particle_pool.append(new_particle)
	return new_particle

func _return_damage_text_to_pool(label: Label):
	"""Remet un label dans le pool après utilisation."""
	if is_instance_valid(label):
		label.visible = false
		label.modulate = Color.WHITE
		animation_completed.emit("damage_text")

func _return_effect_icon_to_pool(icon: TextureRect):
	"""Remet une icône dans le pool après utilisation."""
	if is_instance_valid(icon):
		icon.visible = false
		icon.modulate = Color.WHITE
		icon.scale = Vector2.ONE
		animation_completed.emit("effect_icon")

func _return_particle_to_pool(particle: Node2D):
	"""Remet une particule dans le pool après utilisation."""
	if is_instance_valid(particle):
		particle.visible = false
		particle.modulate = Color.WHITE
		particle.scale = Vector2.ONE
		animation_completed.emit("particle_effect")

# ================================
# NETTOYAGE
# ================================

func clear_all_effects():
	"""Arrête toutes les animations et cache tous les effets."""
	# Arrête toutes les animations
	for tween in active_animations:
		if is_instance_valid(tween):
			tween.kill()
	active_animations.clear()
	
	# Cache tous les éléments des pools
	for label in damage_text_pool:
		if is_instance_valid(label):
			label.visible = false
	
	for icon in effect_icon_pool:
		if is_instance_valid(icon):
			icon.visible = false
	
	for particle in particle_pool:
		if is_instance_valid(particle):
			particle.visible = false
	
	print("[VisualEffectsManager] 🧹 Tous les effets visuels nettoyés")

func _exit_tree():
	"""Nettoyage automatique à la sortie."""
	clear_all_effects() 
