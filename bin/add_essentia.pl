use 5.010;
use lib '/data/Lacuna-Server/lib';
use Lacuna::DB;
use Lacuna;
use Getopt::Long;

my $config = Lacuna->config;
my $db = Lacuna::DB->new( access_key => $config->get('access_key'), secret_key => $config->get('secret_key'), cache_servers => $config->get('memcached')); 

my $name;
my $amount = 10;
GetOptions(
	'name=s' => \$name,
	'amount=i' => \$amount,
);	



$db
	->resultset('Lacuna::DB::Result::Empire')
	->search({name => $name}, {rows=>1})
	->single
	->add_essentia($amount)
	->update;


