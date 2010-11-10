#!/bin/bash
export PATH=/data/apps/bin:$PATH
cd /data/Lacuna-Server/bin
perl weekly_medals.pl
perl saben/send_attack.pl

