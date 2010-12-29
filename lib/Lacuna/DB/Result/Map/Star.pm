package Lacuna::DB::Result::Map::Star;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Map';
use Lacuna::Util;

__PACKAGE__->table('star');
__PACKAGE__->add_columns(
    color                   => { data_type => 'varchar', size => 7, is_nullable => 0 },
);

__PACKAGE__->has_many('bodies', 'Lacuna::DB::Result::Map::Body', 'star_id');


sub get_status {
    my ($self, $empire, $override_probe) = @_;
    my $out = {
        color           => $self->color,
        name            => $self->name,
        id              => $self->id,
        x               => $self->x,
        y               => $self->y,
        zone            => $self->zone,
    };
    if (defined $empire) {
        if ($override_probe || $self->id ~~ $empire->probed_stars) {
            my @orbits;
            my $bodies = $self->bodies;
            while (my $body = $bodies->next) {
                push @orbits, $body->get_status($empire);
            }
            $out->{bodies} = \@orbits;
        }
    }
    return $out;
}




no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
