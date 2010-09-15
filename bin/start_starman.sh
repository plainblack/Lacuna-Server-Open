#!/bin/bash
export PATH=/data/apps/bin:$PATH
cd /data/Lacuna-Server/bin
start_server --port 80 -- starman --workers 10 --preload-app lacuna.psgi &

