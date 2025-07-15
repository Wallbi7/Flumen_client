package models

import (
	"time"
)

// CharacterClass représente les classes disponibles
type CharacterClass string

const (
	ClassWarrior CharacterClass = "warrior" // Guerrier
	ClassArcher  CharacterClass = "archer"  // Archer
)

// Character représente un personnage de joueur
type Character struct {
	ID     int            `json:"id" db:"id"`
	UserID int            `json:"user_id" db:"user_id"`
	Name   string         `json:"name" db:"name"`
	Class  CharacterClass `json:"class" db:"class"`
	Level  int            `json:"level" db:"level"`

	// Stats de base Dofus-like
	Vitality     int `json:"vitality" db:"vitality"`         // Vitalité (PV)
	Wisdom       int `json:"wisdom" db:"wisdom"`             // Sagesse (PM)
	Strength     int `json:"strength" db:"strength"`         // Force (dommages corps à corps)
	Intelligence int `json:"intelligence" db:"intelligence"` // Intelligence (dommages sorts)
	Chance       int `json:"chance" db:"chance"`             // Chance (dommages distance)
	Agility      int `json:"agility" db:"agility"`           // Agilité (initiative, esquive)

	// Stats calculées (non stockées en DB, calculées à la volée)
	HealthPoints   int `json:"health_points" db:"-"`   // Points de Vie (Vitalité * multiplicateur)
	ActionPoints   int `json:"action_points" db:"-"`   // Points d'Action (6 de base)
	MovementPoints int `json:"movement_points" db:"-"` // Points de Mouvement (3 de base)
	Initiative     int `json:"initiative" db:"-"`      // Initiative (Agilité + bonus)

	// Expérience et progression
	Experience     int64 `json:"experience" db:"experience"`
	ExperienceNext int64 `json:"experience_next" db:"-"` // XP nécessaire pour le niveau suivant

	// Position dans le monde
	MapX int `json:"map_x" db:"map_x"`
	MapY int `json:"map_y" db:"map_y"`
	PosX int `json:"pos_x" db:"pos_x"`
	PosY int `json:"pos_y" db:"pos_y"`

	// Métadonnées
	CreatedAt time.Time `json:"created_at" db:"created_at"`
	UpdatedAt time.Time `json:"updated_at" db:"updated_at"`
	LastLogin time.Time `json:"last_login" db:"last_login"`
}

// ClassInfo contient les informations sur une classe
type ClassInfo struct {
	ID          CharacterClass `json:"id"`
	Name        string         `json:"name"`
	Description string         `json:"description"`
	BaseStats   ClassStats     `json:"base_stats"`
	IconPath    string         `json:"icon_path"`
}

// ClassStats représente les stats de base d'une classe
type ClassStats struct {
	Vitality     int `json:"vitality"`
	Wisdom       int `json:"wisdom"`
	Strength     int `json:"strength"`
	Intelligence int `json:"intelligence"`
	Chance       int `json:"chance"`
	Agility      int `json:"agility"`
}

// GetClassInfo retourne les informations d'une classe
func GetClassInfo(class CharacterClass) ClassInfo {
	switch class {
	case ClassWarrior:
		return ClassInfo{
			ID:          ClassWarrior,
			Name:        "Guerrier",
			Description: "Combattant au corps à corps, maître des armes lourdes",
			BaseStats: ClassStats{
				Vitality:     20, // Plus de PV
				Wisdom:       10,
				Strength:     15, // Forte en Force
				Intelligence: 5,
				Chance:       5,
				Agility:      10,
			},
			IconPath: "res://assets/classes/warrior_icon.png",
		}
	case ClassArcher:
		return ClassInfo{
			ID:          ClassArcher,
			Name:        "Archer",
			Description: "Combattant à distance, précis et agile",
			BaseStats: ClassStats{
				Vitality:     15,
				Wisdom:       10,
				Strength:     5,
				Intelligence: 5,
				Chance:       15, // Forte en Chance (dommages distance)
				Agility:      15, // Forte en Agilité
			},
			IconPath: "res://assets/classes/archer_icon.png",
		}
	default:
		return ClassInfo{}
	}
}

// GetAllClasses retourne toutes les classes disponibles
func GetAllClasses() []ClassInfo {
	return []ClassInfo{
		GetClassInfo(ClassWarrior),
		GetClassInfo(ClassArcher),
	}
}

// CalculateStats calcule les stats dérivées du personnage
func (c *Character) CalculateStats() {
	// Points de Vie = Vitalité * 5 + bonus niveau
	c.HealthPoints = c.Vitality*5 + c.Level*2

	// Points d'Action = 6 de base (pourra être modifié par équipements)
	c.ActionPoints = 6

	// Points de Mouvement = 3 de base + bonus Agilité
	c.MovementPoints = 3 + c.Agility/50

	// Initiative = Agilité + niveau + aléatoire (sera calculé en combat)
	c.Initiative = c.Agility + c.Level

	// XP nécessaire pour le niveau suivant (courbe exponentielle)
	c.ExperienceNext = int64(c.Level * c.Level * 100)
}

// CanLevelUp vérifie si le personnage peut monter de niveau
func (c *Character) CanLevelUp() bool {
	return c.Experience >= c.ExperienceNext
}

// LevelUp fait monter le personnage d'un niveau
func (c *Character) LevelUp() {
	if !c.CanLevelUp() {
		return
	}

	c.Level++

	// Bonus de stats par niveau selon la classe
	classInfo := GetClassInfo(c.Class)
	c.Vitality += classInfo.BaseStats.Vitality / 10 // 2 vitalité par niveau pour guerrier
	c.Wisdom += classInfo.BaseStats.Wisdom / 10
	c.Strength += classInfo.BaseStats.Strength / 10
	c.Intelligence += classInfo.BaseStats.Intelligence / 10
	c.Chance += classInfo.BaseStats.Chance / 10
	c.Agility += classInfo.BaseStats.Agility / 10

	// Recalculer les stats
	c.CalculateStats()
}

// CreateCharacterRequest représente une demande de création de personnage
type CreateCharacterRequest struct {
	Name  string         `json:"name" validate:"required,min=3,max=20"`
	Class CharacterClass `json:"class" validate:"required"`
}

// CreateCharacterResponse représente la réponse de création de personnage
type CreateCharacterResponse struct {
	Success   bool      `json:"success"`
	Character Character `json:"character,omitempty"`
	Error     string    `json:"error,omitempty"`
}
