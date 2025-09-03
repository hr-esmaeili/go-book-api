package config

import (
	"github.com/BurntSushi/toml"
	"github.com/mitchellh/go-homedir"
)

func LoadConfig(fpath string) (Config, error) {
	fpath, err := homedir.Expand(fpath)

	var c Config
	if _, err := toml.DecodeFile(fpath, &c); err != nil {
		return Config{}, err
	}

	err = c.check()
	if err != nil {
		return Config{}, err
	}

	return c, nil
}
