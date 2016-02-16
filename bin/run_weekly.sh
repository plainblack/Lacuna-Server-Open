#!/bin/bash
export PATH=/data/apps/bin:$PATH
cd /data/Lacuna-Server-Open/bin
perl weekly_medals.pl >> /tmp/weekly_medals.log 2>> /tmp/weekly_medals.log
perl trelvestian/reset_essentia_veins.pl >> /tmp/weekly.log 2>> /tmp/weekly.log
perl clean_up_battle_log.pl >> /tmp/weekly.log 2>> /tmp/weekly.log
