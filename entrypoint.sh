#!/bin/sh
set -e

error() { echo "error: $*" >&2; }
die() { error "$*"; exit 1; }
toupper() { echo "$*" | tr '[a-z]' '[A-Z]'; }
tolower() { echo "$*" | tr '[A-Z]' '[a-z]'; }

aws_account_id() { aws --output=json sts get-caller-identity | jq -rc '.["Account"]'; }
aws_region() {
	if test -z "${INPUT_REGION}"; then
		aws configure list | awk '$1 ~ /^region$/{print$2}'
	else
		echo "${INPUT_REGION}"
	fi
}
aws_policy_arn()
{
	test -n "${1}" || return 0
	case "${1}" in
	(arn:aws:*)	echo "${1}";;
	(*)		echo "arn:aws:iam::$(aws_account_id):policy/${1}"
	esac
}
aws_role_arn()
{
	test -n "${1}" || return 0
	test != 'null' || return 0
	case "${1}" in
	(arn:aws:*)	echo "${1}";;
	(*)		echo "arn:aws:iam::$(aws_account_id):role/${1}"
	esac
}


strip() { printf '%s' "$*"|sed -e 's/^[[:space:]]//;s/[[:space:]]$//;'; }
split()
{
	__split_delim="${1}"
	shift
	for __split_arg; do
		while ! test -z "${__split_arg}"; do
			/usr/bin/printf '"%s"\n' "${__split_arg%%,*}"
			test "${__split_arg#*,}" != "${__split_arg}" || break
			__split_arg="${__split_arg#*,}"
		done
		shift
	done
}

# $@: List of Environment variable names to produce AWS JSON Env output for
environment()
{
	eval set -- $(split ',' "${@}")
	_env_string=
	for _env_key; do
		eval _env_val="$(strip "\${${_env_key}}")"
		_env_string="${_env_string},$(printf '{ "name": "%s", "value": "%s" }' "${_env_key}" "${_env_val}")"
	done
	echo "${_env_string#,}"
}

##
# $@: List of Environment variable names to produce AWS JSON Secrets output for
secrets()
{
	set +x
	eval set -- $(split ',' "${@}")
	_secret_string=
	for _secret_key; do
		eval _secret_val="$(strip "\${${_secret_key}}")"
		case "${_secret_val}" in
		(arn:aws:*) # ARN, do nothing
			;;

		(key/) # KMS
			_secret_val="arn:aws:kms:$(aws_region):$(aws_account_id):${_secret_val}"
			;;

		(parameter/*) # SSM
			_secret_val="arn:aws:ssm:$(aws_region):$(aws_account_id):${_secret_val}"
			;;
		(/*) # SSM
			_secret_val="arn:aws:ssm:$(aws_region):$(aws_account_id):parameter${_secret_val}"
			;;

		(*) # Secrets Manager
			_secret_val="arn:aws:secretsmanager:$(aws_region):$(aws_account_id):secret:${_secret_val}"
			;;
		esac
		_secret_string="${_secret_string},$(printf '{ "name": "%s", "valueFrom": "%s" }' "${_secret_key}" "${_secret_val}")"
	done
	echo "${_secret_string#,}"
	test "${INPUT_DEBUG}" != true || set -x
}
aws_task_definition()
{
	test "${INPUT_COMMAND}" != 'null' || INPUT_COMMAND=
	sed -e 's/^	//'<<EOF
	[{
		"name": "${INPUT_NAME}",
		"image": "${INPUT_IMAGE}",
		"cpu": ${INPUT_CPU},
		"memory": ${INPUT_MEMORY},
		"command": ${INPUT_COMMAND:=[]},
		"essential": true,
		"environment": [$(environment "${INPUT_ENVIRONMENT}")],
		"secrets": [$(secrets "${INPUT_SECRETS}")],
		"logConfiguration": {
			"logDriver": "awslogs",
			"options": {
				"awslogs-create-group": "true",
				"awslogs-region": "$(aws_region)",
				"awslogs-group": "${INPUT_PROJECT}",
				"awslogs-stream-prefix": "ecs"
			}
		}
	}]
EOF
}

task_param()
{
	case "${1}" in
	(task_role)
		echo "${CURRENT_TASK_JSON}"|jq -rc '.taskDefinition.taskRoleArn' >/dev/null 2>&1
		;;
	(exec_role)
		echo "${CURRENT_TASK_JSON}"|jq -rc '.taskDefinition.executionRoleArn'
		;;
	(project)
		echo "${CURRENT_TASK_JSON}"|jq -rc '.taskDefinition.containerDefinitions[0]["logConfiguration"]["options"]["awslogs-group"]'
		;;
	(*)	echo "${CURRENT_TASK_JSON}"|jq -rc ".taskDefinition.containerDefinitions[0].${1}"
		;;
	esac
}

if ! test -z "${INPUT_AWS_ROLE_ARN}"; then
	set --
	if ! test -z "${INPUT_AWS_EXTERNAL_ID}"; then
		set -- --external-id "${INPUT_AWS_EXTERNAL_ID}"
	fi
	AWS_ACCESS_JSON="$(aws sts assume-role "${@}" \
		--role-arn "${INPUT_AWS_ROLE_ARN}" \
		--role-session-name 'aws-ecs-exec-action')"

	export AWS_ACCESS_KEY_ID="$(echo "${AWS_ACCESS_JSON}"|jq -r '.Credentials.AccessKeyId')"
	export AWS_SECRET_ACCESS_KEY="$(echo "${AWS_ACCESS_JSON}"|jq -r '.Credentials.SecretAccessKey')"
	export AWS_SESSION_TOKEN="$(echo "${AWS_ACCESS_JSON}"|jq -r '.Credentials.SessionToken')"
fi

ECS_EXEC_DEBUG=
if test "${INPUT_DEBUG}" = 'true'; then
	ECS_EXEC_DEBUG='--debug'
	set -x
fi

if test -z "${INPUT_NAME}"; then
	INPUT_NAME="${GITHUB_REPOSITORY##*/}"
else
	INPUT_NAME="${GITHUB_REPOSITORY##*/}-${INPUT_NAME}"
fi

! test -z "${INPUT_TASK_NAME}" || INPUT_TASK_NAME="${INPUT_NAME}"

INPUT_EXEC_ROLE="$(aws_role_arn "${INPUT_EXEC_ROLE}")"
INPUT_TASK_ROLE="$(aws_role_arn "${INPUT_TASK_ROLE}")"

CURRENT_TASK_JSON="$(aws ecs describe-task-definition --task-definition "${INPUT_NAME}" 2> /dev/null || echo '{}')"

# Register a variation of the task if any parameters are specified
UPDATE_TASK='false'
for param in name image cpu memory command exec_role task_role; do
	eval new_param_val="\${INPUT_$(toupper "${param}")}"
	old_param_val="$(task_param "${param}")"
	if test -z "${new_param_val}"; then
		eval "INPUT_$(toupper "${param}")='${old_param_val}'"
	elif test "${old_param_val}" = "${new_param_val}";then
		eval new_param_val="\${INPUT_$(toupper "${param}")}"
	else
		UPDATE_TASK='true'
	fi
done
test "[$(environment "${INPUT_ENVIRONMENT}")]" = "$(task_param 'environment')" || UPDATE_TASK='true'
test "[$(secrets "${INPUT_SECRETS}")]" = "$(task_param 'secrets')" || UPDATE_TASK='true'

if test -z "${INPUT_IMAGE}"; then
       INPUT_IMAGE="$(aws_account_id).dkr.ecr.$(aws_region).amazonaws.com/${GITHUB_REPOSITORY##*/}:${INPUT_VERSION}"
fi

if ${UPDATE_TASK}; then
	set -- \
		--family "${INPUT_NAME}" \
		--cpu "${INPUT_CPU}" \
		--memory "${INPUT_MEMORY}" \
		--requires-compatibilities 'FARGATE' \
		--network-mode 'awsvpc' \
		--execution-role-arn "$(aws_role_arn "${INPUT_EXEC_ROLE}")" \
		--container-definitions "$(aws_task_definition)"

	if ! test -z "${INPUT_TASK_ROLE}"; then
		set -- "${@}" --task-role-arn "$(aws_role_arn "${INPUT_TASK_ROLE}")"
	fi

	if ! test -z "${INPUT_TAGS}"; then
		set -- "${@}" --tags "${INPUT_TAGS}"
	fi

	aws ecs register-task-definition "${@}"
fi

ECS_EXEC_WAIT=
! "${INPUT_WAIT}" || ECS_EXEC_WAIT='--wait'
exec /app/ecs-exec ${ECS_EXEC_DEBUG} ${ECS_EXEC_WAIT} --timeout "${INPUT_TIMEOUT}" --cluster "${INPUT_CLUSTER:=default}" "${INPUT_TASK_NAME}"
