package LR;

use Class::Load qw(load_first_existing_class);

# Intended to be used from the command line to save a bunch of typing.

# This "derives" off Lacuna::RPC, and is simply a shortcut for
# Lacuna::RPC::...->new:
# perl -ML -MData::Dump -e 'dd(LR->Empire->view_profile(LD->empire(2))'

our $AUTOLOAD;
sub AUTOLOAD
{
    my $self = shift;
    my $ns   = $AUTOLOAD;
    $ns =~ s/^.*:://;

    $ns = load_first_existing_class "Lacuna::RPC::$ns", "Lacuna::RPC::Building::$ns";

    $ns->new();
}

1;
