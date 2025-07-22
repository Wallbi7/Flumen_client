extends Panel

## SLOT D'OBJET DOFUS-STYLE
## =========================
## Component réutilisable pour les slots d'inventaire et d'équipement avec drag&drop.

## SIGNAUX
## =======
signal slot_clicked(slot_id, item_data)
signal item_dragged(item_data, source_slot)
signal item_dropped(target_slot)
signal item_hovered(item_data, slot_position)
signal item_unhovered()

## CONSTANTES
## ===========
const SLOT_SIZE = Vector2(48, 48)
const EMPTY_COLOR = Color(0.2, 0.2, 0.3, 0.8)
const HOVER_COLOR = Color(0.4, 0.4, 0.5, 0.9)
const SELECTED_COLOR = Color(0.6, 0.4, 0.2, 0.9)

## VARIABLES D'ÉTAT
## =================
var slot_type: String = "inventory"  # "inventory" ou "equipment"
var slot_id = null  # Index pour inventory, nom pour equipment
var item_data: Dictionary = {}
var is_empty: bool = true
var is_hovered: bool = false
var is_dragging: bool = false

## RÉFÉRENCES UI
## ==============
var item_icon: TextureRect
var quantity_label: Label
var quality_border: NinePatchRect

## INITIALISATION
## ===============
func _ready():
	custom_minimum_size = SLOT_SIZE
	_setup_ui_components()
	_setup_mouse_handling()
	_update_visual_state()

func setup_slot(type: String, id):
	"""Configure le type et l'ID du slot."""
	slot_type = type
	slot_id = id

## CONFIGURATION UI
## =================
func _setup_ui_components():
	"""Crée les composants UI du slot."""
	# Icône de l'objet
	item_icon = TextureRect.new()
	item_icon.name = "ItemIcon"
	item_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	item_icon.anchors_preset = Control.PRESET_FULL_RECT
	item_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(item_icon)
	
	# Label de quantité
	quantity_label = Label.new()
	quantity_label.name = "QuantityLabel"
	quantity_label.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	quantity_label.anchor_left = 0.6
	quantity_label.anchor_top = 0.6
	quantity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	quantity_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	quantity_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(quantity_label)
	
	# Bordure de qualité (rarité)
	quality_border = NinePatchRect.new()
	quality_border.name = "QualityBorder"
	quality_border.anchors_preset = Control.PRESET_FULL_RECT
	quality_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(quality_border)

func _setup_mouse_handling():
	"""Configure la gestion de la souris."""
	mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Connecter les signaux de base
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)

## GESTION DES OBJETS
## ===================
func set_item(new_item_data: Dictionary):
	"""Définit l'objet dans ce slot."""
	item_data = new_item_data
	is_empty = item_data.is_empty()
	_update_item_display()
	_update_visual_state()

func clear_item():
	"""Vide le slot."""
	item_data.clear()
	is_empty = true
	_update_item_display()
	_update_visual_state()

func _update_item_display():
	"""Met à jour l'affichage de l'objet."""
	if is_empty:
		# Slot vide
		item_icon.texture = null
		quantity_label.text = ""
		quality_border.texture = null
	else:
		# Objet présent
		_display_item_icon()
		_display_item_quantity()
		_display_item_quality()

func _display_item_icon():
	"""Affiche l'icône de l'objet."""
	var template = item_data.get("item_template", {})
	var icon_path = _get_item_icon_path(template)
	
	# Vérifier si l'icône spécifique existe
	if ResourceLoader.exists(icon_path):
		item_icon.texture = load(icon_path)
	else:
		# Utiliser icône par défaut (null = carré blanc Godot)
		item_icon.texture = _get_default_icon_for_type(template.get("item_type", ""))
		print("[ItemSlot] Icône non trouvée: ", icon_path)

func _display_item_quantity():
	"""Affiche la quantité de l'objet."""
	var quantity = item_data.get("quantity", 1)
	if quantity > 1:
		quantity_label.text = str(quantity)
	else:
		quantity_label.text = ""

func _display_item_quality():
	"""Affiche la bordure de qualité selon la rarité."""
	var template = item_data.get("item_template", {})
	var rarity = template.get("rarity", "COMMON")
	
	var border_color = _get_rarity_color(rarity)
	if border_color != Color.TRANSPARENT:
		quality_border.modulate = border_color
		# TODO: Charger texture de bordure appropriée
	else:
		quality_border.texture = null

## UTILITAIRES VISUELS
## ====================
func _get_item_icon_path(template: Dictionary) -> String:
	"""Retourne le chemin vers l'icône de l'objet."""
	var icon_id = template.get("icon_id", "")
	if icon_id.is_empty():
		icon_id = template.get("name", "").to_lower().replace(" ", "_")
	
	return "res://assets/icons/items/" + icon_id + ".png"

func _get_default_icon_for_type(item_type: String) -> Texture2D:
	"""Retourne l'icône par défaut pour un type d'objet."""
	# Utiliser l'icône Godot par défaut si les ressources personnalisées n'existent pas
	return null  # Godot affichera un carré blanc par défaut

func _get_rarity_color(rarity: String) -> Color:
	"""Retourne la couleur associée à une rarité."""
	match rarity:
		"COMMON":
			return Color.WHITE
		"UNCOMMON":
			return Color.html("#2ecc71")  # Vert
		"RARE":
			return Color.html("#3498db")  # Bleu
		"MYTHIC":
			return Color.html("#9b59b6")  # Violet
		"LEGENDARY":
			return Color.html("#e67e22")  # Orange
		_:
			return Color.TRANSPARENT

func _update_visual_state():
	"""Met à jour l'état visuel du slot."""
	var style = StyleBoxFlat.new()
	
	if is_dragging:
		style.bg_color = SELECTED_COLOR
	elif is_hovered:
		style.bg_color = HOVER_COLOR
	else:
		style.bg_color = EMPTY_COLOR
	
	# Bordure
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color.html("#666666")
	
	add_theme_stylebox_override("panel", style)

## GESTION DES ÉVÉNEMENTS SOURIS
## ===============================
func _on_mouse_entered():
	"""Souris entre dans le slot."""
	is_hovered = true
	_update_visual_state()
	
	if not is_empty:
		item_hovered.emit(item_data, global_position)

func _on_mouse_exited():
	"""Souris sort du slot."""
	is_hovered = false
	_update_visual_state()
	item_unhovered.emit()

func _on_gui_input(event: InputEvent):
	"""Gère les entrées souris sur le slot."""
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# Clic gauche
			slot_clicked.emit(slot_id, item_data)
			
			if not is_empty:
				# Démarrer le drag and drop
				_start_drag()
	
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			# Clic droit - actions contextuelles
			_show_context_menu()

func _start_drag():
	"""Démarre le glisser-déposer."""
	if is_empty:
		return
	
	is_dragging = true
	_update_visual_state()
	item_dragged.emit(item_data, self)

func _show_context_menu():
	"""Affiche le menu contextuel."""
	if is_empty:
		return
	
	# TODO: Implémenter menu contextuel
	print("[ItemSlot] Menu contextuel pour: ", item_data.get("name", "Unknown"))

## DRAG & DROP HANDLING
## =====================
func can_drop_data(position: Vector2, data) -> bool:
	"""Vérifie si on peut déposer des données ici."""
	# Accepter les objets d'autres slots
	return data is Dictionary and data.has("item_data")

func drop_data(position: Vector2, data):
	"""Reçoit les données déposées."""
	if data.has("item_data"):
		item_dropped.emit(self)

func get_drag_data(position: Vector2):
	"""Fournit les données pour le drag and drop."""
	if is_empty:
		return null
	
	# Créer une preview visuelle
	var preview = TextureRect.new()
	preview.texture = item_icon.texture
	preview.size = SLOT_SIZE
	set_drag_preview(preview)
	
	return {
		"item_data": item_data,
		"source_slot": self
	}

## ACCESSEURS
## ===========
func get_item_data() -> Dictionary:
	"""Retourne les données de l'objet."""
	return item_data

func is_slot_empty() -> bool:
	"""Vérifie si le slot est vide."""
	return is_empty

func get_slot_type() -> String:
	"""Retourne le type de slot."""
	return slot_type

func get_slot_id():
	"""Retourne l'ID du slot."""
	return slot_id

## ANIMATIONS
## ===========
func animate_item_received():
	"""Animation quand un objet est reçu."""
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)

func animate_item_removed():
	"""Animation quand un objet est retiré."""
	var tween = create_tween()
	tween.tween_property(item_icon, "modulate", Color(1, 1, 1, 0), 0.2)

## TOOLTIP
## =======
func show_tooltip():
	"""Affiche le tooltip de l'objet."""
	if is_empty:
		return
	
	var tooltip_text = _generate_tooltip_text()
	# TODO: Afficher tooltip avec le texte généré
	print("[ItemSlot] Tooltip: ", tooltip_text)

func _generate_tooltip_text() -> String:
	"""Génère le texte du tooltip."""
	var template = item_data.get("item_template", {})
	var text = ""
	
	# Nom de l'objet avec couleur de rarité
	text += template.get("name", "Objet inconnu") + "\n"
	
	# Type et niveau requis
	var level_req = template.get("level_requirement", 0)
	if level_req > 0:
		text += "Niveau requis: " + str(level_req) + "\n"
	
	# Description
	var description = template.get("description", "")
	if not description.is_empty():
		text += "\n" + description + "\n"
	
	# Effets de l'objet
	var effects = template.get("effects", {})
	if not effects.is_empty():
		text += "\nEffets:\n"
		for effect_name in effects:
			var effect_value = effects[effect_name]
			text += "+ " + str(effect_value) + " " + effect_name + "\n"
	
	return text