#!/bin/bash
export PATH=/data/apps/bin:$PATH
cd /data/Lacuna-Server/bin
perl tick_planets.pl >>/var/log/tick_planets.log 2>>/var/log/tick_planets.log &
perl tick_spies.pl >>/tmp/tick_spies.log 2>>/tmp/tick_spies.log &
perl summarize_server.pl >>/var/log/run_two_hourly.log 2>>/var/log/run_two_hourly.log
# perl saben/send_attack.pl >>/tmp/attack_saben.log 2>>/tmp/attack_saben.log &
# perl diablotin/send_attack.pl >>/tmp/attack_diab.log 2>>/tmp/attack_diab.log &
