package Lacuna::Role::Fleet::Arrive::CargoExchange;

use strict;
use Moose::Role;

after handle_arrival_procedures => sub {
    my ($self) = @_;
    
    if ($self->direction eq 'out' and $self->foreign_body->empire_id) {
        if ($self->foreign_body->isa('Lacuna::DB::Result::Map::Body::Planet::Station')) {
            my $amount = 0;
            my $payload = $self->payload;
            if (exists $payload->{resources}) {
                my %resources = %{$payload->{resources}};
                foreach my $type (keys %resources) {
                    $amount += $resources{$type};
                }
            }
            if ($amount > 0) {
                $self->body->empire->pay_taxes($self->foreign_body->id, $amount);
            }
        }
        $self->unload($self->foreign_body);
    }
    elsif ($self->direction eq 'in') {
        $self->unload($self->body);
    }
};

1;
