package LD;

# Intended to be used from the command line to save a bunch of typing.

# This "derives" off Lacuna::DB, and is simply a shortcut for
# typing Lacuna->db:
# perl -ML -E 'say LD->empire(2)->name'
# perl -ML -MData::Dump -e 'dd(Lacuna::RPC::Empire->new->view_profile(LD->empire(2))'

use L;

our $AUTOLOAD;
sub AUTOLOAD
{
    my $self = shift;
    my $func = $AUTOLOAD;
    $func =~ s/^.*:://;

    my $db = L->db;

    if (my $code = $db->can($func))
    {
        return $db->$code(@_);
    }
    else
    {
        die "Lacuna::DB cannot $func\n";
    }
}

1;
