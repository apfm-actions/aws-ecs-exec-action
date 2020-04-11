#!/bin/sh
set -e
export AWS_ACCESS_KEY_ID="${INPUT_AWS_ACCESS_KEY_ID}"
export AWS_SECRET_ACCESS_KEY="${INPUT_AWS_SECRET_ACCESS_KEY}"
export AWS_REGION="us-west-2"
WAIT=
! "${INPUT_WAIT}" || WAIT='--wait'
exec /app/ecs-exec --timeout "${INPUT_TIMEOUT}" ${WAIT} --cluster "${INPUT_CLUSTER}" "${INPUT_TASK_NAME}"
