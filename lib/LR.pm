package LR;

use Class::Load qw(load_first_existing_class);
use strict;
use warnings;
use Scalar::Util qw(blessed);
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
         if (blessed $_) {
             if (ref =~ /Exception/)
             {
                 $_
             }
             else
             {
                 eval { $_->id } || ref $_
             }
         } elsif (ref $_ eq 'HASH') {
             my $x = $_;
             +{
                 map {
                     my $o = $x->{$_};
                     if (eval { $o->can('id') })
                     {
                         $_ => $o->id;
                     }
                     elsif ((ref $o) =~ /^Lacuna/)
                     {
                         $_ => ref $o;
                     }
                     else
                     {
                         $_ => $o;
                     }
                 } keys %$x
             }
         } else {
             $_
         }
     } @_ 
    ];
}

sub _session
{
    my $session;
    if (ref $_[0] eq 'Lacuna::DB::Result::Empire')
    {
        # create a session for it.
        $session = $_[0]->start_session;
        $_[0] = $session->id;
    }
    if (ref $_[0] eq 'HASH' && exists $_[0]->{session_id} && ref $_[0]->{session_id} eq 'Lacuna::DB::Result::Empire')
    {
        # create a session for it.
        $session = $_[0]->{session_id}->start_session;
        $_[0]->{session_id} = $session->id;
    }
    if ($ENV{captcha})
    {
        Lacuna->cache->set('captcha_valid', $session->id, 1, 60 * 30 );
    }
    @_
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
    my $rc = eval { $type->new->$method(_session @_) } || $@;
    print "RESULT: ";
    Data::Dump::dd(_clean $rc);
}

sub jcall
{
    my $class = shift;
    my $type  = shift;
    my $method= shift;
    require JSON::XS;

    $type = load_first_existing_class "Lacuna::RPC::$type", "Lacuna::RPC::Building::$type";


    say "Class: $type";
    say "method: $method";
    say "REQUEST params: ", JSON::XS::encode_json(_clean @_);
    my $rc = eval { $type->new->$method(_session @_) } || $@;
    say "RESULT: ", JSON::XS::encode_json(ref $rc ? $rc : [$rc]);
}


1;
