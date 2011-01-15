package Lacuna::DB::Result::Building::Permanent::GreatBallOfJunk;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Permanent';

use constant controller_class => 'Lacuna::RPC::Building::GreatBallOfJunk';

around can_upgrade => sub {
    my ($orig, $self) = @_;
    if ($self->body->get_plan(__PACKAGE__, $self->level + 1)) {
        return $orig->($self);  
    }
    confess [1013,"You can't upgrade a monument."];
};

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
use constant happiness_production => 20_000;
use constant university_prereq => 23;
use constant waste_to_build => -4_000_000;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
