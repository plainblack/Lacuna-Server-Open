docker run                                          \
  --rm -it --name=tle-server                        \
  -p 0.0.0.0:5000:5000                              \
  --net=tle-network                                 \
  -v ${PWD}/../bin:/data/Lacuna-Server-Open/bin     \
  -v ${PWD}/../docs:/data/Lacuna-Server-Open/docs   \
  -v ${PWD}/../etc:/data/Lacuna-Server-Open/etc     \
  -v ${PWD}/../lib:/data/Lacuna-Server-Open/lib     \
  -v ${PWD}/../t:/data/Lacuna-Server-Open/t         \
  -v ${PWD}/../var:/data/Lacuna-Server-Open/var     \
  --volumes-from tle-captcha-data                   \
  -v ${PWD}/../var/www/public/api/api.css:/data/Lacuna-Server-Open/var/www/public/api/api.css \
  -e TLE_NO_MIDDLEWARE=1                            \
  lacuna/tle-server

