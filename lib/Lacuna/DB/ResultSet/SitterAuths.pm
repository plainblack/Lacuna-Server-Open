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

    my $dtf = Lacuna->db->storage->datetime_parser;
    my $now = $dtf->format_datetime(DateTime->now);

    # set the expiry to immediate.
    $self->search({ baby_id => { -in => \@ids }, sitter_id => $user->id })->update({expiry => $now});
    $self->search({ sitter_id => { -in => \@ids }, baby_id => $user->id })->update({expiry => $now});
}

sub new_auth_date { DateTime->now->add(days => VALID_AUTH_DAYS) }

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
