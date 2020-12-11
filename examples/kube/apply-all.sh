#!/bin/bash

log_level=$1

if [[ -z $log_level ]]; then
  log_level=info
elif [[ $log_level -ne "debug" ]]; then
  echo "Invalid log level: ${log_level}"
  exit -1
fi

cd ~/github/ms-http-demo/examples/kube/
git pull
files=$(ls ./ | grep "^ms-.*\.yaml$")
for f in $files; do
  sed 's/\"info\"/\"'${log_level}'\"/g' $f | kubectl apply -f -
done