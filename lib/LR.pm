package LR;

use Class::Load qw(load_first_existing_class);
use 5.12.0;

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

# perl -ML -E 'LR->call(Empire=>view_profile=>LD->empire(2))'

sub _clean(@)
{
    [
     map {
         if (ref $_) {
             eval { $_->id } || ref $_
         } else {
             $_
         }
     } @_ 
    ];
}

sub call
{
    my $class = shift;
    my $type  = shift;
    my $method= shift;

    require Data::Dump;
    $type = load_first_existing_class "Lacuna::RPC::$type", "Lacuna::RPC::Building::$type";

    print "REQUEST: ";
    Data::Dump::dd(_clean @_);
    my $rc = eval { $type->new->$method(@_) } || $@;
    print "RESULT: ";
    Data::Dump::dd($rc);
}

sub jcall
{
    my $class = shift;
    my $type  = shift;
    my $method= shift;
    require JSON::XS;

    $type = load_first_existing_class "Lacuna::RPC::$type", "Lacuna::RPC::Building::$type";

    if (ref $_[0] eq 'Lacuna::DB::Result::Empire')
    {
        # create a session for it.
        $_[0] = $_[0]->start_session->id;
    }
    if (ref $_[0] eq 'HASH' && exists $_[0]->{session_id} && ref $_[0]->{session_id})
    {
        # create a session for it.
        $_[0]->{session_id} = $_[0]->{session_id}->start_session->id;
    }

    say "Class: $type";
    say "method: $method";
    say "REQUEST params: ", JSON::XS::encode_json(_clean @_);
    my $rc = eval { $type->new->$method(@_) } || $@;
    say "RESULT: ", JSON::XS::encode_json(ref $rc ? $rc : [$rc]);
}


1;
