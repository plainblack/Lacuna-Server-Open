package Lacuna::DB::Result::Building::Permanent;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building';

use Lacuna::Constants qw(GROWTH_S INFLATION_F CONSUME_F WASTE_F HAPPY_S TINFLATE_F);

use constant prod_rate    => GROWTH_S;
use constant cost_rate    => INFLATION_F;
use constant consume_rate => CONSUME_F;
use constant waste_prod_rate => WASTE_F;
use constant waste_consume_rate => WASTE_F;
use constant happy_prod_rate => HAPPY_S;
use constant time_inflation => TINFLATE_F;

sub sortable_name {
    '25'.shift->name
}

# permanent buildings come with no population
sub _build_population {
    0
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
