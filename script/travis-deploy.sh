#!/bin/bash
# Deploy to quay.io on master merges (not PRs)

set -e

# Don't deploy on PRs
if [ "$TRAVIS_PULL_REQUEST" != "false" ]; then
  exit 0
fi

if [ "$TRAVIS_BRANCH" == "master" ]; then
  # Deploy to quay.io on a merge to master
  docker login -e="$DOCKER_EMAIL" -u="$DOCKER_USERNAME" -p="$DOCKER_PASSWORD" quay.io
  docker push quay.io/aptible/rabbitmq:latest
  docker push quay.io/aptible/rabbitmq:3.5
fi
