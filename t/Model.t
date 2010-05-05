use strict;
use lib '../lib';
use Test::More tests => 5;
use Lacuna::DB;
use Lacuna::DB::Result::Star;

foreach my $attr (qw(color name x y z)) {
    ok(Lacuna::DB::Result::Star->can($attr), $attr);
}

