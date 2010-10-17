package Lacuna::DB::Result::Ships::Probe;

use Moose;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Ships';

use constant prereq         => { class=> 'Lacuna::DB::Result::Building::Observatory',  level => 1 };
use constant base_food_cost      => 100;
use constant base_water_cost     => 300;
use constant base_energy_cost    => 2000;
use constant base_ore_cost       => 1700;
use constant base_time_cost      => 3600;
use constant base_waste_cost     => 500;
use constant base_speed     => 5000;
use constant base_stealth   => 0;
use constant base_hold_size => 0;

around 'build_tags' => sub {
    my ($orig, $class) = @_;
    return ($orig->($class), qw(Exploration Intelligence));
};

sub arrive {
    my ($self) = @_;
    my $empire = $self->body->empire;
    $empire->add_probe($self->foreign_star_id, $self->body_id);
    $self->delete;
}

sub can_send_to_target {
    my ($self, $target) = @_;
    confess [1009, 'Can only be sent to stars.'] unless ($target->isa('Lacuna::DB::Result::Map::Star'));
    my $body = $self->body;
    my $count = Lacuna->db->resultset('Lacuna::DB::Result::Probes')->search({ body_id => $body->id })->count;
    $count += Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({ body_id => $body->id, type=>'probe', task=>'Travelling' })->count;
    my $max_probes = 0;
    my $observatory = $body->get_buildings_of_class('Lacuna::DB::Result::Building::Observatory')->next;
    if (defined $observatory) {
        $max_probes = $observatory->max_probes;
    }
    confess [ 1009, 'You are already controlling the maximum amount of probes for your Observatory level.'] if ($count >= $max_probes);
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
