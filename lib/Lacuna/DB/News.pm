package Lacuna::DB::News;

use Moose;
extends 'SimpleDB::Class::Item';
use Lacuna::Util qw(format_date);
use UUID::Tiny ':std';

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

sub feed_url {
    my ($class, $zone) = @_;
    my $config = Lacuna->config;
    Lacuna->config->get('feeds/url').$class->feed_filename($zone);
}

sub feed_filename {
    my ($class, $zone) = @_;
    return create_uuid_as_string(UUID_MD5, $zone.Lacuna->config->get('feeds/bucket')).'.rss';
}

no Moose;
__PACKAGE__->meta->make_immutable;
