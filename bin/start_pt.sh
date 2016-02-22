#!/bin/bash
export PATH=/data/apps/bin:$PATH
cd /data/Lacuna-Server/bin
perl generate_docs.pl > /dev/null
memcached -d -u nobody -m 512
fuser -k 5002/tcp

start_server --port 5002 -- starman --user nobody --group nobody --workers 3 --preload-app lacuna.psgi &

service nginx start

