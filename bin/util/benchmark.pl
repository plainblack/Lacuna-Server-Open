use strict;
use LWP::UserAgent;
use JSON qw(to_json from_json);
use 5.010;
use Getopt::Long;
use Time::HiRes;

my $empire_name;
my $password;
my $server;
GetOptions(
    'empire-name=s'         => \$empire_name,  
    'password=s'       => \$password,
    'server=s'        => \$server,
);

unless ($empire_name && $password && $server) {
    say "Usage: $0 --empire-name=xxx --password=xxx --server=us1.lacunaexpanse.com";
    exit;
}

my $t = [Time::HiRes::gettimeofday];
my $ua = LWP::UserAgent->new;
$ua->timeout(30);
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


