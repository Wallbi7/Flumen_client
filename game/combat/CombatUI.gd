extends Control
class_name CombatUI

## INTERFACE UTILISATEUR POUR LE COMBAT TACTIQUE DOFUS-LIKE
## ========================================================
## Interface adaptée pour le nouveau système de combat synchronisé avec serveur.
## Affiche PA/PM, initiative, timer 30s, ordre des tours et actions selon le modèle Dofus.

# ================================
# RÉFÉRENCES AUX NŒUDS UI
# ================================

## Conteneur principal de l'interface
@onready var main_container: VBoxContainer = $MainContainer

## Section des ressources (PA/PM)
@onready var resources_panel: HBoxContainer = $MainContainer/ResourcesPanel
@onready var ap_label: Label = $MainContainer/ResourcesPanel/APContainer/APLabel
@onready var ap_bar: ProgressBar = $MainContainer/ResourcesPanel/APContainer/APBar
@onready var mp_label: Label = $MainContainer/ResourcesPanel/MPContainer/MPLabel
@onready var mp_bar: ProgressBar = $MainContainer/ResourcesPanel/MPContainer/MPBar

## Section de l'ordre des tours avec initiative
@onready var turn_order_panel: VBoxContainer = $MainContainer/TurnOrderPanel
@onready var turn_order_title: Label = $MainContainer/TurnOrderPanel/TitleLabel
@onready var turn_order_list: VBoxContainer = $MainContainer/TurnOrderPanel/ScrollContainer/TurnOrderList

## Section des actions (adaptée pour sorts avec coûts PA)
@onready var actions_panel: HBoxContainer = $MainContainer/ActionsPanel
@onready var attack_button: Button = $MainContainer/ActionsPanel/AttackButton
@onready var spell_button: Button = $MainContainer/ActionsPanel/SpellButton
@onready var item_button: Button = $MainContainer/ActionsPanel/ItemButton
@onready var pass_button: Button = $MainContainer/ActionsPanel/PassButton
@onready var end_turn_button: Button = $MainContainer/ActionsPanel/EndTurnButton

## Section du timer et informations (Timer 30s Dofus-like)
@onready var info_panel: HBoxContainer = $MainContainer/InfoPanel
@onready var timer_label: Label = $MainContainer/InfoPanel/TimerLabel
@onready var phase_label: Label = $MainContainer/InfoPanel/PhaseLabel

## Section des effets temporaires (optionnelle)
@onready var effects_panel: VBoxContainer = get_node_or_null("MainContainer/EffectsPanel")
@onready var effects_title: Label = get_node_or_null("MainContainer/EffectsPanel/EffectsTitle") 
@onready var effects_list: VBoxContainer = get_node_or_null("MainContainer/EffectsPanel/EffectsList")

# ================================
# VARIABLES DE GESTION
# ================================

## État de combat synchronisé avec serveur
var current_combat_state: CombatState = null

## Combattant du joueur local
var local_player_combatant: CombatState.Combatant = null

## Timer pour mise à jour du countdown
var timer_update_timer: Timer = null

## Couleurs pour les équipes et états
const ALLY_COLOR = Color.CYAN
const ENEMY_COLOR = Color.ORANGE  
const CURRENT_FIGHTER_COLOR = Color.YELLOW
const DEAD_FIGHTER_COLOR = Color.GRAY

# ================================
# SIGNAUX
# ================================

## Émis quand le joueur demande une action
signal action_requested(action_type: CombatState.ActionType, target_data: Dictionary)

# ================================
# INITIALISATION
# ================================

func _ready():
	print("[CombatUI] === INITIALISATION INTERFACE COMBAT DOFUS-LIKE ===")
	
	# Connecter les signaux des boutons
	_connect_action_buttons()
	
	# Créer le timer de mise à jour
	_setup_update_timer()
	
	# Masquer l'interface par défaut
	hide_combat_ui()

## Connecte les signaux des boutons d'actions
func _connect_action_buttons():
	if attack_button:
		attack_button.pressed.connect(_on_attack_button_pressed)
	if spell_button:
		spell_button.pressed.connect(_on_spell_button_pressed)
	if item_button:
		item_button.pressed.connect(_on_item_button_pressed)
	if pass_button:
		pass_button.pressed.connect(_on_pass_button_pressed)
	if end_turn_button:
		end_turn_button.pressed.connect(_on_end_turn_button_pressed)

## Configure le timer de mise à jour de l'interface
func _setup_update_timer():
	timer_update_timer = Timer.new()
	timer_update_timer.wait_time = 0.1  # Mise à jour toutes les 100ms
	timer_update_timer.timeout.connect(_on_timer_update)
	add_child(timer_update_timer)

# ================================
# MÉTHODES PRINCIPALES DE SYNCHRONISATION
# ================================

## Met à jour l'interface avec un nouvel état de combat du serveur
func update_from_combat_state(combat_state: CombatState):
	current_combat_state = combat_state
	local_player_combatant = _find_local_player_combatant()
	
	print("[CombatUI] 🔄 Mise à jour interface depuis état serveur")
	
	# Mettre à jour tous les composants
	update_resources_display()
	update_turn_order_display()
	update_action_buttons()
	update_phase_display()
	update_effects_display()
	
	# Démarrer/arrêter le timer selon l'état
	if combat_state.status == CombatState.CombatStatus.IN_PROGRESS:
		timer_update_timer.start()
	else:
		timer_update_timer.stop()

## Trouve le combattant correspondant au joueur local
func _find_local_player_combatant() -> CombatState.Combatant:
	if not current_combat_state:
		return null
	
	# Ici, on devrait obtenir l'ID du personnage du joueur actuel
	# Pour l'instant, on prend le premier joueur de l'équipe alliée
	for combatant in current_combat_state.combatants:
		if combatant.is_player and combatant.team_id == 0:  # Équipe alliée
			return combatant
	return null

# ================================
# AFFICHAGE DES RESSOURCES (PA/PM)
# ================================

## Met à jour l'affichage des PA/PM
func update_resources_display():
	if not local_player_combatant:
		_hide_resources()
		return
	
	# Affichage des Points d'Action (PA)
	if ap_label and ap_bar:
		ap_label.text = "PA: %d/%d" % [local_player_combatant.remaining_action_points, local_player_combatant.base_action_points]
		ap_bar.max_value = local_player_combatant.base_action_points
		ap_bar.value = local_player_combatant.remaining_action_points
		
		# Couleur selon PA restants
		if local_player_combatant.remaining_action_points == 0:
			ap_bar.modulate = Color.RED
		elif local_player_combatant.remaining_action_points <= 2:
			ap_bar.modulate = Color.YELLOW
		else:
			ap_bar.modulate = Color.GREEN
	
	# Affichage des Points de Mouvement (PM)
	if mp_label and mp_bar:
		mp_label.text = "PM: %d/%d" % [local_player_combatant.remaining_movement_points, local_player_combatant.base_movement_points]
		mp_bar.max_value = local_player_combatant.base_movement_points
		mp_bar.value = local_player_combatant.remaining_movement_points
		
		# Couleur selon PM restants
		if local_player_combatant.remaining_movement_points == 0:
			mp_bar.modulate = Color.RED
		elif local_player_combatant.remaining_movement_points <= 1:
			mp_bar.modulate = Color.YELLOW
		else:
			mp_bar.modulate = Color.BLUE

## Masque l'affichage des ressources
func _hide_resources():
	if ap_label:
		ap_label.text = "PA: --/--"
	if ap_bar:
		ap_bar.value = 0
	if mp_label:
		mp_label.text = "PM: --/--"
	if mp_bar:
		mp_bar.value = 0

# ================================
# AFFICHAGE ORDRE DES TOURS AVEC INITIATIVE
# ================================

## Met à jour l'ordre des tours avec initiative
func update_turn_order_display():
	if not current_combat_state or not turn_order_list:
		return
	
	# Nettoyer la liste existante
	for child in turn_order_list.get_children():
		child.queue_free()
	
	# Titre avec index actuel
	if turn_order_title:
		turn_order_title.text = "Ordre des Tours (%d/%d)" % [current_combat_state.current_turn_index + 1, current_combat_state.turn_order.size()]
	
	# Créer l'affichage pour chaque combattant dans l'ordre
	for i in range(current_combat_state.turn_order.size()):
		var character_id = current_combat_state.turn_order[i]
		var combatant = current_combat_state.get_combatant_by_id(character_id)
		
		if combatant:
			var entry = _create_turn_order_entry(combatant, i == current_combat_state.current_turn_index)
			turn_order_list.add_child(entry)

## Crée une entrée dans l'ordre des tours
func _create_turn_order_entry(combatant: CombatState.Combatant, is_current: bool) -> HBoxContainer:
	var entry = HBoxContainer.new()
	entry.custom_minimum_size.y = 30
	
	# Nom du combattant
	var name_label = Label.new()
	name_label.text = combatant.name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entry.add_child(name_label)
	
	# Initiative (style Dofus)
	var initiative_label = Label.new()
	initiative_label.text = "(%d)" % combatant.initiative
	initiative_label.custom_minimum_size.x = 50
	entry.add_child(initiative_label)
	
	# PA/PM restants (si c'est le tour actuel)
	if is_current:
		var stats_label = Label.new()
		stats_label.text = "%dPA/%dPM" % [combatant.remaining_action_points, combatant.remaining_movement_points]
		stats_label.custom_minimum_size.x = 80
		entry.add_child(stats_label)
	
	# Couleurs selon l'état et l'équipe
	var color = ALLY_COLOR if combatant.team_id == 0 else ENEMY_COLOR
	
	if combatant.is_dead:
		color = DEAD_FIGHTER_COLOR
	elif is_current:
		color = CURRENT_FIGHTER_COLOR
	
	name_label.modulate = color
	initiative_label.modulate = color
	
	return entry

# ================================
# AFFICHAGE ET CONTRÔLES PRINCIPAUX
# ================================

## Affiche l'interface de combat
func show_combat_ui():
	visible = true
	print("[CombatUI] 👁️ Interface de combat affichée")

## Masque l'interface de combat
func hide_combat_ui():
	visible = false
	print("[CombatUI] 🙈 Interface de combat masquée")

## Met à jour l'affichage de la phase
func update_phase_display():
	if not current_combat_state or not phase_label:
		return
	
	match current_combat_state.status:
		CombatState.CombatStatus.PLACEMENT:
			phase_label.text = "Phase: Placement"
			phase_label.modulate = Color.BLUE
		CombatState.CombatStatus.IN_PROGRESS:
			phase_label.text = "Phase: Combat"
			phase_label.modulate = Color.RED
		CombatState.CombatStatus.FINISHED:
			phase_label.text = "Phase: Terminé"
			phase_label.modulate = Color.GREEN
		CombatState.CombatStatus.STARTING:
			phase_label.text = "Phase: Démarrage"
			phase_label.modulate = Color.GRAY

## Met à jour l'affichage des effets temporaires
func update_effects_display():
	if not effects_list:
		return
	
	# Nettoyer la liste existante
	for child in effects_list.get_children():
		child.queue_free()
	
	# Ajouter les effets du combattant local
	if local_player_combatant and local_player_combatant.active_effects.size() > 0:
		for effect in local_player_combatant.active_effects:
			var effect_entry = _create_effect_entry(effect)
			effects_list.add_child(effect_entry)

## Crée une entrée pour un effet temporaire
func _create_effect_entry(effect: CombatState.TemporaryEffect) -> HBoxContainer:
	var entry = HBoxContainer.new()
	entry.custom_minimum_size.y = 25
	
	var name_label = Label.new()
	name_label.text = effect.description if effect.description else "Effet"
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entry.add_child(name_label)
	
	var duration_label = Label.new()
	duration_label.text = "(%d tours)" % effect.duration
	duration_label.custom_minimum_size.x = 70
	entry.add_child(duration_label)
	
	# Couleur selon le type d'effet
	var color = Color.WHITE
	match effect.type:
		CombatState.EffectType.POISON:
			color = Color.PURPLE
		CombatState.EffectType.BOOST_PA, CombatState.EffectType.BOOST_PM, CombatState.EffectType.BOOST_DAMAGE:
			color = Color.GREEN
		CombatState.EffectType.REDUCE_PA, CombatState.EffectType.REDUCE_PM:
			color = Color.RED
	
	name_label.modulate = color
	duration_label.modulate = color
	
	return entry

## Met à jour l'état des boutons d'actions selon les capacités actuelles
func update_action_buttons():
	if not current_combat_state or not local_player_combatant:
		_disable_all_action_buttons()
		return
	
	var combatant = local_player_combatant
	var current_character_id = current_combat_state.get_current_combatant()
	var is_player_turn = current_character_id and current_character_id.character_id == combatant.character_id
	
	# Mettre à jour chaque bouton selon les capacités du combattant
	if attack_button:
		attack_button.disabled = not is_player_turn or not combatant.can_cast_spell(3)  # Attaque coûte 3 PA
		attack_button.text = "Attaque (3 PA)"
	
	if spell_button:
		spell_button.disabled = not is_player_turn or not combatant.can_cast_spell(2)  # Sort coûte 2 PA minimum
		spell_button.text = "Sort (2+ PA)"
	
	if item_button:
		item_button.disabled = not is_player_turn or not combatant.can_cast_spell(1)  # Objet coûte 1 PA
		item_button.text = "Objet (1 PA)"
	
	if pass_button:
		pass_button.disabled = not is_player_turn
		pass_button.text = "Passer (0 PA)"
	
	if end_turn_button:
		end_turn_button.disabled = not is_player_turn
		end_turn_button.text = "Fin de tour"

## Désactive tous les boutons d'actions
func _disable_all_action_buttons():
	if attack_button:
		attack_button.disabled = true
	if spell_button:
		spell_button.disabled = true
	if item_button:
		item_button.disabled = true
	if pass_button:
		pass_button.disabled = true
	if end_turn_button:
		end_turn_button.disabled = true

## Met à jour l'affichage du timer
func update_timer_display(remaining_time: float):
	if not timer_label:
		return
	
	var minutes = int(remaining_time / 60)  # Division entière explicite
	var seconds = int(remaining_time) % 60
	
	timer_label.text = "Temps: %02d:%02d" % [minutes, seconds]
	
	# Couleur selon le temps restant
	if remaining_time > 15:
		timer_label.modulate = Color.GREEN
	elif remaining_time > 5:
		timer_label.modulate = Color.YELLOW
	else:
		timer_label.modulate = Color.RED

# ================================
# TIMER ET MISE À JOUR CONTINUE
# ================================

## Gestionnaire du timer de mise à jour
func _on_timer_update():
	if current_combat_state:
		update_timer_display(current_combat_state.get_remaining_turn_time())

# ================================
# GESTIONNAIRES D'ÉVÉNEMENTS
# ================================
# CALLBACKS OBSOLÈTES - SUPPRIMÉS
# ================================
# Les callbacks CombatTurnManager ont été supprimés car remplacés par
# le système synchronisé CombatState qui met à jour automatiquement
# l'interface via update_from_combat_state().

# ================================
# GESTIONNAIRES DE BOUTONS
# ================================

## Gestionnaire du bouton d'attaque
func _on_attack_button_pressed():
	print("[CombatUI] 🗡️ Bouton Attaque pressé")
	action_requested.emit(CombatState.ActionType.CAST_SPELL, {"spell_id": "basic_attack"})

## Gestionnaire du bouton de sort
func _on_spell_button_pressed():
	print("[CombatUI] ✨ Bouton Sort pressé")
	action_requested.emit(CombatState.ActionType.CAST_SPELL, {"spell_id": "player_spell"})

## Gestionnaire du bouton d'objet
func _on_item_button_pressed():
	print("[CombatUI] 🎒 Bouton Objet pressé")
	action_requested.emit(CombatState.ActionType.USE_ITEM, {"item_id": "healing_potion"})

## Gestionnaire du bouton passer
func _on_pass_button_pressed():
	print("[CombatUI] ⏭️ Bouton Passer pressé")
	action_requested.emit(CombatState.ActionType.PASS_TURN, {})

## Gestionnaire du bouton fin de tour
func _on_end_turn_button_pressed():
	print("[CombatUI] 🏁 Bouton Fin de tour pressé")
	action_requested.emit(CombatState.ActionType.PASS_TURN, {})

# ================================
# UTILITAIRES PUBLICS
# ================================

## Force la mise à jour complète de l'interface
func refresh_all_displays():
	if not current_combat_state:
		return
	
	print("[CombatUI] 🔄 Actualisation complète de l'interface")
	
	update_phase_display()
	update_resources_display()
	update_turn_order_display()
	update_action_buttons()
	update_effects_display()

## Affiche un message temporaire à l'utilisateur
func show_temporary_message(message: String, _duration: float = 3.0):
	print("[CombatUI] 📢 Message: ", message)
	# TODO: Implémenter l'affichage de message temporaire avec durée variable

## Affiche les informations de débogage de l'interface
func debug_print_ui_state():
	print("[CombatUI] === ÉTAT DE L'INTERFACE ===")
	print("Visible: ", visible)
	print("Combat State connecté: ", current_combat_state != null)
	print("Combattant affiché: ", local_player_combatant.name if local_player_combatant else "Aucun")
	
	if local_player_combatant:
		print("Ressources affichées:")
		print("  - PA: ", local_player_combatant.remaining_action_points, "/", local_player_combatant.base_action_points)
		print("  - PM: ", local_player_combatant.remaining_movement_points, "/", local_player_combatant.base_movement_points)
	
	print("Boutons d'actions:")
	print("  - Attaque: ", "ACTIF" if (attack_button and not attack_button.disabled) else "INACTIF/N/A")
	print("  - Sort: ", "ACTIF" if (spell_button and not spell_button.disabled) else "INACTIF/N/A")
	print("  - Objet: ", "ACTIF" if (item_button and not item_button.disabled) else "INACTIF/N/A")
	print("  - Passer: ", "ACTIF" if (pass_button and not pass_button.disabled) else "INACTIF/N/A")
	print("  - Fin de tour: ", "ACTIF" if (end_turn_button and not end_turn_button.disabled) else "INACTIF/N/A")
	
	print("======================================") 
