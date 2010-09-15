#!/bin/bash
export PATH=/data/apps/bin:$PATH
cd /data/Lacuna-Server/bin
nginx -s quit
sleep 1
nginx -c /data/Lacuna-Server/etc/nginx.conf

