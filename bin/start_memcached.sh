#!/bin/bash
export PATH=/data/apps/bin:$PATH
cd /data/Lacuna-Server-Open/bin
memcached -d -u nobody -m 1024

