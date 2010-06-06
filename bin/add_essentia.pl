use 5.010;
use lib '/data/Lacuna-Server/lib';
use Lacuna::DB;
use Lacuna;
use Getopt::Long;

my $config = Lacuna->config;
my $db = Lacuna->db;

my $name;
my $amount = 10;
my $note = 'add_essentia.pl';
GetOptions(
	'name=s' => \$name,
	'amount=i' => \$amount,
    'note=s' => \$note,
);	



$db
	->resultset('Lacuna::DB::Result::Empire')
	->search({name => $name}, {rows=>1})
	->single
	->add_essentia($amount,$note)
	->update;


