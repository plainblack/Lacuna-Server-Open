#!/bin/bash
export PATH=/data/apps/bin:$PATH
cd /data/Lacuna-Server/bin
start_server --port 80 -- starman --workers 7 --user nobody --group nobody --preload-app lacuna.psgi &

