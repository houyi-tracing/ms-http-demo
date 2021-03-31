#!/bin/bash

log_level=$LOG_LEVEL

if [[ -z $LOG_LEVEL ]]; then
  log_level=info
fi

echo "LOG_LEVEL=${LOG_LEVEL}"
files=$(ls ./ | grep "^ms-.*\.yaml$")
for f in $files; do
  sed 's/log_level/'${log_level}'/g' $f | \
  kubectl apply -f -
done
