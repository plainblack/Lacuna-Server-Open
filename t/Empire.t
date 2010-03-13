use lib '../lib';
use Test::More tests => 11;
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
is($result->{result}, 0, 'empire name not available');

$result = $tester->post('empire', 'found', [$empire_id]);
my $session_id = $result->{result}{session_id};
ok(defined $session_id, 'empire logged in after foundation');

$result = $tester->post('empire', 'logout', [$session_id]);
is($result->{result}, 1, 'logout');

$result = $tester->post('empire', 'login', [$tester->empire_name,$tester->empire_password]);
ok(exists $result->{result}{session_id}, 'login');


END {
    $tester->cleanup;
}
