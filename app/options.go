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
	"github.com/houyi-tracing/ms-http-demo/ports"
	"github.com/spf13/viper"
)

const (
	serveHttpPort = "http-port"
	serviceName   = "service-name"
	route         = "http-route"
	callingURL    = "calling-urls"

	DefaultHttpPort    = ports.ServeHttpPort
	DefaultRoute       = "/"
	DefaultServiceName = "houyi-http-test-app"
	DefaultCallingURL  = ""
)

type Options struct {
	HttpServePort int
	Route         string
	ServiceName   string
	CallingURLs   string
}

func AddFlags(flags *flag.FlagSet) {
	flags.Int(serveHttpPort, DefaultHttpPort, "Port to serve HTTP")
	flags.String(serviceName, DefaultServiceName, "Service name")
	flags.String(route, DefaultRoute, "Route for serving http")
	flags.String(callingURL, DefaultCallingURL, "URLs to call")
}

func (aOpts *Options) InitFromViper(v *viper.Viper) *Options {
	aOpts.HttpServePort = v.GetInt(serveHttpPort)
	aOpts.ServiceName = v.GetString(serviceName)
	aOpts.Route = v.GetString(route)
	aOpts.CallingURLs = v.GetString(callingURL)
	return aOpts
}
