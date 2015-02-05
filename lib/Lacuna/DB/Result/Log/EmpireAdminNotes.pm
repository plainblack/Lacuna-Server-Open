package Lacuna::DB::Result::Log::EmpireAdminNotes;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result::Log::WithEmpire';
use Lacuna::Util;

__PACKAGE__->table('empire_admin_notes');
__PACKAGE__->add_columns(
    notes                       => { data_type => 'text', is_nullable => 0 },
    creator                     => { data_type => 'varchar', size => 30, is_nullable => 0 },
);

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;
