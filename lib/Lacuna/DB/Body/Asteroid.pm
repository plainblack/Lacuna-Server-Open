package Lacuna::DB::Body::Asteroid;

use Moose;
extends 'Lacuna::DB::Body';

has '+image' => (
    default => '4.png';
);

__PACKAGE__->add_attributes(
    size            => { isa => 'Int' },
);

no Moose;
__PACKAGE__->meta->make_immutable;

