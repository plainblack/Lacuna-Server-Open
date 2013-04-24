use lib '../lib';
use Test::More tests => 1;
use Test::Deep;
use Data::Dumper;
use 5.010;
use DateTime;
use WWW::Firebase::TokenGenerator;
use WWW::Firebase::API::Connection;
use DateTime;

use TestHelper;

my $tester = TestHelper->new({empire_name => 'icydee'});

$tester->use_existing_test_empire;
my $session_id  = $tester->session->id;
my $empire      = $tester->empire;

my $token_generator = WWW::Firebase::TokenGenerator->new({
    secret  => 'EiFR06EdQcht5WCiwSSPNGOcUK16dpUXc1OHp1cS',
    admin   => $empire->is_admin,
});

isa_ok($token_generator,'WWW::Firebase::TokenGenerator');

my $token = $token_generator->create_token({
    empire_name     => $empire->name,
    empire_id       => $empire->id,
    alliance_name   => defined $empire->alliance_id ? $empire->alliance->name : '',
    alliance_id     => $empire->alliance_id || 0,
});

diag($token);

my $connection = WWW::Firebase::API::Connection->new({
    base_uri        => 'https://lacuna-chat.firebaseio.com/',
    auth            => $token,
});

my $response;

# This inserts a new record, or replaces an existing record
$response = $connection->PUT('person/945', {
    empire      => 'icydee',
    on_line     => 0,
});

# Insert or update
$response = $connection->PUT('person/46', {
    empire      => 'Norway',
    on_line     => 1,
});


$response = $connection->PUT('chatroom/Secret', {
    is_public   => 0,
});

$response = $connection->POST('chatroom/Secret/auth_people', {
    person      => {
        id      => 945,
        name    => 'icydee',
    },
});


my $now = DateTime->now;
# put a new chat posting.
$response = $connection->POST('chatroom/General/chat', {
    person      => {
        id      => 945,
        name    => 'icydee',
    },
    datetime    => $now->ymd('-').' '.$now->hms(':'),
    text        => 'Hello world',
});






exit;



my $response = $connection->GET('chat');

$response = $connection->POST('chat/room/general/chat',{ empire => {name => 'Freda', id => 3}, text => 'Hello world 2'});

diag(Dumper($response));

my $name = $response->{name};

$response= $connection->GET("chat/room/general/chat/$name");
diag(Dumper($response));

# now delete it again
$response = $connection->DELETE("chat/room/general/chat/$name");
diag("DELETE response:".Dumper($response));


diag(Dumper($name));


ok(1);

