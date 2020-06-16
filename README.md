AWS ECS Exec Action
===================

This [GitHub Action][GitHub Actions] allows performing the equivilant of
`aws ecs run-task` against an ECS task-definition.

This action expects AWS credentials to have already been initialized.

See also:
- https://help.github.com/en/actions
- https://github.com/apfm-actions
- https://github.com/aws-actions/configure-aws-credentials

Usage
-----

### Executing an existing task
```yaml
  - name: Configure AWS Credentials
    uses: aws-actions/configure-aws-credentials@v1
    with:
      aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
      aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
      aws-region: us-east-2
  - name: Execute my ECS Task
    uses: apfm-actions/aws-ecs-exec-action@master
    with:
      task_name: my-ecs-task
      aws_role_arn: ${{ secrets.AWS_ROLE_TO_ASSUME }}
      aws_external_id: ${{ secrets.AWS_ROLE_EXTERNAL_ID }}
      wait: true
      timeout: 600
```

### Defining a new task to execute
```yaml
  - name: Configure AWS Credentials
    uses: aws-actions/configure-aws-credentials@v1
    with:
      aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
      aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
      aws-region: us-east-2
  - name: Execute my ECS Task
    uses: apfm-actions/aws-ecs-exec-action@master
    with:
      project: 'examples'
      name: 'db-migration'
      image: 'myrepo.example.com/my-image'
      # image: 'my-dockerhub-image'
      version: 'latest'
      cpu: 256
      memory: 512
      command: '["/app/db-migration.sh"]'
      exec_role: 'ecsTaskExecutionRoleDefault'
      aws_role_arn: ${{ secrets.AWS_ROLE_TO_ASSUME }}
      aws_external_id: ${{ secrets.AWS_ROLE_EXTERNAL_ID }}
      wait: true
      timeout: 600
```


Inputs
------

### project
Project family this task is part of
- required: `true`

### name:
Optional name to append to generated task. This helps avoid conflicts with existing task names in the same workflow.
- required: `false`

### image
Docker image to use when creating a task definition
- required: `false`

### version
Version/Label of Docker image to use when creating a task definition
- default: `latest`

### command
Overide default container command
- required: `false`

### environment
Comma separated list of environment variable _names_ that should be exported to
the ECS container environment
- required: `false`

Example:
```
  - name: Execute my ECS Task
    uses: apfm-actions/aws-ecs-exec-action@master
    env:
      DB_ADDRESS: my-database.example.com
      DB_USER: admin
      DB_PASS: parameter/my/aws/ssm/password/path
    with:
      project: 'examples'
      image: 'my-dockerhub-image'
      environment: DB_ADDRESS,DB_USER
      secrets: DB_PASS
```

### secrets
Comma separated list of environment variable _names_ that should be exported to
the ECS container secrets. (See environment example)
- required: `false`

### cpu
CPU allocation (in micro-units)
- default: `256`

### memory
Memory allocation
- default: `512`

### exec_role
ECS Task Execution role to use when provisioning the ECS task (required when creating a new task definition)
- required: `true` _(when creating a new task)_

### task_role
ECS Task role the task should assume when running.
- required: `false`

### task-name ###
Optional name of existing task definition to execute.
- required: false

### cluster ###
The ECS cluster to execute the task on.
- required: false
- default: default

### wait ###
Whether to wait for the task to complete.  Normally launching of an ECS task is
asyncronous and the AWS API returns once it has scheduled the launching of the
task. If `wait` is set to true then this action will wait for the task to
finish using `aws ecs wait`.
- required: false
- default: true

### timeout ###
How long to wait when waiting for the ECS task to timeout. This sets the
aws-cli connection-read-timeout as the `aws ecs wait` does not support a
timeout itself.
- required: false
- default: 600

### aws-role-arn ###
Specify the ARN of a role to `sts:AssumeRole` to. (optional)

### aws-external-id ###
Supply an external-id when performing an `sts:AssumeRole`. This is an optional
parameter to `sts:AssumeRole`.

### debug ###
Enable debugging
- required: false
- default: false

[//]: # (The following are reference links used elsewhere in the document)

[Git]: https://git-scm.com/
[GitHub]: https://www.github.com
[GitHub Actions]: https://help.github.com/en/actions
[Terraform]: https://www.terraform.io/
[Docker]: https://www.docker.com
[Dockerfile]: https://docs.docker.com/engine/reference/builder/
