#!/bin/bash
export PATH=/data/apps/bin:$PATH
cd /data/Lacuna-Server/bin
start_server --port 5001 -- starman --workers 1 --user nobody --group nobody --preload-app deploy.psgi &

