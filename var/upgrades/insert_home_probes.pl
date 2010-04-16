use 5.010;
use lib '/data/Lacuna-Server/lib';
use Lacuna::DB;
use Lacuna;

my $config = Lacuna->config;
my $db = Lacuna::DB->new( access_key => $config->get('access_key'), secret_key => $config->get('secret_key'), cache_servers => $config->get('memcached')); 

my $empires = $db->domain('empire')->search;

while (my $empire = $empires->next) {
    next if $empire->count_probed_stars;
    my $home = $empire->home_planet;
    if (defined $home) {
    	$empire->add_probe($home->star_id);
    }
}
