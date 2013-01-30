#!/bin/bash
export PATH=/data/apps/bin:$PATH
cd /data/Lacuna-Server/bin
perl tick_planets.pl >>/var/log/tick_planets.log 2>>/var/log/tick_planets.log
perl summarize_server.pl >>/var/log/run_two_hourly.log 2>>/var/log/run_two_hourly.log

