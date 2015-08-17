package Lacuna::DB::ResultSet::SitterAuths;

use Moose;
use utf8;
extends 'Lacuna::DB::ResultSet';
use DateTime;

use constant VALID_AUTH_DAYS => 60;
use constant AUTH_WARNING_DAYS => 7;

sub remove_auths_from_alliance
{
    my ($self, $user) = @_;

    # if it was a name or id, convert to object so we can find the alliance_id.
    $user = $self->user($user) unless ref $user;

    my @ids = Lacuna->db->resultset('empire')->
        search(
               {
                   alliance_id => $user->alliance_id,
               }
              )->get_column('id')->all;

    $self->search({ baby_id => { -in => \@ids }, sitter_id => $user->id })->delete;
    $self->search({ sitter_id => { -in => \@ids }, baby_id => $user->id })->delete;
}

sub new_auth_date { DateTime->now->add(days => VALID_AUTH_DAYS) }

sub clean_expired
{
    my ($self) = @_;

    $self->search({ expiry => { '<', \q[UTC_TIMESTAMP()] } })->delete;
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
