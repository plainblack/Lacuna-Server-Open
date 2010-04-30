package Lacuna::DB::Probes;

use Moose;
extends 'SimpleDB::Class::Item';
use Lacuna::Util qw(format_date);
use DateTime;

__PACKAGE__->set_domain_name('probes');
__PACKAGE__->add_attributes(
    empire_id               => { isa => 'Str' },
    star_id                 => { isa => 'Str' },
    body_id                 => { isa => 'Str' },
);

__PACKAGE__->belongs_to('empire', 'Lacuna::DB::Empire', 'empire_id');
__PACKAGE__->belongs_to('star', 'Lacuna::DB::Star', 'star_id');
__PACKAGE__->belongs_to('body', 'Lacuna::DB::Body::Planet', 'body_id');


no Moose;
__PACKAGE__->meta->make_immutable;
