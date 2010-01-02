package Lacuna::DB::Body::Asteroid;

use Moose;
extends 'Lacuna::DB::Body';


__PACKAGE__->add_attributes(
    size            => { isa => 'Int' },
);

no Moose;
__PACKAGE__->meta->make_immutable;

