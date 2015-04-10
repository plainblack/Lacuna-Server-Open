#!/bin/bash
export PATH=/data/apps/bin:$PATH
touch /tmp/daily.log
cd /data/Lacuna-Server/bin
perl trickle_essentia_veins.pl >> /tmp/daily.log 2>> /tmp/daily.log
perl determine_lottery_winner.pl >> /tmp/daily.log 2>> /tmp/daily.log
perl alert_inactive_users.pl >> /tmp/daily.log 2>> /tmp/daily.log
perl rotate_taxes_paid.pl >> /tmp/daily.log 2>> /tmp/daily.log
perl clean_up_mail.pl >> /tmp/daily.log 2>> /tmp/daily.log
perl record_rpc.pl >> /tmp/daily.log 2>> /tmp/daily.log
perl util/check_spy_count.pl --burn >> /tmp/daily.log 2>> /tmp/daily.log
