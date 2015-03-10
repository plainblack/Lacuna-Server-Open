package Lacuna::DB::Result::News;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result';
use Lacuna::Util qw(format_date);
use UUID::Tiny ':std';

__PACKAGE__->table('news');
__PACKAGE__->add_columns(
    headline                => { data_type => 'varchar', size => 140, is_nullable => 0 },
    zone                    => { data_type => 'varchar', size => 16, is_nullable => 0 },
    date_posted             => { data_type => 'datetime', is_nullable => 0, set_on_create => 1 },
);

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;
    $sqlt_table->add_index(name => 'idx_zone_date_posted', fields => ['zone','date_posted']);
    $sqlt_table->add_index(name => 'idx_date_posted', fields => ['date_posted']);
}

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
    return 'network19/'.create_uuid_as_string(UUID_MD5, $zone.Lacuna->config->get('feeds/bucket')).'.rss';
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
