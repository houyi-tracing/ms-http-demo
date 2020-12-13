#!/bin/sh

ROOT_CMD="./main"

fi [[ $SERVICE_NAME ]]; then
  ROOT_CMD="${ROOT_CMD} --service.name=${SERVICE_NAME}"
else
  echo "\$SERVICE_NAME must be set"
  exit -1
fi

if [[ $LOG_LEVEL ]]; then
  ROOT_CMD="${ROOT_CMD} --log.level=${LOG_LEVEL}"
fi

if [[ $SAMPLER_TYPE ]; then
  ROOT_CMD="${ROOT_CMD} --sampler.type=${SAMPLER_TYPE}"
fi

if [[ $ALWAYS_SAMPLE ]]; then
  ROOT_CMD="${ROOT_CMD} --always.sample=${ALWAYS_SAMPLE}"
fi

if [[ $SAMPLING_RATE ]]; then
  ROOT_CMD="${ROOT_CMD} --sampling.rate=${SAMPLING_RATE}"
fi

if [[ $MAX_MAX_TRACES_PER_SECOND ]]; then
  ROOT_CMD="${ROOT_CMD} --max.traces.per.second=${MAX_TRACES_PER_SECOND}"
fi

if [[ $CALLING_URLS ]]; then
  ROOT_CMD="${ROOT_CMD} --calling.urls=${CALLING_URLS}"
fi

if [[ $HTTP_ROUTE ]]; then
  ROOT_CMD="${ROOT_CMD} --http.route=${HTTP_ROUTE}"
fi

if [[ $BUFFER_REFRESH_INTERVAL ]]; then
  ROOT_CMD="${ROOT_CMD} --buffer.refresh.interval=${BUFFER_REFRESH_INTERVAL}"
fi

if [[ $REFRESH_INTERVAL ]]; then
  ROOT_CMD="${ROOT_CMD} --refresh.interval=${REFRESH_INTERVAL}"
fi

if [[ $HTTP_PORT ]]; then
  ROOT_CMD="${ROOT_CMD} --http.port=${HTTP_PORT}"
fi

echo $ROOT_CMD
eval $ROOT_CMD
