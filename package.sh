#!/bin/bash

for file in `ls charts`; do
  helm package charts/$file --destination docs
done

helm repo index docs --url https://revelrylabs.github.io/helm-charts
