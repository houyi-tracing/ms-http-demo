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

if [[ -n \$1 ]]; then
  CALLING_URLS=\$(echo \$1)
else
  CALLING_URLS=""
fi

echo "SERVICE_NAME=\${SERVICE_NAME}"
echo "HTTP_ROUTE=\${HTTP_ROUTE}"
echo "CALLING_URLS=\${CALLING_URLS}"

if [[ -z \${AGENT_HOST} ]]; then
  AGENT_HOST=localhost
fi
if [[ -z \${AGENT_GRPC_PORT} ]]; then
  AGENT_GRPC_PORT=6831
fi
if [[ -z \${AGENT_HTTP_PORT} ]]; then
  AGENT_HTTP_PORT=5778
fi

echo "AGENT_HOST=\${AGENT_HOST}"
echo "AGENT_GRPC_PORT=\${AGENT_GRPC_PORT}"
echo "AGENT_HTTP_PORT=\${AGENT_HTTP_PORT}"


if [[ -z \${SAMPLER_TYPE} ]]; then
  SAMPLER_TYPE=dynamic
  echo "Using default sampler type: \${SAMPLER_TYPE}"
fi

echo "SAMPLER_TYPE=\${SAMPLER_TYPE}"
exec
case \${SAMPLER_TYPE} in
"probability")
  if [[ -z \${SAMPLING_RATE} ]]; then
    echo "SAMPLING_RATE must be set for using sampler type: probability"
    exit -1
  else
    echo "SAMPLING_RATE=\${SAMPLER_TYPE}"
  fi
  ./main \
      --service.name=\${SERVICE_NAME} \
      --http.route=\${HTTP_ROUTE} \
      --calling.urls=\${CALLING_URLS} \
      --sampler.type=\${SAMPLER_TYPE} \
      --sampling.rate=\${SAMPLING_RATE} \
      --agent.host=\${AGENT_HOST} \
      --agent.grpc.port=\${AGENT_GRPC_PORT} \
      --agent.http.port=\${AGENT_HTTP_PORT}
;;
"const")
  if [[ -z \${ALWAYS_SAMPLE} ]]; then
    echo "ALWAYS_SAMPLE must be set for using sampling type: const"
    exit -1
  else
    echo "ALWAYS_SAMPLE=\${ALWAYS_SAMPLE}"
  fi
  ./main \
      --service.name=\${SERVICE_NAME} \
      --http.route=\${HTTP_ROUTE} \
      --calling.urls=\${CALLING_URLS} \
      --sampler.type=\${SAMPLER_TYPE} \
      --always.sample=\${ALWAYS_SAMPLE} \
      --agent.host=\${AGENT_HOST} \
      --agent.grpc.port=\${AGENT_GRPC_PORT} \
      --agent.http.port=\${AGENT_HTTP_PORT}
;;
"rate-limit")
  if [[ -z \${MAX_TRACES_PER_SECOND} ]]; then
    echo "MAX_TRACES_PER_SECOND must be set for using type: rate-limit"
    exit -1
  else
    echo "MAX_TRACES_PER_SECOND=\${MAX_TRACES_PER_SECOND}"
  fi
  ./main \
      --service.name=\${SERVICE_NAME} \
      --http.route=\${HTTP_ROUTE} \
      --calling.urls=\${CALLING_URLS} \
      --sampler.type=\${SAMPLER_TYPE} \
      --max.traces.per.second=\${MAX_TRACES_PER_SECOND} \
      --agent.host=\${AGENT_HOST} \
      --agent.grpc.port=\${AGENT_GRPC_PORT} \
      --agent.http.port=\${AGENT_HTTP_PORT}
;;
"dynamic")
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

EOF
chmod u+x ${RUN_SHELL}
mv ${RUN_SHELL} ${BUILD_OUT_DIR}/

BUILD_DOCKER=build-docker.sh
cat <<EOF > ${BUILD_DOCKER}
docker build -t houyitracing/ms-http .
EOF
chmod u+x ${BUILD_DOCKER}
mv ${BUILD_DOCKER} ${BUILD_OUT_DIR}/

cat <<EOF > Dockerfile
FROM alpine:3.7
COPY main /opt/ms/
COPY ${RUN_SHELL} /opt/ms/
EXPOSE 80
WORKDIR /opt/ms/
ENTRYPOINT ["/opt/ms/${RUN_SHELL}"]
EOF
mv Dockerfile ${BUILD_OUT_DIR}/
