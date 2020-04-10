AWS ECS Exec Action
===================

This GitHub Action allows performing the equivilant of `aws ecs run-task`
against an ECS task-definition.

Usage
-----

```yaml
- uses: aplaceformom/aws-ecs-exec-action@master
  with:
    aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
    aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    aws-region: us-west-2
  task-name: my-ecs-task
  wait: true
  timeout: 600
```

Inputs
------

### aws-access-key-id ###
The `AWS_ACCESS_KEY_ID`
- required: true
- default: N/A

### aws-secret-access-key ###
The `AWS_SECRET_ACCESS_KEY`
- required: true
- default: N/A

### aws-region ###
The `AWS_REGION`
- required: true
- default: us-west-2

### task-name ###
The ECS task definition name.
- required: true
    default: N/A

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
