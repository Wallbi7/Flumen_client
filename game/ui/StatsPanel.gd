extends PanelContainer

## PANEL DE CARACTÉRISTIQUES STYLE DOFUS 1.29
## =============================================
## Interface pour l'attribution des points de caractéristiques et affichage des stats

## MÉTHODES D'ACCÈS AUX NŒUDS
## ============================
# Suppression des @onready qui causent des problèmes
# Utilisation de get_node_or_null() dans les méthodes

## SIGNAUX
## =======
signal stats_updated(new_stats: Dictionary)
signal panel_closed()

## VARIABLES D'ÉTAT
## =================
var original_stats: Dictionary = {}
var current_stats: Dictionary = {}
var original_stat_points: int = 0
var current_stat_points: int = 0
var stat_rows: Array = []

## CONFIGURATION DES STATS DOFUS
## ==============================
var stat_definitions: Array = [
	{
		"name": "vitality",
		"display_name": "Vitalité",
		"description": "Augmente les points de vie",
		"color": Color.RED,
		"cost": 1
	},
	{
		"name": "wisdom",
		"display_name": "Sagesse", 
		"description": "Augmente les points d'action et résistances",
		"color": Color.BLUE,
		"cost": 3
	},
	{
		"name": "strength",
		"display_name": "Force",
		"description": "Augmente les dégâts au corps à corps",
		"color": Color.ORANGE,
		"cost": 1
	},
	{
		"name": "intelligence",
		"display_name": "Intelligence",
		"description": "Augmente les dégâts magiques",
		"color": Color.PURPLE,
		"cost": 1
	},
	{
		"name": "agility",
		"display_name": "Agilité",
		"description": "Augmente les dégâts à distance et PM",
		"color": Color.GREEN,
		"cost": 1
	}
]

## INITIALISATION
## ===============
func _ready():
	print("[StatsPanel] === INITIALISATION PANEL STATS ===")
	
	# Configuration des boutons en utilisant get_node directement
	_setup_connections()
	
	print("[StatsPanel] Panel de stats initialisé")

func _setup_connections():
	"""Configure les connexions de signaux après l'initialisation complète."""
	print("[StatsPanel] Configuration des connexions...")
	
	# Configuration des boutons en utilisant get_node pour éviter les problèmes @onready
	var validate_btn = get_node_or_null("VBox/Buttons/ValidateButton")
	if validate_btn:
		validate_btn.pressed.connect(_on_validate_pressed)
		print("[StatsPanel] ✅ validate_button connecté")
	else:
		print("[StatsPanel] ⚠️ validate_button non trouvé")
	
	var reset_btn = get_node_or_null("VBox/Buttons/ResetButton")
	if reset_btn:
		reset_btn.pressed.connect(_on_reset_pressed)
		print("[StatsPanel] ✅ reset_button connecté")
	else:
		print("[StatsPanel] ⚠️ reset_button non trouvé")
	
	var close_btn = get_node_or_null("CloseButton")
	if close_btn:
		close_btn.pressed.connect(_on_close_pressed)
		print("[StatsPanel] ✅ close_button connecté")
	else:
		print("[StatsPanel] ⚠️ close_button non trouvé")

## OUVERTURE DU PANEL
## ===================
func open_panel(stats: Dictionary, stat_points: int):
	"""Ouvre le panel avec les stats actuelles du personnage."""
	print("[StatsPanel] Ouverture du panel avec stats: ", stats)
	
	# Sauvegarder les valeurs originales
	original_stats = stats.duplicate(true)
	current_stats = stats.duplicate(true)
	original_stat_points = stat_points
	current_stat_points = stat_points
	
	# Mettre à jour l'affichage
	_update_display()
	
	# Créer les lignes de stats
	_create_stat_rows()
	
	# Afficher le panel
	visible = true

## MISE À JOUR DE L'AFFICHAGE
## ===========================
func _update_display():
	"""Met à jour l'affichage des points disponibles."""
	var points_lbl = get_node_or_null("VBox/PointsLabel")
	if points_lbl:
		points_lbl.text = "Points à distribuer : " + str(current_stat_points)
	
	# Activer/désactiver le bouton valider selon les changements
	var has_changes = (current_stats != original_stats) or (current_stat_points != original_stat_points)
	var validate_btn = get_node_or_null("VBox/Buttons/ValidateButton")
	if validate_btn:
		validate_btn.disabled = not has_changes

## CRÉATION DES LIGNES DE STATS
## =============================
func _create_stat_rows():
	"""Crée les lignes d'interface pour chaque statistique."""
	print("[StatsPanel] Création des lignes de stats...")
	
	var stats_container = get_node_or_null("VBox/StatsList")
	if not stats_container:
		print("[StatsPanel] ⚠️ stats_list non trouvé, impossible de créer les lignes")
		return
	
	# Nettoyer les anciennes lignes
	for child in stats_container.get_children():
		child.queue_free()
	stat_rows.clear()
	
	# Créer une ligne pour chaque stat
	for stat_def in stat_definitions:
		var row = _create_stat_row(stat_def)
		stats_container.add_child(row)
		stat_rows.append(row)

## CRÉATION D'UNE LIGNE DE STAT
## =============================
func _create_stat_row(stat_def: Dictionary) -> HBoxContainer:
	"""Crée une ligne d'interface pour une statistique."""
	var row = HBoxContainer.new()
	row.name = stat_def.name + "_row"
	
	# Nom de la stat (coloré)
	var name_label = Label.new()
	name_label.text = stat_def.display_name
	name_label.add_theme_color_override("font_color", stat_def.color)
	name_label.custom_minimum_size = Vector2(120, 0)
	row.add_child(name_label)
	
	# Valeur actuelle
	var value_label = Label.new()
	var current_value = current_stats.get(stat_def.name, 0)
	value_label.text = str(current_value)
	value_label.custom_minimum_size = Vector2(40, 0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(value_label)
	
	# Bouton diminuer
	var minus_button = Button.new()
	minus_button.text = "-"
	minus_button.custom_minimum_size = Vector2(30, 30)
	minus_button.pressed.connect(_on_stat_decreased.bind(stat_def.name))
	row.add_child(minus_button)
	
	# Points investis dans cette session
	var invested_label = Label.new()
	invested_label.text = "0"
	invested_label.custom_minimum_size = Vector2(30, 0)
	invested_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	invested_label.add_theme_color_override("font_color", Color.YELLOW)
	row.add_child(invested_label)
	
	# Bouton augmenter
	var plus_button = Button.new()
	plus_button.text = "+"
	plus_button.custom_minimum_size = Vector2(30, 30)
	plus_button.pressed.connect(_on_stat_increased.bind(stat_def.name))
	row.add_child(plus_button)
	
	# Coût en points
	var cost_label = Label.new()
	cost_label.text = "(" + str(stat_def.cost) + " pt)"
	cost_label.custom_minimum_size = Vector2(50, 0)
	cost_label.add_theme_color_override("font_color", Color.GRAY)
	row.add_child(cost_label)
	
	# Tooltip avec description
	row.tooltip_text = stat_def.description
	
	return row

## AUGMENTATION D'UNE STAT
## ========================
func _on_stat_increased(stat_name: String):
	"""Augmente une statistique si possible."""
	print("[StatsPanel] Augmentation ", stat_name)
	
	# Trouver la définition de la stat
	var stat_def = _get_stat_definition(stat_name)
	if not stat_def:
		return
	
	# Vérifier si on a assez de points
	if current_stat_points < stat_def.cost:
		print("[StatsPanel] Pas assez de points pour ", stat_name)
		return
	
	# Augmenter la stat
	current_stats[stat_name] = current_stats.get(stat_name, 0) + 1
	current_stat_points -= stat_def.cost
	
	# Mettre à jour l'affichage
	_update_stat_row(stat_name)
	_update_display()

## DIMINUTION D'UNE STAT
## ======================
func _on_stat_decreased(stat_name: String):
	"""Diminue une statistique si possible."""
	print("[StatsPanel] Diminution ", stat_name)
	
	# Trouver la définition de la stat
	var stat_def = _get_stat_definition(stat_name)
	if not stat_def:
		return
	
	# Vérifier qu'on peut diminuer (pas en dessous de la valeur originale)
	var current_value = current_stats.get(stat_name, 0)
	var original_value = original_stats.get(stat_name, 0)
	
	if current_value <= original_value:
		print("[StatsPanel] Ne peut pas diminuer ", stat_name, " en dessous de la valeur originale")
		return
	
	# Diminuer la stat
	current_stats[stat_name] = current_value - 1
	current_stat_points += stat_def.cost
	
	# Mettre à jour l'affichage
	_update_stat_row(stat_name)
	_update_display()

## MISE À JOUR D'UNE LIGNE
## ========================
func _update_stat_row(stat_name: String):
	"""Met à jour l'affichage d'une ligne de statistique."""
	var stats_container = get_node_or_null("VBox/StatsList")
	if not stats_container:
		return
	
	var row = stats_container.get_node_or_null(stat_name + "_row")
	if not row:
		return
	
	# Mettre à jour la valeur actuelle
	var value_label = row.get_child(1)
	var current_value = current_stats.get(stat_name, 0)
	value_label.text = str(current_value)
	
	# Mettre à jour les points investis
	var invested_label = row.get_child(3)
	var original_value = original_stats.get(stat_name, 0)
	var invested = current_value - original_value
	invested_label.text = str(max(0, invested))
	
	# Colorer selon le changement
	if invested > 0:
		value_label.add_theme_color_override("font_color", Color.GREEN)
	else:
		value_label.add_theme_color_override("font_color", Color.WHITE)

## UTILITAIRES
## ============
func _get_stat_definition(stat_name: String) -> Dictionary:
	"""Récupère la définition d'une statistique."""
	for stat_def in stat_definitions:
		if stat_def.name == stat_name:
			return stat_def
	return {}

## CALLBACKS DES BOUTONS
## ======================
func _on_validate_pressed():
	"""Valide les changements et ferme le panel."""
	print("[StatsPanel] Validation des changements")
	
	# Émettre le signal avec les nouvelles stats
	stats_updated.emit({
		"stats": current_stats,
		"stat_points": current_stat_points
	})
	
	# Fermer le panel
	_close_panel()

func _on_reset_pressed():
	"""Remet à zéro tous les changements."""
	print("[StatsPanel] Reset des changements")
	
	# Restaurer les valeurs originales
	current_stats = original_stats.duplicate(true)
	current_stat_points = original_stat_points
	
	# Mettre à jour l'affichage
	_update_all_stat_rows()
	_update_display()

func _on_close_pressed():
	"""Ferme le panel sans sauvegarder."""
	print("[StatsPanel] Fermeture sans sauvegarde")
	_close_panel()

## FERMETURE DU PANEL
## ===================
func _close_panel():
	"""Ferme le panel et émet le signal de fermeture."""
	visible = false
	panel_closed.emit()

## MISE À JOUR GLOBALE
## ====================
func _update_all_stat_rows():
	"""Met à jour toutes les lignes de statistiques."""
	for stat_def in stat_definitions:
		_update_stat_row(stat_def.name) 
