FROM amazon/aws-cli

WORKDIR /app
COPY entrypoint.sh /entrypoint.sh
COPY ecs-exec .

ENTRYPOINT ["/entrypoint.sh"]
