AWS ECS Exec Action
===================

This GitHub Action allows performing the equivilant of `aws ecs run-task`
against an ECS task-definition.

This action expects AWS credentials to have already been initialized.
See: https://github.com/aws-actions/configure-aws-credentials

Usage
-----

```yaml
  - name: Configure AWS Credentials
    uses: aws-actions/configure-aws-credentials@v1
    with:
      aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
      aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
      aws-region: us-east-2
      role-to-assume: ${{ secrets.AWS_ROLE_TO_ASSUME }}
      role-external-id: ${{ secrets.AWS_ROLE_EXTERNAL_ID }}
      role-duration-seconds: 1200
      role-session-name: MySessionName
  - name: Execute my ECS Task
    uses: aplaceformom/aws-ecs-exec-action@master
    with:
      task-name: my-ecs-task
      wait: true
      timeout: 600
```

Inputs
------

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

### debug ###
Enable debugging
- required: false
- default: false
