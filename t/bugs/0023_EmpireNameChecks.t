use lib '../../lib','..';
use Test::More tests => 2;
use 5.010;

use strict;
use warnings;

my $result;

use TestHelper;
TestHelper->clear_all_test_empires;

my $tester = TestHelper->new({empire_name => 'TLE Test  Multiple   Spaces'});
$tester->cleanup;

$result = $tester->post('empire', 'is_name_available', [$tester->empire_name]);
is($result->{error}{code}, 1000, 'empire name has multiple spaces');

$result = $tester->post('empire', 'is_name_available', ['TLE Test (Culture)']);
is($result->{error}{code}, 1000, 'empire name has brackets');

END {
#    TestHelper->clear_all_test_empires;
}


