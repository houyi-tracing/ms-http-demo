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
	"github.com/houyi-tracing/ms-http-demo/app/server"
	"github.com/houyi-tracing/ms-http-demo/pkg/hc"
	"github.com/opentracing/opentracing-go"
	"go.uber.org/zap"
	"net/http"
	"strings"
)

type App struct {
	serviceName string
	logger      *zap.Logger
	hc          *hc.HealthCheck
	httpServer  *http.Server
	tracer      opentracing.Tracer
}

type Params struct {
	ServiceName string
	Logger      *zap.Logger
	HealthCheck *hc.HealthCheck
	Tracer      opentracing.Tracer
}

func NewApp(params *Params) *App {
	return &App{
		serviceName: params.ServiceName,
		logger:      params.Logger,
		hc:          params.HealthCheck,
		tracer:      params.Tracer,
	}
}

func (a *App) Start(appOptions *Options) error {
	httpParams := server.HttpServerParams{
		ServePort:   appOptions.HttpServePort,
		Logger:      a.logger,
		Tracer:      a.tracer,
		HealthCheck: a.hc,
		CallingURLs: extractURLs(appOptions.CallingURLs),
		Route:       appOptions.Route,
	}
	if httpServer, err := server.StartHttpServer(&httpParams); err != nil {
		a.logger.Error("failed to start http server", zap.Error(err))
		return err
	} else {
		a.httpServer = httpServer
		return nil
	}
}

func (a *App) Close() error {
	if a.httpServer != nil {
		_ = a.httpServer.Close()
	}
	return nil
}

func extractURLs(urls string) []string {
	return strings.Split(urls, ",")
}
