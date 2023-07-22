#!/bin/sh

eval $(ssh-agent)

ssh-add ./id_rsa

docker-compose -H ssh://user@127.0.0.1:22 up -d