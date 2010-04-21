#!bin/bash
nginx -s quit
sleep 1
nginx -c /usr/local/conf/lacuna.conf

