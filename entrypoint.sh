#!/bin/sh
set -e
export AWS_ACCESS_KEY_ID="${INPUT_AWS_ACCESS_KEY_ID}"
export AWS_SECRET_ACCESS_KEY="${INPUT_AWS_SECRET_ACCESS_KEY}"
export AWS_REGION="${INPUT_AWS_REGION}"

if ! test -z "${INPUT_AWS_ROLE_ARN}"; then
	set --
	if ! test -z "${INPUT_AWS_EXTERNAL_ID}"; then
		set -- --external-id "${INPUT_AWS_EXTERNAL_ID}"
	fi
	AWS_ACCESS_JSON="$(aws sts assume-role "${@}" \
			--role-arn "${INPUT_AWS_ROLE_ARN}" \
			--role-session-name 'GitHub ECS Exec Action')"
	export AWS_ACCESS_KEY_ID="$(echo "${AWS_ACCESS_JSON}"|jq '.Credentials.AccessKeyId')"
	export AWS_SECERT_ACCESS_KEY="$(echo "${AWS_ACCESS_JSON}"|jq '.Credentials.SecretAccessKey')"
	export AWS_SESSION_TOKEN="$(echo "${AWS_ACCESS_JSON}"|jq '.Credentials.SessionToken')"
fi
WAIT=
! "${INPUT_WAIT}" || WAIT='--wait'
exec /app/ecs-exec --timeout "${INPUT_TIMEOUT}" ${WAIT} --cluster "${INPUT_CLUSTER}" "${INPUT_TASK_NAME}"
