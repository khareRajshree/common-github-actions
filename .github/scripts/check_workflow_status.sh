#!/bin/bash

GITHUB_TOKEN=$1
REPO=$2
EVENT_TYPE=$3
MAX_RETRIES=5
POLL_INTERVAL=60
RETRY_COUNT=0
API_URL="https://api.github.com/repos/${REPO}/actions/runs?event=${EVENT_TYPE}"
latest_workflow_id=""

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

  STATUS=$(echo "${RESPONSE}" | jq -r '.workflow_runs[0].status')
  CONCLUSION=$(echo "${RESPONSE}" | jq -r '.workflow_runs[0].conclusion')
  WORKFLOW_ID=$(echo "${RESPONSE}" | jq -r '.workflow_runs[0].id')

  # Check if the workflow ID is different from the last detected workflow ID
  if [ "$WORKFLOW_ID" != "$LATEST_WORKFLOW_ID" ]; then
    LATEST_WORKFLOW_ID="$WORKFLOW_ID"
    echo "New workflow detected. ID: ${WORKFLOW_ID}"
    echo "verify if its from the same parent dispatch event and update the workflow ID"
  fi

  # Poll up to 5 times to check for an in_progress status of the most recently submitted.
  # Once it finds an in_progress workflow, it will keep polling until the workflow is completed successfully or failed.
  if [ "${STATUS}" == "in_progress" ]; then
    echo "Workflow in progress for ${REPO}."

    while [ "${STATUS}" == "in_progress" ]; do
      sleep "$POLL_INTERVAL"
      RESPONSE=$(curl -s -H "Authorization: token $GITHUB_TOKEN" "$API_URL")
      STATUS=$(echo "${RESPONSE}" | jq -r '.workflow_runs[0].status')
      CONCLUSION=$(echo "${RESPONSE}" | jq -r '.workflow_runs[0].conclusion')
    done

    if [ "${STATUS}" == "completed" ]; then
      if [ "${CONCLUSION}" == "success" ]; then
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

  sleep "$POLL_INTERVAL"
done