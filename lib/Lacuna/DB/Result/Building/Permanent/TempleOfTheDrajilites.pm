package Lacuna::DB::Result::Building::Permanent::TempleOfTheDrajilites;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Permanent';

with "Lacuna::Role::Building::UpgradeWithHalls";
with "Lacuna::Role::Building::CantBuildWithoutPlan";

use constant controller_class => 'Lacuna::RPC::Building::TempleOfTheDrajilites';

after finish_upgrade => sub {
    my $self = shift;
    $self->body->add_news(50, 'The Disciples of Drajilite rejoiced when their ancient temple was uncovered on %s.', $self->body->name);
};

use constant image => 'templedrajilites';

sub image_level {
    my ($self) = @_;
    return $self->image.'1';
}

use constant name => 'Temple of the Drajilites';

use constant time_to_build => 0;
use constant max_instances_per_planet => 1;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
