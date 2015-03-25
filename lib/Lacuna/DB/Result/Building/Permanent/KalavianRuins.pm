package Lacuna::DB::Result::Building::Permanent::KalavianRuins;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Permanent';

with "Lacuna::Role::Building::UpgradeWithHalls";
with "Lacuna::Role::Building::CantBuildWithoutPlan";

use constant controller_class => 'Lacuna::RPC::Building::KalavianRuins';
use Lacuna::Util qw(randint);

use constant image => 'kalavianruins';

sub image_level {
    my ($self) = @_;
    return $self->image.'1';
}

after finish_upgrade => sub {
    my $self = shift;
    $self->body->add_news(50, 'Archaeologists estimate that the Kalavian Ruins they uncovered on %s were buried for %d,000 years.', $self->body->name, randint(10,99));
};

use constant name => 'Kalavian Ruins';

use constant time_to_build => 0;
use constant max_instances_per_planet => 1;
use constant happiness_production => 4000;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
