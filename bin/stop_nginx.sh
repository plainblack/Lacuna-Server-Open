#!/bin/bash
export PATH=/data/apps/bin:$PATH
cd /data/Lacuna-Server/bin
nginx -c /data/Lacuna-Server/etc/nginx.conf -s quit

