use lib '../lib';

use strict;
use warnings;

use Test::More tests => 3;
use Test::Deep;
use Test::Memory::Cycle;
use Data::Dumper;
use 5.010;
use DateTime;
use Lacuna;
use TestHelper;

my $empire_name     = 'icydee';
my $planet_name     = 'iceburg';
my $target_name     = 'Aep Eewes Eerv 3';

my $tester = TestHelper->new({empire_name => $empire_name})->use_existing_test_empire;
my $empire = $tester->empire;
my $session = $empire->start_session({api_key => 'tester'});

diag("Empire ".$empire->name);
diag("Empire @{[$empire->name]}");
diag("Session @{[$tester->session]}");

my $session_id = $tester->session->id;

my ($planet) = Lacuna->db->resultset('Map::Body::Planet')->search({name => $planet_name});
my ($bhg)    = $planet->get_building_of_class('Lacuna::DB::Result::Building::Permanent::BlackHoleGenerator');

diag("BHG = $bhg");

my $result = $tester->post('blackholegenerator','get_actions_for', [$session_id, $bhg->id, {body_name => $target_name}]);
diag(Dumper($result->{result}{tasks}));

$result = $tester->post('blackholegenerator','generate_singularity', [{
    session_id          => $session_id,
    building_id         => $bhg->id,
    target              => { body_name => $target_name },
    task_name           => "Swap Places",
    subsidize           => 1,
}]);

diag(Dumper($result->{result}));

$result = $tester->post('blackholegenerator','subsidize_cooldown', [$session_id, $bhg->id]);

diag(Dumper($result->{result}{tasks}));
1;

