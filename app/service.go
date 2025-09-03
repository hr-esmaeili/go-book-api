package app

import "gorm.io/gorm"

func NewApp(db *gorm.DB) *App {
	return &App{
		db: db,
	}
}

type App struct {
	db *gorm.DB
}

func (app *App) AppB() *gorm.DB { return app.db }
