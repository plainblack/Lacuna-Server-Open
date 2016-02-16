use lib '/data/Lacuna-Server-Open/lib';

use Test::More;
use Log::Any::Test;
use Log::Any qw/$log/;

use Plack::Builder;
use Plack::Test;
use HTTP::Request::Common;

use_ok 'Plack::Middleware::LightProfile';

my $base_app = sub { return [ 200, [], ['Body'] ]; };

my $app = builder {
    enable 'LightProfile';
    $base_app;
};

test_psgi
    app => $app,
    client => sub {
        my $cb = shift;
        my $res = $cb->(GET "/");
        is $res->code, 200, 'Call succeeded';
        is $res->content, 'Body', '... returned correct content';
    }
    ;

$log->contains_ok(qr/response time: \d.\d+ end memory: \d+ added memory: \d+/, 'Logged memory and time data');
$log->empty_ok('Only one message in the log');

done_testing;
