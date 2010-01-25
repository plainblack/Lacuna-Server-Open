package Lacuna::Body;

use Moose;
extends 'JSON::RPC::Dispatcher::App';
use Lacuna::Util qw(in);
use Lacuna::Verify;

has simpledb => (
    is      => 'ro',
    required=> 1,
);

with 'Lacuna::Role::Sessionable';

sub rename {
    my ($self, $session_id, $body_id, $name) = @_;
    Lacuna::Verify->new(content=>\$name, throws=>[1000,'Name not available.',$name])
        ->length_gt(2)
        ->length_lt(31)
        ->no_restricted_chars
        ->no_profanity
        ->not_ok($self->simpledb->domain('body')->count({cname=>Lacuna::Util::cname($name), id=>['!=',$body_id]})); # name available
    my $body = $self->simpledb->domain('body')->find($body_id);
    if (defined $body) {
        my $empire = $self->get_empire_by_session($session_id);
        if ($body->empire_id eq $empire->id) {
            $body->update({
                name        => $name,
            })->put;
            return 1;
        }
        else {
            confess [1010, "Can't rename a body that you don't inhabit."];
        }
    }
    else {
        confess [1002, 'Body does not exist.', $body_id];
    }
}

sub get_buildings {
    my ($self, $session_id, $body_id) = @_;
    my $body = $self->simpledb->domain('body')->find($body_id);
    if (defined $body) {
        my $empire = $self->get_empire_by_session($session_id);
        if ($body->empire_id eq $empire->id) {
            my $db = $self->simpledb;
            my %out;
            foreach my $domain (qw(farm factory)) {
                my $buildings = $db->domain($domain);
                while (my $building = $buildings->next) {
                    $out{$building->id} = (
                        url     => $building->url,
                        image   => $building->image,
                        name    => $building->name,
                        x       => $building->x,
                        y       => $building->y,
                        level   => $building->level,
                    );
                }
            }
            return {buildings=>\%out, status=>$empire->get_status};
        }
        else {
            confess [1010, "Can't view a planet you don't inhabit."];
        }
    }
    else {
        confess [1002, 'Body does not exist.', $body_id];
    }
}



__PACKAGE__->register_rpc_method_names(qw(rename get_buildings));

no Moose;
__PACKAGE__->meta->make_immutable;

