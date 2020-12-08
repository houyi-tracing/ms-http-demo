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
/opt/ms/main --service-name=\${SERVICE_NAME} --http-route=\${HTTP_ROUTE} --calling-urls=\${CALLING_URLS}
EOF
chmod u+x ${RUN_SHELL}
mv ${RUN_SHELL} ${BUILD_OUT_DIR}/

cat <<EOF > Dockerfile
FROM alpine:3.7
COPY ${RUN_SHELL} /opt/ms/
EXPOSE 80
ENTRYPOINT ["/opt/ms/${RUN_SHELL}"]
EOF
mv Dockerfile ${BUILD_OUT_DIR}/
