#!/bin/bash

SERVICE_NAME=$1
PERCENTAGE=$2

if [[ -z $SERVICE_NAME ]]; then
  echo "Service name cannot be empty"
  exit -1
fi

arr=(${SERVICE_NAME//-/ })
echo ${arr[@]}

ROOT_SERVICE=${arr[0]}-${arr[1]}
OPERATION=${arr[2]}

echo $ROOT_SERVICE
echo $OPERATION

file=ms-abort.yaml
sed 's/SERVICE_NAME/'${SERVICE_NAME}'/g' $file | \
sed 's/ABORT_PERCENTAGE/'${PERCENTAGE}'/g' | \
sed 's/ROOT_SERVICE/'${ROOT_SERVICE}'/g' | \
sed 's/OPERATION/'${OPERATION}'/g' | \
kubectl apply -f -

echo "SERVICE_NAME=${SERVICE_NAME}"
echo "PERCENTAGE=${PERCENTAGE}"
echo "Abort injection done"
