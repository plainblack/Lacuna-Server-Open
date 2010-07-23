#!/bin/bash
export PATH=/data/apps/bin:$PATH
cd /data/Lacuna-Server/bin
perl hourly_maintenance.pl
perl generate_news_feeds.pl
perl sumarize_server.pl

