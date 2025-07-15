package database

import (
	"database/sql"
	"fmt"
	"time"

	"github.com/flumen/flumen_server/internal/models"
)

// CharacterRepository gère les opérations sur les personnages
type CharacterRepository struct {
	db *sql.DB
}

// NewCharacterRepository crée un nouveau repository pour les personnages
func NewCharacterRepository(db *sql.DB) *CharacterRepository {
	return &CharacterRepository{db: db}
}

// CreateCharacter crée un nouveau personnage
func (r *CharacterRepository) CreateCharacter(userID int, req models.CreateCharacterRequest) (*models.Character, error) {
	// Vérifier que le nom n'est pas déjà pris
	exists, err := r.CharacterNameExists(req.Name)
	if err != nil {
		return nil, fmt.Errorf("erreur lors de la vérification du nom: %w", err)
	}
	if exists {
		return nil, fmt.Errorf("ce nom de personnage est déjà utilisé")
	}

	// Vérifier que l'utilisateur n'a pas déjà 5 personnages (limite Dofus)
	count, err := r.GetCharacterCountByUser(userID)
	if err != nil {
		return nil, fmt.Errorf("erreur lors de la vérification du nombre de personnages: %w", err)
	}
	if count >= 5 {
		return nil, fmt.Errorf("vous avez déjà atteint la limite de 5 personnages")
	}

	// Récupérer les stats de base de la classe
	classInfo := models.GetClassInfo(req.Class)
	if classInfo.ID == "" {
		return nil, fmt.Errorf("classe invalide: %s", req.Class)
	}

	// Créer le personnage avec les stats de base
	character := &models.Character{
		UserID:       userID,
		Name:         req.Name,
		Class:        req.Class,
		Level:        1,
		Vitality:     classInfo.BaseStats.Vitality,
		Wisdom:       classInfo.BaseStats.Wisdom,
		Strength:     classInfo.BaseStats.Strength,
		Intelligence: classInfo.BaseStats.Intelligence,
		Chance:       classInfo.BaseStats.Chance,
		Agility:      classInfo.BaseStats.Agility,
		Experience:   0,
		MapX:         0, // Position de départ
		MapY:         0,
		PosX:         15, // Centre de la map
		PosY:         15,
		CreatedAt:    time.Now(),
		UpdatedAt:    time.Now(),
		LastLogin:    time.Now(),
	}

	// Calculer les stats dérivées
	character.CalculateStats()

	// Insérer en base de données
	query := `
		INSERT INTO characters (user_id, name, class, level, vitality, wisdom, strength, intelligence, chance, agility, experience, map_x, map_y, pos_x, pos_y, created_at, updated_at, last_login)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18)
		RETURNING id
	`

	err = r.db.QueryRow(
		query,
		character.UserID, character.Name, character.Class, character.Level,
		character.Vitality, character.Wisdom, character.Strength, character.Intelligence,
		character.Chance, character.Agility, character.Experience,
		character.MapX, character.MapY, character.PosX, character.PosY,
		character.CreatedAt, character.UpdatedAt, character.LastLogin,
	).Scan(&character.ID)

	if err != nil {
		return nil, fmt.Errorf("erreur lors de la création du personnage: %w", err)
	}

	return character, nil
}

// GetCharactersByUser récupère tous les personnages d'un utilisateur
func (r *CharacterRepository) GetCharactersByUser(userID int) ([]models.Character, error) {
	query := `
		SELECT id, user_id, name, class, level, vitality, wisdom, strength, intelligence, chance, agility, experience, map_x, map_y, pos_x, pos_y, created_at, updated_at, last_login
		FROM characters
		WHERE user_id = $1
		ORDER BY last_login DESC
	`

	rows, err := r.db.Query(query, userID)
	if err != nil {
		return nil, fmt.Errorf("erreur lors de la récupération des personnages: %w", err)
	}
	defer rows.Close()

	var characters []models.Character
	for rows.Next() {
		var char models.Character
		err := rows.Scan(
			&char.ID, &char.UserID, &char.Name, &char.Class, &char.Level,
			&char.Vitality, &char.Wisdom, &char.Strength, &char.Intelligence,
			&char.Chance, &char.Agility, &char.Experience,
			&char.MapX, &char.MapY, &char.PosX, &char.PosY,
			&char.CreatedAt, &char.UpdatedAt, &char.LastLogin,
		)
		if err != nil {
			return nil, fmt.Errorf("erreur lors du scan du personnage: %w", err)
		}

		// Calculer les stats dérivées
		char.CalculateStats()
		characters = append(characters, char)
	}

	return characters, nil
}

// GetCharacterByID récupère un personnage par son ID
func (r *CharacterRepository) GetCharacterByID(characterID int) (*models.Character, error) {
	query := `
		SELECT id, user_id, name, class, level, vitality, wisdom, strength, intelligence, chance, agility, experience, map_x, map_y, pos_x, pos_y, created_at, updated_at, last_login
		FROM characters
		WHERE id = $1
	`

	var char models.Character
	err := r.db.QueryRow(query, characterID).Scan(
		&char.ID, &char.UserID, &char.Name, &char.Class, &char.Level,
		&char.Vitality, &char.Wisdom, &char.Strength, &char.Intelligence,
		&char.Chance, &char.Agility, &char.Experience,
		&char.MapX, &char.MapY, &char.PosX, &char.PosY,
		&char.CreatedAt, &char.UpdatedAt, &char.LastLogin,
	)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("personnage non trouvé")
		}
		return nil, fmt.Errorf("erreur lors de la récupération du personnage: %w", err)
	}

	// Calculer les stats dérivées
	char.CalculateStats()
	return &char, nil
}

// UpdateCharacterPosition met à jour la position d'un personnage
func (r *CharacterRepository) UpdateCharacterPosition(characterID int, mapX, mapY, posX, posY int) error {
	query := `
		UPDATE characters
		SET map_x = $1, map_y = $2, pos_x = $3, pos_y = $4, updated_at = $5
		WHERE id = $6
	`

	_, err := r.db.Exec(query, mapX, mapY, posX, posY, time.Now(), characterID)
	if err != nil {
		return fmt.Errorf("erreur lors de la mise à jour de la position: %w", err)
	}

	return nil
}

// UpdateCharacterLastLogin met à jour la dernière connexion
func (r *CharacterRepository) UpdateCharacterLastLogin(characterID int) error {
	query := `
		UPDATE characters
		SET last_login = $1, updated_at = $2
		WHERE id = $3
	`

	_, err := r.db.Exec(query, time.Now(), time.Now(), characterID)
	if err != nil {
		return fmt.Errorf("erreur lors de la mise à jour de la dernière connexion: %w", err)
	}

	return nil
}

// CharacterNameExists vérifie si un nom de personnage existe déjà
func (r *CharacterRepository) CharacterNameExists(name string) (bool, error) {
	query := `SELECT EXISTS(SELECT 1 FROM characters WHERE LOWER(name) = LOWER($1))`

	var exists bool
	err := r.db.QueryRow(query, name).Scan(&exists)
	if err != nil {
		return false, fmt.Errorf("erreur lors de la vérification du nom: %w", err)
	}

	return exists, nil
}

// GetCharacterCountByUser compte le nombre de personnages d'un utilisateur
func (r *CharacterRepository) GetCharacterCountByUser(userID int) (int, error) {
	query := `SELECT COUNT(*) FROM characters WHERE user_id = $1`

	var count int
	err := r.db.QueryRow(query, userID).Scan(&count)
	if err != nil {
		return 0, fmt.Errorf("erreur lors du comptage des personnages: %w", err)
	}

	return count, nil
}

// DeleteCharacter supprime un personnage (soft delete possible plus tard)
func (r *CharacterRepository) DeleteCharacter(characterID, userID int) error {
	query := `DELETE FROM characters WHERE id = $1 AND user_id = $2`

	result, err := r.db.Exec(query, characterID, userID)
	if err != nil {
		return fmt.Errorf("erreur lors de la suppression du personnage: %w", err)
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("erreur lors de la vérification de la suppression: %w", err)
	}

	if rowsAffected == 0 {
		return fmt.Errorf("personnage non trouvé ou non autorisé")
	}

	return nil
}
