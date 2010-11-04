use lib '../lib';
use Test::More;
use Test::Deep;
use Data::Dumper;
use Lacuna;
use 5.010;
$|=1;
use Config::JSON;

use TestHelper;

opendir my $folder, '/data/Lacuna-Server/var/missions';
my @files = readdir $folder;
closedir $folder;

my $config;
foreach my $filename (@files) {
    next if $filename =~ m/^\./;
    ok($filename =~ m/^[a-z0-9\-\_]+\.((mission)|(part\d))$/i, $filename.' is valid filename');
    eval{ $config = Config::JSON->new('/data/Lacuna-Server/var/missions/'.$filename)};
    isa_ok($config,'Config::JSON');
    ok($config->get('mission_type'), 'has a type');
    my @plans = (@{$config->get('mission_objective')->{plans}}, @{$config->get('mission_reward')->{plans}});
    foreach my $plan (@plans) {
        my $class = $plan->{classname};
        ok(eval{$class->name}, $filename.' plan class '.$class.' loads');
    }
}

done_testing();



