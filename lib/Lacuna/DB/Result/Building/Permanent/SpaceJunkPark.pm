package Lacuna::DB::Result::Building::Permanent::SpaceJunkPark;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Permanent';

with "Lacuna::Role::Building::UpgradeWithHalls"; 
use constant controller_class => 'Lacuna::RPC::Building::SpaceJunkPark';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Waste Happiness));
};

use constant image => 'spacejunkpark';

sub image_level {
    my ($self) = @_;
    return $self->image.'1';
}

use constant name => 'Space Junk Park';
use constant time_to_build => 60 * 60 * 40;
use constant max_instances_per_planet => 1;
use constant happiness_production => 900;
use constant university_prereq => 27;
use constant waste_to_build => -8_000_000;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
