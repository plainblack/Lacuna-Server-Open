package Lacuna::DB::Result::Building::Permanent::JunkHengeSculpture;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Permanent';

use constant controller_class => 'Lacuna::RPC::Building::JunkHengeSculpture';

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

use constant image => 'junkhengesculpture';

sub image_level {
    my ($self) = @_;
    return $self->image.'1';
}

use constant name => 'Junk Henge Sculpture';
use constant time_to_build => 60 * 60 * 10;
use constant max_instances_per_planet => 1;
use constant happiness_production => 10_000;
use constant university_prereq => 21;
use constant waste_to_build => -2_000_000;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
