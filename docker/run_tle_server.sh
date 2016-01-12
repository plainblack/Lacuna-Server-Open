# This script runs the docker image that you have created locally
# by the use of the script 'docker_build.sh'.
#
# If you don't want the trouble of building it yourself, use the script
# 'docker_run_prebuilt.sh' which will download and run the pre-built
# image stored on docker hub. This is the recommended method.
#
# This container starts up your TLE web server. It maps the port 5000
# from the container to your host port 5000
#
# The container also maps your host directories 'bin','lib','etc' and
# 'var' to the container. This means you can edit the files in your
# host with an editor of your choice, and they will also save in
# the container. Note however that if you make changes to the code you
# will also need to restart the server in the container to make the
# changes live (./startdev.sh).
#
# You can use GIT as normal in your host to commit your changes.
#
# If you 'exit' this container then your server will stop and all data
# in the container will be lost. EXCEPT for the mysql data with is held
# in a separate data-only container 'tld-mysql-data'
#
echo 'This is your TLE server'
echo 'you should now run the following command to initialize it'
echo '  $ ./docker_client_start.sh
echo ''
echo 'At this point your TLE web server is running and monitoring'
echo 'the web requests.'
echo
echo 'If you make any changes to the code you need to restart the web'
echo 'server. You can do this with the following.
echo '  $ ctrl-c'
echo '  $ ./startdev.sh'
echo
docker run --rm -it -p 5000:5000 --name=tle-server -v ${PWD}/../bin:/data/Lacuna-Server/bin -v ${PWD}/../lib:/data/Lacuna-Server/lib -v ${PWD}/../etc:/data/Lacuna-Server/etc -v ${PWD}/../var:/data/Lacuna-Server/var icydee/tle-server /bin/bash
