#!/bin/sh

ROOT_CMD="./main"

if [[ $SERVICE_NAME ]]; then
  ROOT_CMD="${ROOT_CMD} --service.name=${SERVICE_NAME}"
else
  echo "\$SERVICE_NAME must be set"
  exit -1
fi

if [[ $LOG_LEVEL ]]; then
  ROOT_CMD="${ROOT_CMD} --log.level=${LOG_LEVEL}"
fi

if [[ $CALLING_URLS ]]; then
  ROOT_CMD="${ROOT_CMD} --calling.urls=${CALLING_URLS}"
fi

if [[ $HTTP_ROUTE ]]; then
  ROOT_CMD="${ROOT_CMD} --http.route=${HTTP_ROUTE}"
fi

if [[ $HTTP_PORT ]]; then
  ROOT_CMD="${ROOT_CMD} --http.port=${HTTP_PORT}"
fi

echo $ROOT_CMD
eval $ROOT_CMD
