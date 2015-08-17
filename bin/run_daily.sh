#!/bin/bash
export PATH=/data/apps/bin:$PATH
touch /tmp/daily.log
cd /data/Lacuna-Server/bin

# redirect everything.
exec >> /tmp/daily.log
exec 2>&1

perl trickle_essentia_veins.pl
perl determine_lottery_winner.pl
perl alert_inactive_users.pl
perl rotate_taxes_paid.pl
perl clean_up_mail.pl
perl record_rpc.pl
perl util/check_spy_count.pl --burn
perl check_starter_zones.pl
perl clean_up_sitterauths.pl
