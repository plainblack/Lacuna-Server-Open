#!/bin/bash
export PATH=/data/apps/bin:$PATH
cd /data/Lacuna-Server/bin
perl generate_docs.pl > /dev/null
memcached -d -u nobody -m 512
fuser -k 5000/tcp
fuser -k 5001/tcp

start_server --port 5000 -- starman --user nobody --group nobody --workers 3 --preload-app lacuna.psgi &
start_server --port 5001 -- starman --workers 1 --user nobody --group nobody --preload-app deploy.psgi &

service nginx start

