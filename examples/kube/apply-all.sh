#!/bin/bash

log_level=$LOG_LEVEL
sampler_type=$SAMPLER_TYPE
sampling_rate=$SAMPLING_RATE
always_sample=$ALWAYS_SAMPLE
max_traces_per_second=$MAX_TRACES_PER_SECOND

if [[ -z $log_level ]]; then
  log_level=info
fi

if [[ -z $sampler_type ]]; then
  sampler_type=dynamic
  echo "Using default sampler type: dynamic"
else
  case $sampler_type in
  "dynamic")
    ;;
  "prob")
    if [[ -z $sampling_rate ]]; then
      echo "SAMPLING_RATE must be set while using probability sampler"
      exit 0
    else
      echo "SAMPLING_RATE=${sampler_rate}"
    fi
    ;;
  "const")
    if [[ -z $always_sample ]]; then
      echo "ALWAYS_SAMPLE must be set while using const sampler"
      exit 0
    else
      echo "ALWAYS_SAMPLE=${always_sample}"
    fi
    ;;
    "rate-limit")
    if [[ -z $max_traces_per_second ]]; then
      echo "MAX_TRACES_PER_SECOND must be set while using rate-limit sampler"
      exit 0
    else
      echo "MAX_TRACES_PER_SECOND=${max_traces_per_second}"
    fi
    ;;
    *)
      echo "Unsupported sampler type: ${sampler_type}"
      exit 0
    ;;
    esac
fi


echo "LOG_LEVEL=${log_level}"
echo "SAMPLER_TYPE=${sampler_type}"

cd ~/github/ms-http-demo/examples/kube/
git pull
files=$(ls ./ | grep "^ms-.*\.yaml$")
for f in $files; do
  sed 's/log_level/'${log_level}'/g' $f | \
  sed 's/sampler_type/'${sampler_type}'/g' | \
  sed 's/sampling_rate/'${sampler_rate}'/g' | \
  sed 's/always_sample/'${always_sample}'/g' | \
  sed 's/max_traces_per_second/'${max_traces_per_second}'/g' | \
  kubectl apply -f -
done
