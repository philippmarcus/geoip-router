#!/bin/bash

echo "Starting build of docker image..."
./docker_build.sh
echo "Finished build of docker image..."

echo "Invoking docker image..."
./docker_run.sh
