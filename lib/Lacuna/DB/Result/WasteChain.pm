package Lacuna::DB::Result::WasteChain;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result';

__PACKAGE__->table('waste_chain');
__PACKAGE__->add_columns(
    planet_id                       => { data_type => 'int', size => 11, is_nullable => 0 },
    star_id                         => { data_type => 'int', size => 11, is_nullable => 0 },
    waste_hour                      => { data_type => 'int', size => 11, default_value => 0 },
    percent_transferred             => { data_type => 'int', size => 11, default_value => 0 },
);

__PACKAGE__->belongs_to('star', 'Lacuna::DB::Result::Map::Star', 'star_id');
__PACKAGE__->belongs_to('planet', 'Lacuna::DB::Result::Map::Body', 'planet_id');

sub get_status {
    my ($self) = @_;

    my $star = $self->star;
    return {
        id      => $self->id,
        star    => {
            id      => $star->id,
            name    => $star->name,
            color   => $star->color,
            x       => $star->x,
            y       => $star->y,
        },
        waste_hour  => $self->waste_hour,
        percent_transferred => $self->percent_transferred,
    };
}


no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
