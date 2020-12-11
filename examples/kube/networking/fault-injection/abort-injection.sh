#!/bin/bash

SERVICE_NAME=$1
PERCENTAGE=$2

if [[ -z $SERVICE_NAME ]]; then
  echo "Service name cannot be empty"
  exit -1
fi

file=ms-abort.yaml
sed 's/SERVICE_NAME/'${SERVICE_NAME}'/g' $file | sed 's/ABORT_PERCENTAGE/'${PERCENTAGE}'/g'

echo "SERVICE_NAME=${SERVICE_NAME}"
echo "PERCENTAGE=${PERCENTAGE}"
echo "Abort injection done"
