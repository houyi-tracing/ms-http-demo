#!/bin/bash

git pull

OS=$1
ARCH=$2

if [[ -z ${OS} ]]; then
  OS=linux
fi

if [[ -z ${ARCH} ]]; then
  ARCH=amd64
fi

echo "OS=${OS}"
echo "ARCH=${ARCH}"

WORK_DIR=.
BUILD_OUT_DIR=~/houyi/ms/http

mkdir -p ${BUILD_OUT_DIR}
CGO_ENABLED=0 GOOS=${OS} GOARCH=${ARCH} go build -tags netgo -o ${BUILD_OUT_DIR}/main -v ${WORK_DIR}/main.go

RUN_SHELL=run.sh
cat <<EOF > ${RUN_SHELL}
#!/bin/sh

echo "SERVICE_NAME=\${SERVICE_NAME}"
echo "HTTP_ROUTE=\${HTTP_ROUTE}"
echo "CALLING_URLS=\${CALLING_URLS}"

if [[ -z \${SAMPLER_TYPE} ]]; then
  SAMPLER_TYPE=dynamic
  echo "Using default sampler type: \${SAMPLER_TYPE}"
else
  echo "SAMPLER_TYPE=\${SAMPLER_TYPE}"
  exec
  case \${SAMPLER_TYPE} in
  "probability")
    if [[ -z \${SAMPLING_RATE} ]]; then
      echo "SAMPLING_RATE must be set for using sampler type: probability"
      break
    else
      echo "SAMPLING_RATE=\${SAMPLER_TYPE}"
    fi
    ./main \
        --service.name=\${SERVICE_NAME} \
        --http.route=\${HTTP_ROUTE} \
        --calling.urls=\${CALLING_URLS} \
        --sampler.type=\${SAMPLER_TYPE} \
        --sampling.rate=\${SAMPLING_RATE}
  ;;
  "const")
    if [[ -z \${ALWAYS_SAMPLE} ]]; then
      echo "ALWAYS_SAMPLE must be set for using sampling type: const"
      break
    else
      echo "ALWAYS_SAMPLE=\${ALWAYS_SAMPLE}"
    fi
    ./main \
        --service.name=\${SERVICE_NAME} \
        --http.route=\${HTTP_ROUTE} \
        --calling.urls=\${CALLING_URLS} \
        --sampler.type=\${SAMPLER_TYPE} \
        --always.sample=\${ALWAYS_SAMPLE}
  ;;
  "rate-limit")
    if [[ -z \${MAX_TRACES_PER_SECOND} ]]; then
      echo "MAX_TRACES_PER_SECOND must be set for using type: rate-limit"
      break
    else
      echo "MAX_TRACES_PER_SECOND=\${MAX_TRACES_PER_SECOND}"
    fi
    ./main \
        --service.name=\${SERVICE_NAME} \
        --http.route=\${HTTP_ROUTE} \
        --calling.urls=\${CALLING_URLS} \
        --sampler.type=\${SAMPLER_TYPE} \
        --max.traces.per.second=\${MAX_TRACES_PER_SECOND}
  ;;
  "dynamic")
    if [[ -n \${AGENT_HOST} ]]; then
      AGENT_HOST=localhost
      echo "AGENT_HOST is empty, using: \${AGENT_HOST}"
    fi
    if [[ -n \${AGENT_GRPC_PORT} ]]; then
      AGENT_GRPC_PORT=6831
      echo "AGENT_GRPC_PORT is empty, using: \${AGENT_GRPC_PORT}"
    fi
    if [[ -n \${AGENT_HTTP_PORT} ]]; then
      AGENT_HTTP_PORT=5778
      echo "AGENT_HTTP_PORT is empty, using: \${AGENT_HTTP_PORT}"
    fi

    echo "AGENT_HOST=\${AGENT_HOST}"
    echo "AGENT_GRPC_PORT=\${AGENT_GRPC_PORT}"
    echo "AGENT_HTTP_PORT=\${AGENT_HTTP_PORT}"

    ./main \
      --service.name=\${SERVICE_NAME} \
      --http.route=\${HTTP_ROUTE} \
      --calling.urls=\${CALLING_URLS} \
      --sampler.type=\${SAMPLER_TYPE} \
      --agent.host=\${AGENT_HOST} \
      --agent.grpc.port=\${AGENT_GRPC_PORT} \
      --agent.http.port=\${AGENT_HTTP_PORT}
  ;;
  *)
    echo "Unsupported sampler type"
  esac
fi
EOF
chmod u+x ${RUN_SHELL}
mv ${RUN_SHELL} ${BUILD_OUT_DIR}/

cat <<EOF > Dockerfile
FROM alpine:3.7
COPY ${RUN_SHELL} /opt/ms/
EXPOSE 80
WORKDIR /opt/ms/
ENTRYPOINT ["/opt/ms/${RUN_SHELL}"]
EOF
mv Dockerfile ${BUILD_OUT_DIR}/
