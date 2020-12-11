#!/bin/bash

cd ~/github/ms-http-demo/examples/kube/
files=$(ls ./ | grep "^ms-.*\.yaml$")
for f in $files; do
    kubectl delete -f $f
done
