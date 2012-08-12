#!/bin/bash
export PATH=/data/apps/bin:$PATH
cd /data/Lacuna-Server/bin
perl clean_up_empires.pl >>/tmp/hourly.log 2>>/tmp/hourly.log
perl sanitize_ss.pl >>/tmp/hourly.log 2>>/tmp/hourly.log
# perl summarize_server.pl >>/tmp/hourly.log 2>>/tmp/hourly.log
perl summarize_economy.pl >>/tmp/hourly.log 2>>/tmp/hourly.log
perl generate_news_feeds.pl >>/tmp/news_feeds.log 2>>/tmp/news_feeds.log
perl tick_spies.pl >>/tmp/hourly.log 2>>/tmp/hourly.log
perl tick_parliament.pl >>/tmp/hourly.log 2>>/tmp/hourly.log
perl add_missions.pl >>/tmp/hourly.log 2>>/tmp/hourly.log
perl clean_up_market.pl >>/tmp/hourly.log 2>>/tmp/hourly.log
perl trelvestian/hourly_update.pl >>/tmp/hourly.log 2>>/tmp/hourly.log
perl trelvestian/send_attack.pl >>/tmp/hourly.log 2>>/tmp/hourly.log &
perl diablotin/hourly_update.pl >>/tmp/hourly.log 2>>/tmp/hourly.log
perl saben/hourly_update.pl >>/tmp/hourly.log 2>>/tmp/hourly.log
perl delambert/hourly_update.pl >>/tmp/hourly.log 2>>/tmp/hourly.log
#perl check_for_total_victory.pl >>/tmp/hourly.log 2>>/tmp/hourly.log
