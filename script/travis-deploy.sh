#!/bin/bash
# Deploy to staging on master merges (not PRs)

set -e

# Don't deploy on PRs
if [ "$TRAVIS_PULL_REQUEST" != "false" ]; then
  exit 0
fi

if [ "$TRAVIS_BRANCH" == "master" ]; then
  # Deploy to staging on a merge to master
  docker login -e="$DOCKER_EMAIL" -u="$DOCKER_USERNAME" -p="$DOCKER_PASSWORD" quay.io

  #TODO: Once we actually have multiple version to support, we will need a strategy
  #      to figure out how we will build multiple versions from different branches.
  docker push quay.io/aptible/rabbitmq:3.5
fi
