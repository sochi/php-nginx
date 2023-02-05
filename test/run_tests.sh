#!/usr/bin/env sh
apk --no-cache add curl
sleep 2
curl --silent --fail http://app:8080 | grep 'PHP 8'
