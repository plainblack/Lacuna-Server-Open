. dataapps.sh

cp dataapps.sh /etc/profile.d/

yum -y install ncurses-devel gcc make glibc-devel gcc-c++ zlib-devel openssl-devel java sendmail expat expat-devel
service sendmail start
rpm -ivh *.rpm

cd libxml2-2.7.7
./configure --prefix=/data/apps
make
make install
cd ..

cd pcre-8.33
./configure --prefix=/data/apps
make
make install
cd ..

cd nginx-0.7.67
./configure --prefix=/data/apps --with-pcre=../pcre-8.33 --with-http_ssl_module --with-openssl=../openssl-1.0.0c
make
make install
cd ..

cd perl-5.12.1
./Configure -Dprefix=/data/apps -des
make
make install
cd ..

cd libevent-1.4.14b-stable
./configure --prefix=/data/apps
make
make install
cd ..

cd memcached-1.4.5
./configure --prefix=/data/apps
make
make install
cd ..

cpan App::cpanminus


