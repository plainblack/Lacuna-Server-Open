package Lacuna::DB::Result::Votes;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::DB::Result';
use Lacuna::Util qw(format_date);
use Lacuna::Constants qw(FOOD_TYPES ORE_TYPES);
use DateTime;

__PACKAGE__->table('alliance');
__PACKAGE__->add_columns(
    proposition_id          => { data_type => 'int', is_nullable => 0 },
    empire_id               => { data_type => 'int', is_nullable => 0 },
    vote                    => { data_type => 'int', is_nullable => 0, default_value => 0 },
); 

__PACKAGE__->belongs_to('proposition', 'Lacuna::DB::Result::Propositions', 'proposition_id');
__PACKAGE__->belongs_to('empire', 'Lacuna::DB::Result::Empire', 'empire_id');


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
