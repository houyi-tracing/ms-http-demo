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

package server

import (
	"fmt"
	"github.com/gorilla/mux"
	"github.com/houyi-tracing/ms-http-demo/app/handler"
	"github.com/houyi-tracing/ms-http-demo/pkg/hc"
	"github.com/jaegertracing/jaeger/pkg/recoveryhandler"
	"github.com/opentracing/opentracing-go"
	"go.uber.org/zap"
	"net"
	"net/http"
)

type HttpServerParams struct {
	ServePort   int
	Route       string
	CallingURLs []string
	Logger      *zap.Logger
	Tracer      opentracing.Tracer
	HealthCheck *hc.HealthCheck
}

func StartHttpServer(params *HttpServerParams) (*http.Server, error) {
	hostPort := fmt.Sprintf(":%d", params.ServePort)
	listener, err := net.Listen("tcp", hostPort)
	if err != nil {
		return nil, err
	}

	server := &http.Server{Addr: hostPort}
	serveHttp(server, listener, params)
	return server, nil
}

func serveHttp(server *http.Server, listener net.Listener, params *HttpServerParams) {
	params.Logger.Info("Starting http server",
		zap.Int("port", params.ServePort))

	r := mux.NewRouter()
	httpHandler := handler.NewHttpHandler(&handler.HttpHandlerParams{
		Logger:      params.Logger,
		Tracer:      params.Tracer,
		CallingURLs: params.CallingURLs,
		Route:       params.Route,
	})
	httpHandler.RegisterRoutes(r)

	recoveryHandler := recoveryhandler.NewRecoveryHandler(params.Logger, true)
	server.Handler = recoveryHandler(r)
	go func() {
		if err := server.Serve(listener); err != nil {
			params.Logger.Fatal("failed to serve http", zap.Error(err))
		}
		params.HealthCheck.Set(hc.Unavailable)
	}()
}
