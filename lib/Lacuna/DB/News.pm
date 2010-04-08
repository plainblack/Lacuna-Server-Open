package Lacuna::DB::News;

use Moose;
extends 'SimpleDB::Class::Item';
use Lacuna::Util qw(format_date);

__PACKAGE__->set_domain_name('news');
__PACKAGE__->add_attributes(
    headline                => { isa => 'Str' },
    zone                    => { isa => 'Str' },
    date_posted             => { isa => 'DateTime'},
);

sub date_posted_formatted {
    my $self = shift;
    return format_date($self->date_posted);
}


no Moose;
__PACKAGE__->meta->make_immutable;
