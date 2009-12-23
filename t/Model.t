use strict;
use lib '../lib';
use Test::More tests => 5;
use Lacuna::DB;
use Lacuna::DB::Star;

foreach my $attr (qw(color name x y z)) {
    ok(Lacuna::DB::Star->can($attr), $attr);
}

