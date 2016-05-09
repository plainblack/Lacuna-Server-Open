package Lacuna::DB::Result::Building::Permanent::MetalJunkArches;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Permanent';

with "Lacuna::Role::Building::UpgradeWithHalls";

use constant controller_class => 'Lacuna::RPC::Building::MetalJunkArches';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Waste Happiness));
};

use constant image => 'metaljunkarches';

sub image_level {
    my ($self) = @_;
    return $self->image.'1';
}

use constant name => 'Metal Junk Arches';
use constant time_to_build => 60 * 60 * 30;
use constant max_instances_per_planet => 1;
use constant happiness_production => 800;
use constant university_prereq => 25;
use constant waste_to_build => -6_000_000;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
