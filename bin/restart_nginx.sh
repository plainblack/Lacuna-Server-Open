#!bin/bash
nginx -s quit
sleep 1
nginx -c /data/apps/conf/lacuna.conf

