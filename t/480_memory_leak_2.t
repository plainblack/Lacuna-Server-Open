use lib '../lib';

use strict;
use warnings;

use Test::More tests => 2;
use Test::Deep;
use Test::Memory::Cycle;
use Data::Dumper;
use 5.010;
use DateTime;
use Lacuna;

my $empire_name = "TLE Test Memory Leak";

# Make sure no other test empires are still around
my $empires = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->search({
    name                => $empire_name,
});
while (my $empire = $empires->next) {
    $empire->delete;
}

my $empire = Lacuna->db->resultset('Lacuna::DB::Result::Empire')->new({
    name                => $empire_name,
    date_created        => DateTime->now,
    status_message      => 'Making Lacuna a better Expanse.',
    password            => Lacuna::DB::Result::Empire->encrypt_password('secret'),
})->insert;
memory_cycle_ok($empire, "Initial empire has no memory cycles");

$empire->found;
                                                                  
memory_cycle_ok($empire, "Founded empire has no memory cycles");

END {
#    TestHelper->clear_all_test_empires;
}
