use strict;
use lib '/data/Lacuna-Server-Open/lib';
use Lacuna;
use Lacuna::Constants qw(FOOD_TYPES ORE_TYPES);
use DBI;
use 5.010;
my $config = Lacuna->config->get('db-reboot');
my $db = DBI->connect($config->{dsn}, $config->{username}, $config->{password});
foreach my $resource (qw(energy water), ORE_TYPES, FOOD_TYPES) {
  my $field = $resource .'_stored'; 
  print $resource . ': ';
  say $db->do("update body set $field = 0 where $field < 0");
}





