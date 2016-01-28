# This creates some data-only containers.
#
# tle-mysql-data contains the mysql database. This ensures that
# the database is persistent even if the container using it
# is stopped and removed.
#
# tle-captcha-data contains a shared volume since both tle-server
# and tle-nginx will need to share it.
#
# If for any reason you do want to delete a container be sure
# to first stop and remove all containers with a reference to
# the data container and then do the following command.
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
docker create --name tle-captcha-data -v /data/captcha lacuna/tle-captcha-data

