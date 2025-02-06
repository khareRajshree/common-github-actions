#!/bin/bash

# URL to fetch the repository list
REPO_LIST_URL="https://raw.githubusercontent.com/khareRajshree/common-github-actions/main/.github/configs/dell-libraries-list.txt"

# GitHub access token
GITHUB_TOKEN="${1}"
POLL_INTERVAL=60  # Check every 60 seconds

# Fetch the repository list
repos=$(curl -s "${REPO_LIST_URL}")

for repo in "${repos[@]}"; do
  echo "Checking workflow status for $repo..."

  while true; do
    # Get the latest workflow run status for the specified event type
    response=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
      "https://api.github.com/repos/${repo}/actions/runs?event=repository_dispatch")

    # Parse the JSON response to get the workflow run status
    status=$(echo "${response}" | jq -r '.workflow_runs[0].status')
    conclusion=$(echo "${response}" | jq -r '.workflow_runs[0].conclusion')

    if [ "${status}" == "completed" ]; then
      if [ "${conclusion}" == "success" ]; then
        echo "Workflow completed successfully for $repo."
        break
      else
        echo "Workflow failed for $repo."
        exit 1
      fi
    else
      echo "Workflow not completed yet for $repo. Waiting for $POLL_INTERVAL seconds..."
      sleep "$POLL_INTERVAL"
    fi
  done
done