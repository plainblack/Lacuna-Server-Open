use strict;
use LWP::UserAgent;
use JSON qw(to_json from_json);
use 5.010;
use Getopt::Long;
use Time::HiRes;
use HTTP::Request::Common;

my $empire_name;
my $password;
my $server;
my $ping;
GetOptions(
    'empire-name=s'     => \$empire_name,  
    'password=s'        => \$password,
    'server=s'          => \$server,
    'ping'              => \$ping,
);

my $ua = LWP::UserAgent->new;
$ua->timeout(30);
$ua->get('https://www.google.com/'); # prime it



if ($ping) {
    my $t = [Time::HiRes::gettimeofday];
    die 'nginx failed' unless $ua->get('https://'.$server.'/nginx_ping.txt')->is_success;
    my $nginx_time = Time::HiRes::tv_interval($t);
    $t = [Time::HiRes::gettimeofday];
    die 'starman failed' unless $ua->get('https://'.$server.'/starman_ping')->is_success;
    my $starman_time = Time::HiRes::tv_interval($t);
    say "Nginx: ".$nginx_time;
    say "Starman: ". $starman_time;
    say "Difference: ".($starman_time - $nginx_time);
    exit;
}


unless ($empire_name && $password && $server) {
    say "Usage: $0 --empire-name=xxx --password=xxx --server=us1.lacunaexpanse.com";
    exit;
}

my $t = [Time::HiRes::gettimeofday];
my $content = {
    jsonrpc     => '2.0',
    id          => 1,
    method      => 'benchmark',
    params      => [$empire_name, $password, 'benchmark'],
};
#say "REQUEST: ".to_json($content);
my $response = $ua->post('https://'.$server.'/empire',
    Content_Type    => 'application/json',
    Content         => to_json($content),
    Accept          => 'application/json',
    );
#say "RESPONSE: ".$response->content;
my $result = from_json($response->content);
my $total_time = Time::HiRes::tv_interval($t);

my $internal_time;
foreach my $key (keys %{$result->{result}}) {
    say $key.' = '.$result->{result}{$key};
    $internal_time += $result->{result}{$key};
}
say "Internal Time = ".$internal_time;
say "External Time = ".($total_time - $internal_time);
say "Total Time = ".$total_time;




