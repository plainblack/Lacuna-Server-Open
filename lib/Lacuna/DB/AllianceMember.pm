package Lacuna::DB::AllianceMember;

use Moose;
extends 'SimpleDB::Class::Item';

__PACKAGE__->set_domain_name('alliance_member');
__PACKAGE__->add_attributes(
    alliance_id     => { isa => 'Str' },
    empire_id       => { isa => 'Str' },
    joined_on       => { isa => 'DateTime' },
    is_commander    => { isa => 'Str', default=>0 },
    status_message  => { isa => 'Str' },
);

__PACKAGE__->belongs_to('alliance', 'Lacuna::DB::Alliance', 'alliance_id');
__PACKAGE__->belongs_to('empire', 'Lacuna::DB::Empire', 'empire_id');

no Moose;
__PACKAGE__->meta->make_immutable;
