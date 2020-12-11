#!/bin/bash

SERVICE_NAME=$1
PERCENTAGE=$2

if [[ -z $SERVICE_NAME ]]; then
  echo "Service name cannot be empty"
  exit -1
fi

file=$( ls ./ | grep 'ms-'${SERVICE_NAME}'-abort.yaml')
if [[ -z $file ]]; then
  echo "YAML file for service ${SERVICE_NAME} does not exist"
  exit -1
else
  sed 's/[SERVICE_NAME]/'${SERVICE_NAME}'/g' file | sed 's/[ABORT_PERCENTAGE]/'${PERCENTAGE}'/g' - | echo
fi

echo "SERVICE_NAME=${SERVICE_NAME}"
echo "PERCENTAGE=${PERCENTAGE}"
echo "Abort injection done"
