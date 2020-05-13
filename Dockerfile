FROM amazon/aws-cli

RUN yum install jq -y

WORKDIR /app
COPY entrypoint.sh /entrypoint.sh
COPY ecs-exec .

ENTRYPOINT ["/entrypoint.sh"]
