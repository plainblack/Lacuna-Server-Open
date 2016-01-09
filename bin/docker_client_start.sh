#!/bin/bash

# This script is run within a docker container
# (see docker_run.sh) to start up the TLE server

service mysqld start
cd /data/Lacuna-Server/etc
cp lacuna.conf.docker lacuna.conf
cp log4perl.conf.docker log4perl.conf
cp nginx.conf.docker nginx.conf
cd /data/Lacuna-Server/bin
./start_beanstalk.sh
./start_memcached.sh
./startdev.sh

