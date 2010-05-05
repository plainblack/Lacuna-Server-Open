package Lacuna::DB::Ships;

use Moose;
extends 'Lacuna::DB::Result';
use Lacuna::Util qw(format_date);
use DateTime;

__PACKAGE__->table('ship_builds');
__PACKAGE__->add_columns(
    shipyard_id             => { data_type => 'int', size => 11, is_nullable => 0 },
    body_id                 => { data_type => 'int', size => 11, is_nullable => 0 },
    date_completed          => { data_type => 'datetime', is_nullable => 0, default_value => DateTime->now },
    type                    => { data_type => 'char', size => 30, is_nullable => 0 },
    probe_count                         => { isa => 'Int', default => 0 },
    colony_ship_count                   => { isa => 'Int', default => 0 },
    spy_pod_count                       => { isa => 'Int', default => 0 },
    cargo_ship_count                    => { isa => 'Int', default => 0 },
    space_station_count                 => { isa => 'Int', default => 0 },
    smuggler_ship_count                 => { isa => 'Int', default => 0 },
    mining_platform_ship_count          => { isa => 'Int', default => 0 },
    terraforming_platform_ship_count    => { isa => 'Int', default => 0 },
    gas_giant_settlement_platform_ship_count     => { isa => 'Int', default => 0 },
);

__PACKAGE__->belongs_to('shipyard', 'Lacuna::DB::Building::Shipyard', 'shipyard_id');
__PACKAGE__->belongs_to('body', 'Lacuna::DB::Body::Planet', 'body_id');

sub date_completed_formatted {
    my $self = shift;
    return format_date($self->date_completed);
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
