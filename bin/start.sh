perl generate_docs.pl > /dev/null
memcached -d -u nobody -m 512
plackup --env prod --server Plack::Handler::Standalone --max-workers=10 --port 80 lacuna.psgi
