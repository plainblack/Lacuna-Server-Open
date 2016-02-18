package Lacuna::DB::Result::Captcha;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result';
use Lacuna::Util;

__PACKAGE__->table('captcha');
__PACKAGE__->add_columns(
    riddle                  => { data_type => 'varchar', size => 12, is_nullable => 0 },
    solution                => { data_type => 'varchar', size => 5, is_nullable => 0 },
    guid                    => { data_type => 'varchar', size => 36, is_nullable => 0 },
    created                 => { data_type => 'datetime', is_nullable => 0, set_on_create => 1 },
);

sub uri {
    my $self = shift;
    return Lacuna->config->get('server_url').'/captcha/'.substr($self->guid,0,2).'/'.$self->guid.'.png';
}




no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
