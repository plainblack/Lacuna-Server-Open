FROM centos:6

RUN yum install -y cpan wget tar gcc gcc-c++ zlib-devel openssl-devel expat expat-devel ncurses-devel
RUN yum install -y glibc-devel git mysql mysql-devel libxml2 libxml2-devel mysql-server gd gd-devel

RUN mkdir /downloads
RUN mkdir /data
RUN mkdir /data/apps
RUN mkdir /data/Lacuna-Server
RUN mkdir /data/Lacuna-Server/third_party

WORKDIR /downloads
RUN wget -q --output-document=perl-5.12.1.tar.gz http://www.cpan.org/src/5.0/perl-5.12.1.tar.gz
RUN tar xfz perl-5.12.1.tar.gz
RUN rm --interactive=never perl-5.12.1.tar.gz
WORKDIR perl-5.12.1
RUN ./Configure -Dprefix=/data/apps -des
RUN make
RUN make install
WORKDIR /downloads
RUN rm -rf perl-5.12.1

WORKDIR /downloads
RUN wget http://www.monkey.org/~provos/libevent-1.4.14b-stable.tar.gz
RUN tar xfz libevent-1.4.14b-stable.tar.gz
RUN rm --interactive=never libevent-1.4.14b-stable.tar.gz
WORKDIR libevent-1.4.14b-stable
RUN ./configure --prefix=/data/apps
RUN make
RUN make install
WORKDIR /downloads
RUN rm -rf libevent-1.4.14b-stable

WORKDIR /downloads
RUN wget http://memcached.googlecode.com/files/memcached-1.4.5.tar.gz
RUN tar xfz memcached-1.4.5.tar.gz
RUN rm --interactive=never memcached-1.4.5.tar.gz
WORKDIR memcached-1.4.5
RUN ./configure --prefix=/data/apps
RUN make
RUN make install
WORKDIR /downloads
RUN rm -rf memcached-1.4.5

WORKDIR /downloads
RUN wget ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-8.37.tar.gz
RUN tar xfz pcre-8.37.tar.gz
RUN rm --interactive=never pcre-8.37.tar.gz

WORKDIR /downloads
RUN wget http://openssl.org/source/openssl-1.0.0c.tar.gz
RUN tar xfz openssl-1.0.0c.tar.gz
RUN rm --interactive=never openssl-1.0.0c.tar.gz

WORKDIR /downloads
RUN wget http://nginx.org/download/nginx-0.7.67.tar.gz
RUN tar xfz nginx-0.7.67.tar.gz
RUN rm --interactive=never nginx-0.7.67.tar.gz

WORKDIR nginx-0.7.67
RUN ./configure --prefix=/data/apps --with-pcre=../pcre-8.37 --with-http_ssl_module --with-openssl=../openssl-1.0.0c
RUN make
RUN make install

WORKDIR /downloads
RUN rm -rf pcre-8.37
RUN rm -rf openssl-1.0.0c
RUN rm -rf nginx-0.7.67

ENV PATH /data/apps/bin:/data/app/sbin:$PATH
ENV LD_LIBRARY_PATH /data/apps/lib:$LD_LIBRARY_PATH
ENV ANYMOOSE Moose

RUN cpan App::cpanminus

# without a terminal the tests fail
RUN cpanm --force Term::ReadKey 

RUN cpanm Test::Most Test::Trap AnyEvent Beanstalk::Client Business::PayPal::API Chat::Envolve Clone Config::JSON Config::YAML
RUN cpanm DateTime DateTime::Format::Duration DateTime::Format::MySQL DateTime::Format::Strptime DBD::mysql DBIx::Class 
RUN cpanm DBIx::Class::DynamicSubclass DBIx::Class::InflateColumn::Serializer DBIx::Class::Schema DBIx::Class::TimeStamp 
RUN cpanm Digest::HMAC_SHA1 Digest::MD5 Email::Stuff Email::Valid Facebook::Graph File::Copy File::Path Guard IO::Socket::SSL
RUN cpanm JSON JSON::Any JSON::RPC::Dispatcher JSON::RPC::Dispatcher::App JSON::WebToken JSON::XS List::MoreUtils List::Util
RUN cpanm List::Util::WeightedChoice Log::Any::Adapter Log::Any::Adapter::Log4perl Log::Log4perl LWP::Protocol::https LWP::UserAgent
RUN cpanm Module::Find Moose namespace::autoclean Term::ProgressBar::Simple Net::Amazon::S3 Net::Server::SS::PreFork Path::Class
RUN cpanm Plack::Middleware::CrossOrigin Pod::Simple::HTML Regexp::Common Server::Starter SOAP::Lite String::Random
RUN cpanm Text::CSV_XS Tie::IxHash URI::Encode UUID::Tiny XML::FeedPP XML::Hash::LX XML::Parser
RUN cpanm Term::ProgressBar Term::ProgressBar::Quiet PerlX::Maybe Firebase::Auth Gravatar::URL

# without verbose it times out and aborts due to long compilation
RUN cpanm --verbose Memcached::libmemcached

# Starman does not seem to test without a terminal
RUN cpanm --notest Starman

# We don't need git in a dev environment
#RUN cpanm Git::Wrapper

# This seems to be no longer on cpan! (but it is on metacpan)
#RUN cpanm SOAP::Amazon::S3

WORKDIR /data/Lacuna-Server/third_party
RUN git clone git://github.com/kr/beanstalkd.git
WORKDIR /data/Lacuna-Server/third_party/beanstalkd
RUN make
RUN make install

WORKDIR /data/Lacuna-Server/bin

