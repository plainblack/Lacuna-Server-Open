#!/usr/bin/bash

# This is a data-only container which holds the mysql database.
#
# This means that the mysql data will persist even if you stop or
# even delete the running TLE server.
#
# If for any reason you do want to delete the container be sure
# to first stop and remove all containers with a reference to
# the data container (docker_run.sh for example) and then do
# the folowing command.
#
#   $ docker rm -v tle-mysql-data
#
# This will ensure that you don't leave a 'dangling container' which
# will be difficult to remove and use up disk space.
#
# You only need to create a data-only container, you don't need to
# run it. This script will create it for you.
#
docker create --name tle-mysql-data arungupta/mysql-data-container

