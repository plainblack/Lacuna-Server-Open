perl generate_docs.pl > /dev/null
memcached -d -u nobody -m 512
#starman --preload-app --workers 10 --port 5000 lacuna.psgi
start_server --port 5000 -- starman --workers 10 --preload-app lacuna.psgi
nginx -c /data/Lacuna-Server/etc/nginx.conf

