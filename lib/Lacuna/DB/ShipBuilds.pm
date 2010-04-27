package Lacuna::DB::ShipBuilds;

use Moose;
extends 'SimpleDB::Class::Item';
use Lacuna::Util qw(format_date);
use DateTime;

__PACKAGE__->set_domain_name('ship_builds');
__PACKAGE__->add_attributes(
    shipyard_id             => { isa => 'Str' },
    body_id                 => { isa => 'Str' },
    date_completed          => { isa => 'DateTime' },
    type                    => { isa => 'Str' },
);

__PACKAGE__->belongs_to('shipyard', 'Lacuna::DB::Building::Shipyard', 'shipyard_id');
__PACKAGE__->belongs_to('body', 'Lacuna::DB::Body::Planet', 'body_id');




no Moose;
__PACKAGE__->meta->make_immutable;
