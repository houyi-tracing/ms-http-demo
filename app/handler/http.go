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
	"github.com/opentracing/opentracing-go/ext"
	"go.uber.org/zap"
	"net/http"
	"sync"
	"time"
)

type httpHandler struct {
	serviceName  string
	logger       *zap.Logger
	tracer       opentracing.Tracer
	route        string
	grpcHostPort string
	httpClient   *http.Client
	callingURLs  []string
	tracerOpts   []grpc_opentracing.Option
}

type HttpHandlerParams struct {
	ServiceName  string
	Route        string
	Logger       *zap.Logger
	Tracer       opentracing.Tracer
	GRPCHostPort string
	CallingURLs  []string
}

func NewHttpHandler(params *HttpHandlerParams) app.HTTPHandler {
	ret := &httpHandler{
		serviceName:  params.ServiceName,
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
	router.HandleFunc(h.route, h.serveHttp).Methods(http.MethodGet)
	//h.handleFunc(router, h.serveHttp, h.route).Methods(http.MethodGet)
}

//func (h *httpHandler) handleFunc(
//	router *mux.Router,
//	f func(http.ResponseWriter, *http.Request),
//	route string,
//	_ ...interface{}) *mux.Route {
//	traceMiddleware := nethttp.Middleware(
//		h.tracer,
//		http.HandlerFunc(f),
//		nethttp.OperationNameFunc(func(r *http.Request) string {
//			return route
//		}))
//	return router.HandleFunc(route, traceMiddleware.ServeHTTP)
//}

func (h *httpHandler) serveHttp(_ http.ResponseWriter, r *http.Request) {
	var span opentracing.Span
	spanCtx, err := h.tracer.Extract(opentracing.HTTPHeaders, opentracing.HTTPHeadersCarrier(r.Header))
	if err == opentracing.ErrSpanContextNotFound {
		span = h.tracer.StartSpan(h.route, opentracing.StartTime(time.Now()))
	} else {
		span = h.tracer.StartSpan(h.route, opentracing.StartTime(time.Now()), opentracing.ChildOf(spanCtx))
	}
	span.SetTag("kind", "server")

	time.Sleep(time.Millisecond * 100)

	var wg sync.WaitGroup
	for _, URL := range h.callingURLs {
		if len(URL) != 0 {
			wg.Add(1)
			if err := h.mockHttpRequest(span, URL, &wg); err != nil {
				h.logger.Error("failed to get response", zap.Error(err))
			}
		}
	}
	wg.Wait()

	span.Finish()
}

func (h *httpHandler) mockHttpRequest(span opentracing.Span, URL string, wg *sync.WaitGroup) error {
	defer wg.Done()

	req, err := http.NewRequest(http.MethodGet, URL, nil)
	if err != nil {
		return err
	}

	// Set some tags on the clientSpan to annotate that it's the client span. The additional HTTP tags are useful for debugging purposes.

	if err = h.tracer.Inject(span.Context(), opentracing.HTTPHeaders, opentracing.HTTPHeadersCarrier(req.Header)); err != nil {
		return err
	}
	resp, err := h.httpClient.Do(req)
	if err != nil {
		ext.Error.Set(span, true)
		return err
	} else {
		ext.HTTPStatusCode.Set(span, uint16(resp.StatusCode))
		if resp.StatusCode >= 400 {
			ext.Error.Set(span, true)
		}
		return resp.Body.Close()
	}
}
