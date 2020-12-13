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

WORK_DIR=../
BUILD_OUT_DIR=~/houyi/ms/http

mkdir -p ${BUILD_OUT_DIR}
CGO_ENABLED=0 GOOS=${OS} GOARCH=${ARCH} go build -tags netgo -o ${BUILD_OUT_DIR}/main -v ${WORK_DIR}/main.go

RUN_SHELL=run.sh
chmod u+x ${RUN_SHELL}
cp ${RUN_SHELL} ${BUILD_OUT_DIR}/

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
