package Lacuna::DB::Result::Building::Permanent::PyramidJunkSculpture;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Permanent';

with "Lacuna::Role::Building::UpgradeWithHalls";

use constant controller_class => 'Lacuna::RPC::Building::PyramidJunkSculpture';

use Lacuna::Constants qw(INFLATION_F WASTE_F HAPPY_F TINFLATE_F);

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Waste Happiness));
};

use constant image => 'pyramidjunksculpture';

sub image_level {
    my ($self) = @_;
    return $self->image.'1';
}

use constant name => 'Pyramid Junk Sculpture';
use constant time_to_build => 60 * 60 * 50;
use constant max_instances_per_planet => 1;
use constant happiness_production => 600;
use constant university_prereq => 29;
use constant waste_to_build => -10_000_000;
use constant waste_consumption => 600;

use constant waste_consume_rate => WASTE_F;
use constant happy_prod_rate => HAPPY_F;
use constant time_inflation => TINFLATE_F;
use constant cost_rate => INFLATION_F;

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

