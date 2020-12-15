#!/bin/bash

if [[ -z $LOG_LEVEL ]]; then
  LOG_LEVEL=info
fi

if [[ $SAMPLER_TYPE ]]; then
  SAMPLER_TYPE=dynamic
  echo "Using default sampler type: dynamic"
else
  case $SAMPLER_TYPE in
  "dynamic")
    ;;
  "prob")
    if [[ $SAMPLING_RATE ]]; then
      echo "SAMPLING_RATE must be set while using probability sampler"
      exit 0
    else
      echo "SAMPLING_RATE=${SAMPLING_RATE}"
    fi
    ;;
  "const")
    ALWAYS_SAMPLE ]]; then
      echo "ALWAYS_SAMPLE must be set while using const sampler"
      exit 0
    else
      echo "ALWAYS_SAMPLE=${ALWAYS_SAMPLE}"
    fi
    ;;
    "rate-limit")
    if [[ $MAX_TRACES_PER_SECOND ]]; then
      echo "MAX_TRACES_PER_SECOND must be set while using rate-limit sampler"
      exit 0
    else
      echo "MAX_TRACES_PER_SECOND=${MAX_TRACES_PER_SECOND}"
    fi
    ;;
    *)
      echo "Unsupported sampler type: ${SAMPLER_TYPE}"
      exit 0
    ;;
    esac
fi

echo "LOG_LEVEL=${LOG_LEVEL}"
echo "SAMPLER_TYPE=${SAMPLER_TYPE}"

cd ~/github/ms-http-demo/examples/kube/
files=$(ls ./ | grep "^ms-.*\.yaml$")
for f in $files; do
  sed 's/LOG_LEVEL/'${LOG_LEVEL}'/g' $f | \
  sed 's/SAMPLER_TYPE/'${SAMPLER_TYPE}'/g' | \
  sed 's/SAMPLING_RATE/'${SAMPLING_RATE}'/g' | \
  ALWAYS_SAMPLE}'/g' | \
  sed 's/MAX_TRACES_PER_SECOND/'${MAX_TRACES_PER_SECOND}'/g' | \
  kubectl apply -f -
done
