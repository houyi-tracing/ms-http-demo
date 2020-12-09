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
	"encoding/json"
	"fmt"
	"github.com/houyi-tracing/ms-http-demo/pkg/hc"
	"github.com/magiconair/properties/assert"
	"io/ioutil"
	"log"
	"net/http"
	"testing"
	"time"
)

const (
	httpPort = 28831
)

type HcResp struct {
	StatusMsg string    `json:"status"`
	UpSince   time.Time `json:"upSince"`
	Uptime    string    `json:"uptime"`
}

func TestAdminServer(t *testing.T) {
	aServer := NewAdminServer(httpPort)

	aServer.hc.Ready()

	go func() {
		if err := aServer.Serve(); err != nil {
			log.Fatal(err)
		}
	}()

	var hcResp HcResp

	hcResp = getHcResp()
	assert.Equal(t, hcResp.StatusMsg, "Service Available")

	aServer.hc.Set(hc.Unavailable)

	hcResp = getHcResp()
	assert.Equal(t, hcResp.StatusMsg, "Service Unavailable")
}

func getHcResp() HcResp {
	resp, err := http.Get(fmt.Sprintf("http://localhost:%d/health", httpPort))
	if err != nil {
		log.Fatal(err)
	}

	bytes, _ := ioutil.ReadAll(resp.Body)
	hcResp := HcResp{}
	_ = json.Unmarshal(bytes, &hcResp)
	_ = resp.Body.Close()
	return hcResp
}
