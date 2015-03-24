#!/bin/bash
export PATH=/data/apps/bin:$PATH
cd /data/Lacuna-Server/bin
perl clean_up_empires.pl >>/tmp/hourly.log 2>>/tmp/hourly.log
perl sanitize_ss.pl >>/tmp/hourly.log 2>>/tmp/hourly.log
perl summarize_economy.pl >>/tmp/hourly.log 2>>/tmp/hourly.log
perl generate_news_feeds.pl >>/tmp/news_feeds.log 2>>/tmp/news_feeds.log
perl tick_parliament.pl >>/tmp/hourly.log 2>>/tmp/hourly.log
perl add_missions.pl >>/tmp/hourly.log 2>>/tmp/hourly.log
perl clean_up_market.pl >>/tmp/hourly.log 2>>/tmp/hourly.log
perl jackpot/hourly_update.pl >>/tmp/hourly.log 2>>/tmp/hourly.log
perl trelvestian/hourly_update.pl >>/tmp/hourly.log 2>>/tmp/hourly.log
perl diablotin/hourly_update.pl >>/tmp/hourly.log 2>>/tmp/hourly.log
perl saben/hourly_update.pl >>/tmp/hourly.log 2>>/tmp/hourly.log
perl delambert/hourly_update.pl >>/tmp/hourly.log 2>>/tmp/hourly.log
perl cult/hourly_update.pl >>/tmp/hourly.log 2>>/tmp/hourly.log
perl tick_fissures.pl >>/tmp/tick_fissures.log 2>>/tmp/tick_fissures.log
perl test_weather.pl >>/tmp/test_weather.csv 2>/tmp/test_weather.log
perl trelvestian/send_attack.pl >>/tmp/attack_trel.log 2>>/tmp/attack_trel.log &
perl tick_stations.pl >>/tmp/hourly.log 2>>/tmp/hourly.log
