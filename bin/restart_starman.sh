#!/bin/bash
export PATH=/data/apps/bin:$PATH
cd /data/Lacuna-Server/bin
perl generate_docs.pl > /dev/null
killall -HUP start_server
