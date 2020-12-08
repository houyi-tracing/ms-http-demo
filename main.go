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

package main

import (
	"fmt"
	"github.com/houyi-tracing/houyi-client-go"
	"github.com/houyi-tracing/ms-http-demo/app"
	"github.com/houyi-tracing/ms-http-demo/pkg/config"
	"github.com/houyi-tracing/ms-http-demo/ports"
	"github.com/mitchellh/go-homedir"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
	"go.uber.org/zap"
	"os"
)

var cfgFile string
var v *viper.Viper
var svc *app.Service
var tracerFactory houyi.Factory

var rootCmd = &cobra.Command{
	Use:   app.DefaultServiceName,
	Short: "A template of microservice implemented by Golang",
	Long:  `This is a template of microservice implemented by Golang, for tracing tests.`,
	RunE: func(cmd *cobra.Command, args []string) error {
		if err := svc.Start(v); err != nil {
			return err
		}

		logger := svc.Logger
		tracerFactory.InitFromViper(v, logger)
		tracer, tracerCloser := tracerFactory.CreateTracer(svc.ServiceName)

		myApp := app.NewApp(&app.Params{
			ServiceName: svc.ServiceName,
			Logger:      logger,
			HealthCheck: svc.HC(),
			Tracer:      tracer,
		})
		err := myApp.Start(new(app.Options).InitFromViper(v))
		if err != nil {
			svc.Logger.Fatal("cannot start microservice", zap.Error(err))
		}

		svc.RunAndThen(func() {
			// Do some nothing before completing shutting down.
			// for example, closing I/O or DB connection, etc.
			if err := tracerCloser.Close(); err != nil {
				logger.Error("failed to close tracer", zap.Error(err))
			}
		})
		return nil
	},
}

func init() {
	v = viper.New()
	cobra.OnInitialize(initConfig)

	svc = app.NewService(app.DefaultServiceName, ports.AdminHttpPort)

	// Here you will define your flags and configuration settings.
	// Cobra supports persistent flags, which, if defined here,
	// will be global for your application.

	rootCmd.PersistentFlags().StringVar(&cfgFile, "config", "", "config file (default is $HOME/.microservice-go-template.yaml)")

	tracerFactory = houyi.NewFactory()

	// Cobra also supports local flags, which will only run
	// when this action is called directly.
	//rootCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")

	config.AddFlags(
		v,
		rootCmd,
		houyi.AddFlags,
		app.AddFlags,
		svc.AddFlags)
}

// initConfig reads in config file and ENV variables if set.
func initConfig() {
	if cfgFile != "" {
		// Use config file from the flag.
		v.SetConfigFile(cfgFile)
	} else {
		// Find home directory.
		home, err := homedir.Dir()
		if err != nil {
			fmt.Println(err)
			os.Exit(1)
		}

		// Search config in home directory with name ".microservice-go-template" (without extension).
		v.AddConfigPath(home)
		v.SetConfigName(".microservice-go-template")
	}

	v.AutomaticEnv() // read in environment variables that match

	// If a config file is found, read it in.
	if err := v.ReadInConfig(); err == nil {
		fmt.Println("Using config file:", v.ConfigFileUsed())
	}
}

func main() {
	// rootCmd represents the base command when called without any subcommands
	if err := rootCmd.Execute(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}
