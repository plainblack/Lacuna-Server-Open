package Lacuna::DB::ResultSet::SitterAuths;

use Moose;
use utf8;
extends 'Lacuna::DB::ResultSet';
use DateTime;

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

sub new_auth_date { DateTime->now->add(days => 60) }

sub hire_sitter
{
    my ($self, %opts) = @_;
    die "Invalid hiring" unless ($opts{sitter} || $opts{sitter_id}) && ($opts{baby} || $opts{baby_id});

    my $sitter = $opts{sitter} || $self->empire($opts{sitter_id});
    my $baby   = $opts{baby}   || $self->empire($opts{baby_id});

    __PACKAGE__->new({
                  sitter_id   => $sitter->id,
                  baby_id     => $baby->id,
                  expiry      => new_auth_date(),
              })->insert;
}

sub clean_expired
{
    my ($self) = @_;

    my $db = Lacuna->db;
    my $dtf = $db->storage->datetime_parser;
    my $too_old = $dtf->format_datetime(DateTime->now);

    $self->search({ expiry => { '<', $too_old } })->delete;
}

#sub 

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
