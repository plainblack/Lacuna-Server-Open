use lib '../lib';
use Test::More tests => 11;
use Test::Deep;
use Data::Dumper;
use 5.010;
use DateTime;

use strict;
use warnings;

use TestHelper;
TestHelper->clear_all_test_empires;

my $tester = TestHelper->new->generate_test_empire->build_infrastructure;
my $session_id = $tester->session->id;
my $empire = $tester->empire;
my $home = $empire->home_planet;

my $result;

my $forge_level = 5;
my $forge = $tester->build_building('Lacuna::DB::Result::Building::Permanent::TheDillonForge', $forge_level);
my $arch  = $tester->build_building('Lacuna::DB::Result::Building::Archaeology', 15);
my $trade = $tester->build_building('Lacuna::DB::Result::Building::Trade', 15);

# create some plans to split and combine

for (1..21) {
    $home->add_plan('Lacuna::DB::Result::Building::SpacePort', 5);
}

for (1..21) {
    $home->add_plan('Lacuna::DB::Result::Building::SpacePort', 1);
}

$home->add_plan('Lacuna::DB::Result::Building::Permanent::AlgaePond', 1);
$home->add_plan('Lacuna::DB::Result::Building::Permanent::AlgaePond', 1, 5);

$result = $tester->post('thedillonforge', 'view', [$session_id, $forge->id]);

is_deeply($result->{result}{tasks}, {
    can => 1,
    make_plan => [
        {
            name                => 'Space Port',
            max_level           => $forge_level,
            class               => 'SpacePort',
            reset_sec_per_level => 5000,
        }
    ],
    split_plan => [
        {
            name                => 'Algae Pond',
            class               => 'Permanent::AlgaePond',
            level               => 1,
            extra_build_level   => 0,
            fail_chance         => 85,
            reset_seconds       => 21600,
        },
        {
            name                => 'Algae Pond',
            class               => 'Permanent::AlgaePond',
            level               => 1,
            extra_build_level   => 5,
            fail_chance         => 85,
            reset_seconds       => 453600,
        }
    ],
});

$result = $tester->post('thedillonforge', 'subsidize', [$session_id, $forge->id]);

is_deeply($result->{error}, {
    data    => undef,
    message => 'Nothing is being done!',
    code    => 1010,
});

$result = $tester->post('thedillonforge', 'make_plan', [$session_id, $forge->id, 'SpacePort', 6]);

is_deeply($result->{error}, {
    data    => undef,
    message => 'Your Dillon Forge level is not high enough to build that high a plan level.',
    code    => 1002,
});

$result = $tester->post('thedillonforge', 'make_plan', [$session_id, $forge->id, 'SpacePort', $forge_level]);

is_deeply($result->{result}{tasks}, {
    seconds_remaining   => 25000,
    can                 => 0,
});

$result = $tester->post('thedillonforge', 'subsidize', [$session_id, $forge->id]);

is_deeply($result->{error}, {
    data    => undef,
    message => 'Not enough essentia.',
    code    => 1011,
});

$empire->add_essentia({ amount => 100, reason => 'testing The Dillon Forge'});
$empire->update;

$result = $tester->post('thedillonforge', 'subsidize', [$session_id, $forge->id]);

my $plans_1 = $home->plans->search({
    level               => 1,
    class               => 'Lacuna::DB::Result::Building::SpacePort',
    extra_build_level   => 0,
})->count;

is($plans_1, 11, "We have consumed 10 level 1 plans");

my $plans_5 = $home->plans->search({
    level               => 5,
    class               => 'Lacuna::DB::Result::Building::SpacePort',
    extra_build_level   => 0,
})->count;

is($plans_5, 22, "We have created an extra level 5+0 plan");

$result = $tester->post('thedillonforge', 'split_plan', [$session_id, $forge->id, 'SpacePort', 1, 0]);

is_deeply($result->{error}, {
    data    => undef,
    message => 'You can only split plans that have a glyph recipe.',
    code    => 1002,
});

$result = $tester->post('thedillonforge', 'split_plan', [$session_id, $forge->id, 'Permanent::AlgaePond', 1, 5]);

is_deeply($result->{result}{tasks}, {
    seconds_remaining   => 453600,
    can                 => 0,
});

$result = $tester->post('thedillonforge', 'subsidize', [$session_id, $forge->id]);

$plans_1 = $home->plans->search({
    level               => 1,
    class               => 'Lacuna::DB::Result::Building::Permanent::AlgaePond',
    extra_build_level   => 5,
})->count;

is($plans_1, 0, "We have split a plan into glyphs");

my $glyphs = $home->glyphs->search({
    
})->count;

cmp_ok($glyphs, '>', 0, "We expect at least one glyph");

END {
#    TestHelper->clear_all_test_empires;
}
1;

