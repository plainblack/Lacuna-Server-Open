perl generate_docs.pl > /dev/null
memcached -d -u nobody -m 512
starman --preload-app --workers 10 --port 5000 lacuna.psgi
