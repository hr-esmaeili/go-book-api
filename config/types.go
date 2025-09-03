package config

import (
	"encoding/base64"
	"fmt"
	"time"
)

type Config struct {
	Api      ApiConfig      `toml:"api"`
	Database DatabaseConfig `toml:"database"`
}

type ApiConfig struct {
	Ip      string   `toml:"ip"`
	Port    string   `toml:"port"`
	Timeout Duration `toml:"timeout"`
}

type DatabaseConfig struct {
	DSN string `toml:"dsn"`
}

type Duration struct {
	time.Duration
}

func (c *Config) check() error {
	err := c.Database.check()
	if err != nil {
		return err
	}
	return nil
}

func (c *DatabaseConfig) check() error {
	if c.DSN == "" {
		return fmt.Errorf("dsn is required")
	}

	originDSN, err := base64.StdEncoding.DecodeString(c.DSN)
	if err != nil {
		return nil
	}
	c.DSN = string(originDSN)
	return nil
}
