package db

import (
	"gorm.io/driver/mysql"
	"gorm.io/gorm"
	"time"
)

type AppDB struct {
	*gorm.DB
}

func NewMysqlDB(dsn string) (*gorm.DB, error) {
	var err error
	var Eloguent *gorm.DB
	for i := 0; i < 3; i++ {
		Eloguent, err = gorm.Open(mysql.Open(dsn), &gorm.Config{})
		if err != nil {
			break
		}
		time.Sleep(time.Second)
	}
	if err != nil {
		return nil, err
	}

	sqlDB, err := Eloguent.DB()
	if err != nil {
		return nil, err
	}

	sqlDB.SetMaxIdleConns(4)

	return Eloguent, nil
}
