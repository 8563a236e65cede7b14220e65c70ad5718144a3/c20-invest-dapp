#!/usr/bin/env bash

# Build base testing and development
# image
docker image build -t contract_tester -f docker/Dockerfile .
rm -rf run
mkdir run