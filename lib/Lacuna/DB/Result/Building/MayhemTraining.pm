package Lacuna::DB::Result::Building::MayhemTraining;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Building';

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Infrastructure Intelligence));
};

use constant controller_class => 'Lacuna::RPC::Building::MayhemTraining';

use constant max_instances_per_planet => 1;

use constant university_prereq => 13;

use constant image => 'mayhemtraining';

use constant name => 'Mayhem Training';

use constant food_to_build => 100;

use constant energy_to_build => 99;

use constant ore_to_build => 99;

use constant water_to_build => 100;

use constant waste_to_build => 84;

use constant time_to_build => 180;

use constant food_consumption => 84;

use constant energy_consumption => 12;

use constant ore_consumption => 3;

use constant water_consumption => 84;

use constant waste_production => 2;

has spies_in_training_count => (
    is          => 'rw',
    lazy        => 1,
    default     => sub {
        my $self = shift;
        return $self->get_spies->search({task=>'Mayhem Training'})->count;
    },
);

sub get_spies {
    my ($self) = @_;
    return Lacuna->db->resultset('Lacuna::DB::Result::Spies')
                 ->search({ empire_id => $self->body->empire_id,
                            on_body_id => $self->body_id,
                            mayhem_xp => {'<', 2600} });
}

sub get_spy {
    my ($self, $spy_id) = @_;
    my $spy = Lacuna->db->resultset('Lacuna::DB::Result::Spies')->find($spy_id);
    unless (defined $spy) {
        confess [1002, 'No such spy.'];
    }
    if ($spy->empire_id ne $self->body->empire_id) {
        confess [1013, "You don't control that spy."];
    }
    if ($spy->on_body_id != $self->body->id) {
        confess [1013, "Spy must be on planet to train."];
    }
    if ($spy->on_body_id != $self->body->id) {
        confess [1013, "Spy must be on planet to train."];
    }
    if ($spy->mayhem_xp >= 2600) {
        confess [1013, $spy->name." has already learned all there is to know about Mayhem."];
    }
    return $spy;
}

has training_multiplier => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $multiplier = $self->level;
        $multiplier = 1 if $multiplier < 1;
        return $multiplier;
    }
);

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
