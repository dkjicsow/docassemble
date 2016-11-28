#!/bin/bash

export DA_CONFIG_FILE=/usr/share/docassemble/config/config.yml

source /dev/stdin < <(su -c "source /usr/share/docassemble/local/bin/activate && python -m docassemble.base.read_config $DA_CONFIG_FILE" www-data)

if [ "${S3ENABLE:-null}" == "null" ] && [ "${S3BUCKET:-null}" != "null" ]; then
    export S3ENABLE=true
fi

if [ "${S3ENABLE:-null}" == "true" ] && [ "${S3BUCKET:-null}" != "null" ] && [ "${S3ACCESSKEY:-null}" != "null" ] && [ "${S3SECRETACCESSKEY:-null}" != "null" ]; then
    export AWS_ACCESS_KEY_ID=$S3ACCESSKEY
    export AWS_SECRET_ACCESS_KEY=$S3SECRETACCESSKEY
fi

function stopfunc {
    redis-cli shutdown
    echo backing up redis
    if [ "${S3ENABLE:-false}" == "true" ]; then
	s3cmd -q put "/var/lib/redis/dump.rdb" s3://${S3BUCKET}/redis.rdb
    fi
    exit 0
}

trap stopfunc SIGINT SIGTERM

redis-server /etc/redis/redis.conf &
wait %1
