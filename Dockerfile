FROM amazon/aws-cli

WORKDIR /app
COPY entrypoint.sh /entrypoint.sh
COPY ecs-exec .
RUN yum install jq -y

ENTRYPOINT ["/entrypoint.sh"]
