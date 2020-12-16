#!/bin/bash

SERVICE=$1
OPERATION=$2
PERCENTAGE=$3

if [[ -z $SERVICE ]]; then
  echo "SERVICE must be set"
  exit 0
fi

if [[ -z $OPEATION ]]; then
  echo "OPERATION must be set"
  exit 0
fi

if [[ -z $PERCENTAGE ]]; then
  echo "PERCENTAGE must be set"
  exit 0
fi

file="ms-${SERVICE}-${OPERATION}.yaml"
sed 's/SERVICE/'${SERVICE}'/g' $file | \
sed 's/OPERATION/'${OPERATION}'/g' | \
sed 's/PERCENTAGE/'${PERCENTAGE}'/g' | \
kubectl apply -f -

echo "SERVICE_NAME=${SERVICE}-${OPERATION}"
echo "PERCENTAGE=${PERCENTAGE}"
echo "Abort injection done"
