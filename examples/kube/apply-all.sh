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
fi

if [[ -z $sampling_rate ]]; then
  sampling_rate=1.00
fi

if [[ -z $always_sample ]]; then
  always_sample=true
fi

if [[ -z $max_traces_per_second ]]; then
  max_traces_per_second=50
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
