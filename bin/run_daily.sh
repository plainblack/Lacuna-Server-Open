#!/bin/bash
export PATH=/data/apps/bin:$PATH
cd /data/Lacuna-Server/bin
perl trickle_essentia_veins.pl
perl determine_lottery_winner.pl
perl alert_inactive_users.pl
perl rotate_taxes_paid.pl
perl diablotin/send_attack.pl&
perl saben/send_attack.pl&
perl clean_up_mail.pl
perl record_rpc.pl
perl util/check_spy_count.pl &
