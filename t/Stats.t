use lib '../lib';
use Test::More tests => 1;
use Test::Deep;
use Data::Dumper;
use 5.010;

use TestHelper;
my $tester = TestHelper->new;


my $result = $tester->post('stats', 'credits',[]);

is($result->{result}[0]{'Game Design'}[0], 'JT Smith', 'credits');

