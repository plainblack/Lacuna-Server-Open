#!/bin/bash
export PATH=/data/apps/bin:$PATH
cd /data/Lacuna-Server/bin
perl generate_docs.pl > /dev/null
memcached -d -u nobody -m 512
plackup --port 5001 --workers 1 --user nobody --group nobody deploy.psgi &
start_server --port 5000 -- starman --user nobody --group nobody --workers 10 --preload-app lacuna.psgi &
nginx -c /data/Lacuna-Server/etc/nginx.conf

