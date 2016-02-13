docker run -it -p ${TLE_SERVER_LISTEN:-0.0.0.0}:${TLE_SERVER_PORT:-8000}:80 	\
  --name=tle-nginx 					\
  --net=tle-network 					\
  -v ${PWD}/../etc/nginx.conf:/etc/nginx/nginx.conf:ro 	\
  --volumes-from tle-captcha-data       		\
  -v ${PWD}/../etc:/data/Lacuna-Server/etc 		\
  -v ${PWD}/../var:/data/Lacuna-Server/var 		\
  -v ${PWD}/../var/www/public/api/api.css:/data/Lacuna-Server/var/www/public/api/api.css \
  -d lacuna/tle-nginx

