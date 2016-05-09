package Lacuna::DB::Result::Building::Permanent::GreatBallOfJunk;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Permanent';

with "Lacuna::Role::Building::UpgradeWithHalls";

use constant controller_class => 'Lacuna::RPC::Building::GreatBallOfJunk';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Waste Happiness));
};

use constant image => 'greatballofjunk';

sub image_level {
    my ($self) = @_;
    return $self->image.'1';
}

use constant name => 'Great Ball of Junk';
use constant time_to_build => 60 * 60 * 20;
use constant max_instances_per_planet => 1;
use constant happiness_production => 700;
use constant university_prereq => 23;
use constant waste_to_build => -4_000_000;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
