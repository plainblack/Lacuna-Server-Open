package Lacuna::DB::Result::Building::Permanent::TheDillonForge;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building::Permanent';
use Lacuna::Util qw(randint);

use constant controller_class => 'Lacuna::RPC::Building::TheDillonForge';

around can_build => sub {
    my ($orig, $self, $body) = @_;
    confess [1013,"You can't build The Dillon Forge by any known process. How the hell did you manage to get a plan!?"];
};

around can_upgrade => sub {
    my ($orig, $self) = @_;
    confess [1013,"You can't upgrade the Dillon Forge, the technology to do so is beyond your scientific ability."];
};

around can_downgrade => sub {
    my ($orig, $self) = @_;
    confess [1013,"You can't downgrade the Dillon Forge, it is impervious to your current level of technology."];
};

around can_demolish => sub {
    my ($orig, $self) = @_;
    confess [1013,"You can't demolish the Dillon Forge, it is impervious to your current level of technology."];
};

use constant image => 'thedillonforge';

sub image_level {
    my ($self) = @_;
    return $self->image.'1';
}

after finish_upgrade => sub {
    my $self = shift;
    $self->body->add_news(30, sprintf('It is hard to believe that after going unused for nearly '.randint(10,99).',000 years, The Dillon Forge still works on %s.', $self->body->name));
};

use constant name => 'The Dillon Forge';
use constant time_to_build => 0;
use constant max_instances_per_planet => 1;


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
