package Lacuna::DB::Result::Propositions;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result';
use Lacuna::Util qw(format_date);
use Lacuna::Constants qw(FOOD_TYPES ORE_TYPES);
use DateTime;

__PACKAGE__->table('alliance');
__PACKAGE__->add_columns(
    name                    => { data_type => 'varchar', size => 30, is_nullable => 0 },
    station_id              => { data_type => 'int', size => 11, is_nullable => 0 },
    votes_needed            => { data_type => 'int', is_nullable => 0, default_value => 1 },
    votes_yes               => { data_type => 'int', is_nullable => 0, default_value => 0 },
    votes_no                => { data_type => 'int', is_nullable => 0, default_value => 0 },
    description             => { data_type => 'text', is_nullable => 1 },
    consequence             => { data_type => 'text', is_nullable => 1 },
    type                    => { data_type => 'varchar', size => 15, is_nullable => 0 },
    scratch                 => { data_type => 'mediumblob', is_nullable => 1, 'serializer_class' => 'JSON' },
); 

__PACKAGE__->belongs_to('station', 'Lacuna::DB::Result::Map::Body', 'station_id');


sub date_created_formatted {
    my ($self) = @_;
    return format_date($self->date_created);
}

sub get_status {
    my $self = shift;
    my $members = $self->members;
    my @members_list;
    while (my $member = $members->next) {
        push @members_list, {
            empire_id   => $member->id,
            name        => $member->name,
        };
    }
    return {
        id              => $self->id,
        members         => \@members_list,
        leader_id       => $self->leader_id,
        forum_uri       => $self->forum_uri,
        description     => $self->description,
        name            => $self->name,
        announcements   => $self->announcements,
        date_created    => $self->date_created_formatted,
    };
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
