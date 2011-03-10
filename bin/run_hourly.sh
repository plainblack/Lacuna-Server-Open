#!/bin/bash
export PATH=/data/apps/bin:$PATH
cd /data/Lacuna-Server/bin
perl clean_up_empires.pl
perl tick_planets.pl
perl summarize_server.pl
perl summarize_economy.pl
perl generate_news_feeds.pl
perl tick_spies.pl
perl add_missions.pl
perl clean_up_market.pl
perl trelvestian/hourly_update.pl
perl trelvestian/send_attack.pl&
perl diablotin/hourly_update.pl
perl saben/hourly_update.pl
