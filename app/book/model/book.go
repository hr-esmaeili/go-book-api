package model

import "time"

// Book represents a book entity
type Book struct {
	ID        uint      `json:"id" gorm:"primaryKey"`
	Title     string    `json:"title" gorm:"size:255;not null"`
	Author    string    `json:"author" gorm:"size:255;not null"`
	Year      int       `json:"year"`
	ISBN      string    `json:"isbn" gorm:"size:20;uniqueIndex"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

func (b *Book) create(name string, author string, year int) error {

	var book = Book{}
	book.Title = name
	book.Author = author
	book.Year = year

	return nil
}
