#!/bin/bash

GITHUB_TOKEN=$1
REPO=$2
EVENT_TYPE=$3
MAX_RETRIES=5
POLL_INTERVAL=60
RETRY_COUNT=0
API_URL="https://api.github.com/repos/${REPO}/actions/runs?event=${EVENT_TYPE}"

echo "Checking workflow status for ${REPO}..."
echo "URL: ${API_URL}"

while true; do
  # Get the latest workflow run status for the specified event type
  RESPONSE=$(curl -s -H "Authorization: token $GITHUB_TOKEN" "$API_URL")

  # Check if the API call was successful
  if [ $? -ne 0 ]; then
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
      echo "API call failed after $MAX_RETRIES attempts."
      exit 1
    else
      echo "API call failed. Retrying ($RETRY_COUNT/$MAX_RETRIES)..."
      sleep 5
      continue
    fi
  fi

  # Get the current time
  current_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # Find the most recent workflow run based on the timestamp
  latest_run=$(echo "${RESPONSE}" | jq '.workflow_runs | sort_by(.created_at) | last')

  # Extract relevant information
  created_at=$(echo "${latest_run}" | jq -r '.created_at')
  status=$(echo "${latest_run}" | jq -r '.status')
  conclusion=$(echo "${latest_run}" | jq -r '.conclusion')

  # Compare the created_at timestamp with the current time
  if [[ "$created_at" < "$current_time" ]]; then
    # Poll up to 5 times to check for an in_progress status of the most recently submitted.
    # Once it finds an in_progress workflow, it will keep polling until the workflow is completed successfully or failed.
    if [ "${status}" == "in_progress" ]; then
      workflow_id=$(echo "${latest_run}" | jq -r '.id')
      echo "Workflow ID is: ${workflow_id}"
      echo "Workflow in progress for ${REPO}."

      while [ "${status}" == "in_progress" ]; do
        sleep "$POLL_INTERVAL"
        RESPONSE=$(curl -s -H "Authorization: token $GITHUB_TOKEN" "$API_URL")
        latest_run=$(echo "${RESPONSE}" | jq '.workflow_runs | sort_by(.created_at) | last')
        status=$(echo "${latest_run}" | jq -r '.status')
        conclusion=$(echo "${latest_run}" | jq -r '.conclusion')
      done

      if [ "${status}" == "completed" ]; then
        if [ "${conclusion}" == "success" ]; then
          echo "Workflow completed successfully for ${REPO}."
          exit 0
        else
          echo "Workflow failed for ${REPO}."
          exit 1
        fi
      fi
    else
      echo "No in-progress workflow found for ${REPO}. Waiting for $POLL_INTERVAL seconds..."
    fi
  else
    echo "No recent workflow runs found."
  fi

  sleep "$POLL_INTERVAL"
done