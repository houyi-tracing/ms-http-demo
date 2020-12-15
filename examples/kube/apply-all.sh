#!/bin/bash

if [[ -z $LOG_LEVEL ]]; then
  LOG_LEVEL=info
fi

case $SAMPLER_TYPE in
"probability")
  if [[ $SAMPLING_RATE ]]; then
    echo "SAMPLING_RATE=${SAMPLING_RATE}"
  else
    SAMPLING_RATE=1
    echo "SAMPLING_RATE=${SAMPLING_RATE} (default)"
  fi
  ;;
"const")
  if [[ $ALWAYS_SAMPLE ]]; then
    echo "ALWAYS_SAMPLE=${ALWAYS_SAMPLE}"
  else
    ALWAYS_SAMPLE=true
    echo "ALWAYS_SAMPLE=${ALWAYS_SAMPLE} (default)"
  fi
  ;;
"rate-limit")
  if [[ $MAX_TRACES_PER_SECOND ]]; then
    echo "MAX_TRACES_PER_SECOND=${MAX_TRACES_PER_SECOND}"
  else
    MAX_TRACES_PER_SECOND=50
    echo "MAX_TRACES_PER_SECOND=${MAX_TRACES_PER_SECOND} (default)"
  fi
  ;;
*)
  SAMPLER_TYPE=dynamic
  echo "Using default sampler type: ${SAMPLER_TYPE}"
  ;;
esac

echo "LOG_LEVEL=${LOG_LEVEL}"
echo "SAMPLER_TYPE=${SAMPLER_TYPE}"

cd ~/github/ms-http-demo/examples/kube/
files=$(ls ./ | grep "^ms-.*\.yaml$")
for f in $files; do
  sed 's/log_level/'${LOG_LEVEL}'/g' $f | \
  sed 's/sampler_type/'${SAMPLER_TYPE}'/g' | \
  sed 's/sampling_rate/'${SAMPLING_RATE}'/g' | \
  sed 's/always_sample/'${ALWAYS_SAMPLE}'/g' | \
  sed 's/max_traces_per_second/'${MAX_TRACES_PER_SECOND}'/g' | \
  kubectl apply -f -
done
