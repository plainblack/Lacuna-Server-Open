package Lacuna::DB::Alliance;

use Moose;
extends 'SimpleDB::Class::Item';

__PACKAGE__->set_domain_name('alliance');
__PACKAGE__->add_attributes(
    name                => { isa => 'Str' },
    date_created        => { isa => 'DateTime' },
    description         => { isa => 'Str' },
    motd                => { isa => 'Str' },
    forum_url           => { isa => 'Str' },
    web_site_url        => { isa => 'Str' },
);

__PACKAGE__->has_many('members', 'Lacuna::DB::AllianceMember', 'alliance_id');
__PACKAGE__->has_many('commanders', 'Lacuna::DB::AllianceMember', 'alliance_id', {is_commander=>1});

no Moose;
__PACKAGE__->meta->make_immutable;
