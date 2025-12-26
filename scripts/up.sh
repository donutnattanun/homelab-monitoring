#!/usr/bin/env bash
set -e

echo ">> Start local infar"
docker-compose up -d

echo ">> Containers"
docker ps
