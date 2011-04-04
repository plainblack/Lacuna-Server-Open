package Lacuna::DB::Result::Propositions::ForeignAid;

use Moose;
use utf8;
use DateTime;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Propositions';

before pass => sub {
    my ($self) = @_;
    my $resources = $self->scratch->{resources};
    my $planet_id = $self->scratch->{planet_id};
    my $planet = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')->find($planet_id);
    if (defined $planet) {
        if ($planet->star->station_id == $self->body_id) {
            my $finish = DateTime->now;
            my $supply_pod = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->new({
                body_id         => $self->station_id,
                type            => 'supply_pod',
                hold_size       => $self->scratch->{resource},
                date_available  => $finish,
            });
            $supply_pod->send(target => $planet);
        }
        else {
        }
    }
    else {
    }

};

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
