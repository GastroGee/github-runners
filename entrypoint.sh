#!/usr/bin/dumb-init /bin/bash

ORG=<github_organization>

### deregister_runner removes the runner from the Github registry and cleans the workdir
function deregister_runner {
  ACCESS_TOKEN=$(</local/access-token.txt)

  echo "Get Runner Deregistration Token"
  CURL="$(curl -fsX POST -H "Authorization: token ${ACCESS_TOKEN}" \
  "https://api.github.com/orgs/$org/actions/runners/remove-token")"
  if [ $? -ne 0 ]; then
    echo "curl failed"
    exit 1
  fi
  TOKEN="$(printf '%s\n' "$CURL" | jq -r '.token')"

  echo "Deregistering runner"
  /actions-runner/config.sh remove --token "${TOKEN}"

  echo "Removing workdir contents"
  rm -rf /home/github-runner/*
}

### register_runner configures the runner with the Github registry
function register_runner {
  ACCESS_TOKEN=$(</local/access-token.txt)

  echo "Get Runner Registration Token"
  CURL="$(curl -fsX POST -H "Authorization: token ${ACCESS_TOKEN}" \
  "https://api.github.com/orgs/${ORG}/actions/runners/registration-token")"
  if [ $? -ne 0 ]; then
    echo "curl failed"
    exit 1
  fi
  TOKEN="$(printf '%s\n' "$CURL" | jq -r '.token')"

  echo "Registering the Runner"
  /actions-runner/config.sh \
      --disableupdate \
      --ephemeral \
      --labels "${LABELS}" \
      --name "${NOMAD_ALLOC_ID}" \
      --replace \
      --runnergroup "Default" \
      --token "${TOKEN}" \
      --unattended \
      --url "https://github.com/${ORG}" \
      --work "/home/github-runner"
}

export PATH=$PATH:/actions-runner
export RUNNER_ALLOW_RUNASROOT=1

### Conditionally enable debugging
if [[ $DEBUG ]]; then
  set -xv
fi

### Register the Github Runner
register_runner

### Ensure we deregister the Github runner
trap 'deregister_runner' SIGINT SIGQUIT SIGTERM

### Launch the Github Runner
./bin/Runner.Listener run --disableupdate --ephemeral

### Deregister the Github runner
deregister_runner

exit 0
