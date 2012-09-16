use lib '../lib';

use strict;
use warnings;

use Test::More tests => 3;
use Test::Deep;
use Test::Memory::Cycle;
use Data::Dumper;
use 5.010;
use DateTime;
use Lacuna;


my $minus_x = 493;
my $minus_y = 498;
my $closest = Lacuna->db->resultset('Map::Body')->search({
    empire_id => {'>' => 1},
},{
    '+select' => [
        { ceil => \"pow(pow(me.x + $minus_x,2) + pow(me.y + $minus_y,2), 0.5)", '-as' => 'distance' },
    ],
    '+as' => [
        'distance',
    ],
    order_by    => 'distance',
});


diag($closest);
my $damaged = 0;
DAMAGED:
while (my $to_damage = $closest->next) {
    # damage planet
    diag("Damaging planet ".$to_damage->name." at distance ".$to_damage->get_column('distance'));

    if (++$damaged == 10) {
        last DAMAGED;
    }
}


