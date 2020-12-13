#!/bin/bash

log_level=$1
sampler_type=$2

if [[ -z $log_level ]]; then
  log_level=info
elif [[ $log_level -ne "debug" ]]; then
  echo "Invalid log level: ${log_level}"
  exit -1
fi

if [[ -z $sampler_type ]]; then
  sampler_type=dynamic
fi

echo "LOG_LEVEL=${log_level}"
echo "SAMPLER_TYPE=${sampler_type}"

cd ~/github/ms-http-demo/examples/kube/
git pull
files=$(ls ./ | grep "^ms-.*\.yaml$")
for f in $files; do
  sed 's/\"debug\"/\"'${log_level}'\"/g' $f | \
  sed 's/\"dynamic\"/\"'${sampler_type}'\"/g' | \
  kubectl apply -f -
done
