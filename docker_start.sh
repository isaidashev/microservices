#!/bin/bash
docker run -d --network=reddit --network-alias=post_db_new --network-alias=comment_db_new -v reddit_db:/data/db mongo:latest
docker run -d --network=reddit --network-alias=post_new -e POST_DATABASE_HOST="post_db_new" isaidashev/post:1.0
docker run -d --network=reddit --network-alias=comment_new -e COMMENT_DATABASE_HOST="comment_db_new" isaidashev/comment:1.0
docker run -d --network=reddit -p 9292:9292 -e POST_SERVICE_HOST="post_new" -e COMMENT_SERVICE_HOST="comment_new" isaidashev/ui:2.0
