#!/bin/bash
nginx -s quit
sleep 1
nginx -c /data/Lacuna-Server/etc/nginx.conf

