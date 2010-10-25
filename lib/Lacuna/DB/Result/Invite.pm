package Lacuna::DB::Result::Invite;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result';

__PACKAGE__->table('invite');
__PACKAGE__->add_columns(
    inviter_id              => { data_type => 'int', is_nullable => 0 },
    zone                    => { data_type => 'varchar', size => 16, is_nullable => 0 },
    invitee_id              => { data_type => 'int', is_nullable => 1 },
    email                   => { data_type => 'varchar', size => 255, is_nullable => 1 },
    code                    => { data_type => 'varchar', size => 36, is_nullable => 0 },
    invite_date             => { data_type => 'datetime', is_nullable => 0, set_on_create => 1 },
    accept_date             => { data_type => 'datetime', is_nullable => 0, set_on_create => 1 },
);

__PACKAGE__->belongs_to('inviter', 'Lacuna::DB::Result::Empire', 'inviter_id');
__PACKAGE__->belongs_to('invitee', 'Lacuna::DB::Result::Empire', 'invitee_id');

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
