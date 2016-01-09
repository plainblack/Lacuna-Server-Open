# This script allows to you attach to the currently
# running TLE server (see docker_run.sh) and poke
# around etc.
#
# When you are done, and want to return to the host
# just use the command 'exit'.
#
# Note. you don't need to make changes to the code
# from within the docker container, you can do this
# from your host (since the lib,bin,etc,var directories
# are mapped from the host to the container).
#
docker exec -it tle-server bash
