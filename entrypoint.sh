#!/bin/sh
set -e
DEBUG=
if test "${INPUT_DEBUG}" = 'true'; then
	DEBUG='--debug'
       	set -x
fi

WAIT=
! "${INPUT_WAIT}" || WAIT='--wait'
exec /app/ecs-exec ${DEBUG} ${WAIT} --timeout "${INPUT_TIMEOUT}" --cluster "${INPUT_CLUSTER}" "${INPUT_TASK_NAME}"
