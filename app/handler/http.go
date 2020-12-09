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

package handler

import (
	"github.com/gorilla/mux"
	grpc_opentracing "github.com/grpc-ecosystem/go-grpc-middleware/tracing/opentracing"
	"github.com/jaegertracing/jaeger/cmd/query/app"
	"github.com/opentracing-contrib/go-stdlib/nethttp"
	"github.com/opentracing/opentracing-go"
	"go.uber.org/zap"
	"net/http"
	"sync"
)

type httpHandler struct {
	logger       *zap.Logger
	tracer       opentracing.Tracer
	route        string
	grpcHostPort string
	httpClient   *http.Client
	callingURLs  []string
	tracerOpts   []grpc_opentracing.Option
}

type HttpHandlerParams struct {
	Route        string
	Logger       *zap.Logger
	Tracer       opentracing.Tracer
	GRPCHostPort string
	CallingURLs  []string
}

func NewHttpHandler(params *HttpHandlerParams) app.HTTPHandler {
	ret := &httpHandler{
		route:        params.Route,
		logger:       params.Logger,
		tracer:       params.Tracer,
		grpcHostPort: params.GRPCHostPort,
		callingURLs:  params.CallingURLs,
		httpClient: &http.Client{
			Transport: &nethttp.Transport{},
		},
	}
	ret.tracerOpts = []grpc_opentracing.Option{
		grpc_opentracing.WithTracer(ret.tracer),
	}

	ret.logger.Info("urls", zap.Strings("URLs", params.CallingURLs))
	return ret
}

func (h *httpHandler) RegisterRoutes(router *mux.Router) {
	h.handleFunc(router, h.serveHttp, h.route).Methods(http.MethodGet)
}

func (h *httpHandler) handleFunc(
	router *mux.Router,
	f func(http.ResponseWriter, *http.Request),
	route string,
	_ ...interface{}) *mux.Route {
	traceMiddleware := nethttp.Middleware(
		h.tracer,
		http.HandlerFunc(f),
		nethttp.OperationNameFunc(func(r *http.Request) string {
			return route
		}))
	return router.HandleFunc(route, traceMiddleware.ServeHTTP)
}

func (h *httpHandler) serveHttp(_ http.ResponseWriter, r *http.Request) {
	h.logger.Debug("receive request", zap.String("remote address", r.RemoteAddr))

	var wg sync.WaitGroup
	for _, URL := range h.callingURLs {
		if len(URL) != 0 {
			wg.Add(1)
			if err := h.mockHttpRequest(r, URL, &wg); err != nil {
				h.logger.Error("failed to get response", zap.Error(err))
			}
		}
	}
	wg.Wait()
}

func (h *httpHandler) mockHttpRequest(r *http.Request, URL string, wg *sync.WaitGroup) error {
	defer wg.Done()

	req, err := http.NewRequest(http.MethodGet, URL, nil)
	if err != nil {
		return err
	}

	req = req.WithContext(r.Context())
	req, ht := nethttp.TraceRequest(h.tracer, req, nethttp.OperationName(h.route))

	resp, err := h.httpClient.Do(req)
	if err != nil {
		return err
	}
	h.logger.Debug("get response",
		zap.String("URL", URL),
		zap.Int("status_code", resp.StatusCode))

	ht.Finish()
	return nil
}
