use lib '../lib';
use Test::More tests => 50;
use Test::Deep;
use 5.010;

use strict;
use warnings;

my $result;

use TestHelper;
TestHelper->clear_all_test_empires;

my $tester = TestHelper->new;
$tester->cleanup;

$result = $tester->post('empire', 'is_name_available', [$tester->empire_name]);
is($result->{result}, 1, 'empire name is available');

my $empire = {
    name        => $tester->empire_name,
    password    => $tester->empire_password,
    password1   => $tester->empire_password,
    email       => 'joe@blow.com',
    captcha_guid    => '1111',
    captcha_solution=> '1111',
};
my $e2;

Lacuna->cache->set('create_empire_captcha', '127.0.0.1', { guid => 1111, solution => 1111 }, 60 * 15 );

$empire->{name} = 'XX>';
$result = $tester->post('empire', 'create', $empire);
is($result->{error}{code}, 1000, 'empire name has funky chars');

$empire->{name} = '';
$result = $tester->post('empire', 'create', $empire);
is($result->{error}{code}, 1000, 'empire name too short');

$empire->{name} = 'abc def ghi jkl mno pqr stu vwx yz 0123456789';
$result = $tester->post('empire', 'create', $empire);
is($result->{error}{code}, 1000, 'empire name too long');

$empire->{name} = $tester->empire_name;
$empire->{password} = 'abc';
$result = $tester->post('empire', 'create', $empire);
is($result->{error}{code}, 1001, 'empire password too short');

$empire->{password} = 'abc123';
$result = $tester->post('empire', 'create', $empire);
is($result->{error}{code}, 1001, 'empire passwords do not match');

$empire->{password} = $tester->empire_password;

$result = $tester->post('empire', 'create', $empire);
my $empire_id = $result->{result};
ok(defined $empire_id, 'empire created');

$result = $tester->post('empire', 'is_name_available', [$tester->empire_name]);
is($result->{error}{code}, 1000, 'empire name not available');

$result = $tester->post('empire', 'get_species_templates');
is(ref $result->{result}, 'ARRAY', 'can get species templates');

my $borg = {
        name=>'Borg', 
        description=>'cyborg', 
        min_orbit               => 1,
        max_orbit               => 7,
        manufacturing_affinity   => 7,
        deception_affinity      => 1,
        research_affinity       => 4,
        management_affinity     => 7,
        farming_affinity        => 1,
        mining_affinity         => 1,
        science_affinity        => 7,
        environmental_affinity  => 1,
        political_affinity      => 1,
        trade_affinity          => 1,
        growth_affinity         => 7,
        };

$borg->{name} = 'Borg abcdefghijklmnopqrstuvwxyz 123456';
$result = $tester->post('empire', 'update_species', [$empire_id, $borg]);
is($result->{error}{code}, 1000, 'create species with too long a name');

$borg->{name} = 'Borg >';
$result = $tester->post('empire', 'update_species', [$empire_id, $borg]);
is($result->{error}{code}, 1000, 'create species with invalid characters in the name');

$borg->{name} = '';
$result = $tester->post('empire', 'update_species', [$empire_id, $borg]);
is($result->{error}{code}, 1000, 'create species with no name');

$borg->{name} = 'Borg';
$borg->{description} = 'cyborg &';
$result = $tester->post('empire', 'update_species', [$empire_id, $borg]);
is($result->{error}{code}, 1005, 'create species with junk in description');

$borg->{description} = 'cyborg';
$borg->{min_orbit} = '';
$result = $tester->post('empire', 'update_species', [$empire_id, $borg]);
is($result->{error}{code}, 1009, 'create species with too few orbits');

$borg->{min_orbit} = 'blah';
$result = $tester->post('empire', 'update_species', [$empire_id, $borg]);
is($result->{error}{code}, 1009, 'create species with a non orbit');

$borg->{min_orbit} = 0;
$result = $tester->post('empire', 'update_species', [$empire_id, $borg]);
is($result->{error}{code}, 1009, 'create species with invalid orbits');

$borg->{min_orbit} = 1;
$borg->{research_affinity} = 8;
$result = $tester->post('empire', 'update_species', [$empire_id, $borg]);
is($result->{error}{code}, 1007, 'affinity too high');

$borg->{research_affinity} = 0;
$result = $tester->post('empire', 'update_species', [$empire_id, $borg]);
is($result->{error}{code}, 1008, 'affinity too low');

$borg->{research_affinity} = 1;
$result = $tester->post('empire', 'update_species', [$empire_id, $borg]);
is($result->{error}{code}, 1008, 'too few points spent');

$borg->{research_affinity} = 5;
$result = $tester->post('empire', 'update_species', [$empire_id, $borg]);
is($result->{error}{code}, 1007, 'too many points spent');

$borg->{research_affinity} = 4;
$result = $tester->post('empire', 'update_species', [$empire_id, $borg]);
cmp_deeply(
    $result,
    {jsonrpc=>'2.0', id=>1, result=>ignore()},
    'create species'
);
my $borg_id = $result->{result};

$result = $tester->post('empire', 'update_species', [$empire_id, $borg]);
ok(exists $result->{result}, 're-create works');

$result = $tester->post('empire', 'found', [$empire_id]);
is($result->{error}{code}, 1002, 'api key required');

$result = $tester->post('empire', 'found', [$empire_id,'Anonymous']);
my $session_id = $result->{result}{session_id};
ok(defined $session_id, 'empire logged in after foundation');
ok($result->{result}{welcome_message_id}, 'we get a welcome message');

$empire->{email} = 'joe2@blow.com';
$result = $tester->post('empire', 'create', $empire);
ok(exists $result->{error}, 'cannot create a second time');

$empire->{password} = 'dddddd';
$empire->{password1} = 'dddddd';
$result = $tester->post('empire', 'create', $empire);
ok(exists $result->{error}, 'cannot create a second time with a different password');

my $empire_obj = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->find($empire_id);
is($empire_obj->species_name, 'Borg', 'species getting set properly');
is($empire_obj->home_planet->command->level, 7, 'growth affinity works');

$result = $tester->post('empire','view_species_stats',[$session_id]);
is($result->{result}{species}{name}, 'Borg', 'get species name');
is($result->{result}{species}{research_affinity}, 4, 'get affinity');

$result = $tester->post('empire', 'logout', [$session_id]);
is($result->{result}, 1, 'logout');

$result = $tester->post('empire', 'login', [$tester->empire_name,$tester->empire_password,'Anonymous']);
ok(exists $result->{result}{session_id}, 'login');
cmp_ok($result->{result}{status}{server}{version}, '>=', 1, 'version number');
cmp_ok($result->{result}{status}{server}{star_map_size}{x}[1], '>=', 1, 'map size');
$session_id = $result->{result}{session_id};

$result = $tester->post('empire', 'set_status_message', [$session_id,'woot!']);

$result = $tester->post('empire', 'view_profile', [$session_id]);
ok(exists $result->{result}{profile}, 'view profile');
ok(exists $result->{result}{profile}{status_message}, 'can set status message');
my @medal_ids = keys %{$result->{result}{profile}{medals}};
my $private_medal_id = pop @medal_ids;

my %profile = (
    status_message  => 'Whoopie!',
    description     => 'test',
    public_medals   => \@medal_ids,
    sitter_password => 'testsitter',
);
$result = $tester->post('empire', 'edit_profile', [$session_id, \%profile]);
is($result->{result}{profile}{description}, 'test', 'description set in profile');
is($result->{result}{profile}{status_message}, 'Whoopie!', 'status message set in profile');
is($result->{result}{profile}{medals}{$private_medal_id}{public}, 0, 'medal set private');

$result = $tester->post('empire', 'view_public_profile', [$session_id, $empire_id]);
is($result->{result}{profile}{status_message}, 'Whoopie!', 'public profile works');

$result = $tester->post('empire', 'invite_friend', [$session_id, $empire_id, 'tavis@isajerk.com']);
ok($result->{result}, 'can invite a friend');

$result = $tester->post('empire', 'find', [$session_id, 'TLE']);
is($result->{result}{empires}[0]{id}, $empire_id, 'empire search works');

$result = $tester->post('empire', 'get_status', [$session_id]);
ok(exists $result->{result}{empire}{planets}, 'got starting resources');


$result = $tester->post('empire', 'login', [$tester->empire_name, 'broken sitter password','Anonymous']);
is($result->{error}{code}, 1004, 'broken sitter password');

$result = $tester->post('empire', 'login', [$tester->empire_name, 'testsitter','Anonymous']);
ok(exists $result->{result}{session_id}, 'login with sitter password');

my %empire2 = %{$empire};
$empire2{name} = 'TLE Test essentia code';
$empire2{email} = 'test@example.com';
$result = $tester->post('empire', 'create', \%empire2);
$empire2{id} = $result->{result};
$result = $tester->post('empire', 'found', [$empire2{id},'Anonymous']);
$e2 = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->find($empire2{id});
$e2->add_essentia({ amount => 200, reason => 'test'});
$e2->update;
my $session2 = $result->{result}{session_id};
$result = $tester->post('empire', 'get_status', [$session2]);
is($result->{result}{empire}{essentia}, '200.0', 'added essentia works');

$result = $tester->post('empire', 'redefine_species_limits', [$session2]);
is($result->{result}{essentia_cost}, 100, 'get redefine limits');

$borg->{name} = 'The BORGinator';
$result = $tester->post('empire', 'redefine_species', [$session2, $borg]);
$result = $tester->post('empire','view_species_stats',[$session2]);
is($result->{result}{species}{name}, 'The BORGinator', 'get renamed species name');
is($result->{result}{status}{empire}{essentia}, '100.0', 'essentia spent');

# as far as I can tell, we don't create an EssentiaCode in this test.
#my $code = Lacuna->db->resultset('Lacuna::DB::Result::EssentiaCode')->search({description=>'essentia code deleted'})->first;
#is($result->{result}{status}{empire}{essentia}, $code->amount, 'you get a proper essentia code');

END {
    TestHelper->clear_all_test_empires;
}
