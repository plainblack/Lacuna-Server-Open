#!/bin/bash
export PATH=/data/apps/bin:$PATH
cd /data/Lacuna-Server/bin
perl trickle_essentia_veins.pl
perl determine_lottery_winner.pl
perl alert_inactive_users.pl
perl diablotin/send_attack.pl --randomize
#perl saben/send_attack.pl --randomize

