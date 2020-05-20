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
      aws_role_arn: ${{ secrets.AWS_ROLE_TO_ASSUME }}
      aws_external_id: ${{ secrets.AWS_ROLE_EXTERNAL_ID }}
      task_name: my-ecs-task
      wait: true
      timeout: 600
```

Inputs
------

### task-name ###
The ECS task definition name.
- required: true
    default: N/A

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
