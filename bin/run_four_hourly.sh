#!/bin/bash
export PATH=/data/apps/bin:$PATH
cd /data/Lacuna-Server/bin
perl summarize_spies.pl >>/var/log/four_hourly.log 2>>/var/log/four_hourly.log

