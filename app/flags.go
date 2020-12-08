// Copyright (c) 2020 The Houyi Authors.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package app

import (
	"flag"
	"github.com/spf13/viper"
	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
)

const (
	// logging
	logLevel        = "log-level"
	defaultLogLevel = "info"
)

type SharedFlags struct {
	logging
}

type logging struct {
	LogLevel string
}

func AddSharedFlags(flags *flag.FlagSet) {
	addLoggingFlags(flags)
}

func addLoggingFlags(flags *flag.FlagSet) {
	flags.String(
		logLevel,
		defaultLogLevel, "Minimal allowed log Level. For more levels see https://github.com/uber-go/zap")
}

func (aOpts *SharedFlags) InitFromViper(v *viper.Viper) *SharedFlags {
	aOpts.LogLevel = v.GetString(logLevel)
	return aOpts
}

func (aOpts *SharedFlags) NewLogger(conf zap.Config, options ...zap.Option) (*zap.Logger, error) {
	var level zapcore.Level
	err := (&level).UnmarshalText([]byte(aOpts.LogLevel))
	if err != nil {
		return nil, err
	}
	conf.Level = zap.NewAtomicLevelAt(level)
	return conf.Build(options...)
}
