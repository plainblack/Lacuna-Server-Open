use lib '../lib';
use Test::More tests => 1;
use Test::Deep;
use Data::Dumper;
use 5.010;
use DateTime;
use WWW::Firebase::TokenGenerate;

use TestHelper;

my $tester = TestHelper->new({empire_name => 'icydee'});

$tester->use_existing_test_empire;
my $session_id  = $tester->session->id;
my $empire      = $tester->empire;

my $token_generator = WWW::Firebase::TokenGenerate->new({
    secret  => 'EiFR06EdQcht5WCiwSSPNGOcUK16dpUXc1OHp1cS',
});

if ($empire->is_admin) {
    $token_generator->admin(1);
}
diag($token_generator);

my $token = $token_generator->create_token({
    empire_name     => $empire->name,
    empire_id       => $empire->id,
    alliance_name   => defined $empire->alliance_id ? $empire->alliance->name : '',
    alliance_id     => $empire->alliance_id || 0,
});

diag($token);

ok(1);

