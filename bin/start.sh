memcached -d -u nobody -m 512
plackup --env prod --server Plack::Server::Standalone::Prefork --port 80 lacuna.psgi
