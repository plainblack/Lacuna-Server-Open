package Lacuna::DB::News;

use Moose;
extends 'Lacuna::DB::Result';
use Lacuna::Util qw(format_date);
use UUID::Tiny ':std';

__PACKAGE__->table('news');
__PACKAGE__->add_columns(
    headline                => { data_type => 'char', size => 140, is_nullable => 0 },
    zone                    => { data_type => 'char', size => 16, is_nullable => 0 },
    date_posted             => { data_type => 'datetime', is_nullable => 0, default_value => DateTime->now },
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
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
