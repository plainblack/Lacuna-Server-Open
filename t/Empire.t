use lib '../lib';
use Test::More tests => 25;
use Test::Deep;
use Data::Dumper;
use 5.010;

my $result;

use TestHelper;
my $tester = TestHelper->new;
$tester->cleanup;


$result = $tester->post('empire', 'is_name_available', [$tester->empire_name]);
is($result->{result}, 1, 'empire name is available');

my $empire = {
    name        => $tester->empire_name,
    password    => $tester->empire_password,
    password1   => $tester->empire_password,
};

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

$result = $tester->post('empire', 'found', [$empire_id]);
my $session_id = $result->{result}{session_id};
ok(defined $session_id, 'empire logged in after foundation');

$result = $tester->post('empire', 'logout', [$session_id]);
is($result->{result}, 1, 'logout');

$result = $tester->post('empire', 'login', [$tester->empire_name,$tester->empire_password]);
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

$result = $tester->post('empire', 'find', [$session_id, 'TLE']);
is($result->{result}{empires}[0]{id}, $empire_id, 'empire search works');

$result = $tester->post('empire', 'get_status', [$session_id]);
ok(exists $result->{result}{empire}{planets}, 'got starting resources');


$result = $tester->post('empire', 'login', [$tester->empire_name, 'broken sitter password']);
is($result->{error}{code}, 1004, 'broken sitter password');

$result = $tester->post('empire', 'login', [$tester->empire_name, 'testsitter']);
ok(exists $result->{result}{session_id}, 'login with sitter password');

my $empire2 = $empire;
$empire2->{name} = 'essentia code';
$empire2->{email} = 'test@example.com';
$result = $tester->post('empire', 'create', $empire2);
$empire2->{id} = $result->{result};
$result = $tester->post('empire', 'found', [$empire2->{id}]);
my $e2 = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->find($empire2->{id});
$e2->add_essentia(100, 'test')->update;
$result = $tester->post('empire', 'get_status', [$result->{result}{session_id}]);
ok($result->{result}{empire}{essentia} > 99, 'added essentia works');
$e2->delete;
my $code = Lacuna->db->resultset('Lacuna::DB::Result::EssentiaCode')->search({description=>'essentia code deleted'},{rows=>1})->single;
is($result->{result}{empire}{essentia}, $code->amount, 'you get a proper essentia code');

END {
    $tester->cleanup;
    Lacuna->db->resultset('Lacuna::DB::Result::EssentiaCode')->delete;
    Lacuna->db->resultset('Lacuna::DB::Result::Empire')->search({name => 'essentia code'})->delete;
}
