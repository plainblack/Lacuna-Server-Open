package Lacuna::DB::Result::SupplyChain;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result';

__PACKAGE__->table('supply_chain');
__PACKAGE__->add_columns(
    planet_id                       => { data_type => 'int', size => 11, is_nullable => 0 },
    building_id                     => { data_type => 'int', size => 11, is_nullable => 0 },
    target_id                       => { data_type => 'int', size => 11, is_nullable => 0 },
    resource_hour                   => { data_type => 'int', size => 11, default_value => 0 },
    resource_type                   => { data_type => 'varchar', default_value => '' },
    percent_transferred             => { data_type => 'int', size => 11, default_value => 0 },
    stalled                         => { data_type => 'int', size => 11, default_value => 0 },
);

__PACKAGE__->belongs_to('target', 'Lacuna::DB::Result::Map::Body', 'target_id');
__PACKAGE__->belongs_to('building', 'Lacuna::DB::Result::Building', 'building_id');
__PACKAGE__->belongs_to('planet', 'Lacuna::DB::Result::Map::Body', 'planet_id');

sub get_status {
    my ($self) = @_;

    my $target = $self->target;
    return {
        id      => $self->id,
        body    => {
            id      => $target->id,
            name    => $target->name,
            x       => $target->x,
            y       => $target->y,
            image   => $target->image,
        },
        building_id    => $self->building_id,
        resource_hour  => $self->resource_hour,
        resource_type  => $self->resource_type,
        percent_transferred => $self->percent_transferred,
        stalled        => $self->stalled,
    };
}

sub get_incoming_status {
    my ($self) = @_;

    my $planet = $self->planet;
    return {
        id      => $self->id,
        from_body   => {
            id      => $planet->id,
            name    => $planet->name,
            x       => $planet->x,
            y       => $planet->y,
            image   => $planet->image,
        },
        building_id    => $self->building_id,
        resource_hour  => $self->resource_hour,
        resource_type  => $self->resource_type,
        stalled        => $self->stalled,
        percent_transferred => $self->percent_transferred,
    };
}


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
