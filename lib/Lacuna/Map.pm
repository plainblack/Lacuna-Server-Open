package Lacuna::Map;

use Moose;
extends 'JSON::RPC::Dispatcher::App';
use Lacuna::Verify;
use Lacuna::Constants qw(ORE_TYPES);

has simpledb => (
    is      => 'ro',
    required=> 1,
);

with 'Lacuna::Role::Sessionable';


sub check_star_for_incoming_probe {
    my ($self, $session_id, $star_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $date = 0;
    my $bodies = $empire->body_ids;
    my $incoming = Lacuna->db->resultset('travel_queue')->search(where => {foreign_star_id=>$star_id, ship_type=>'probe'});
    while (my $probe = $incoming->next) {
        if ($probe->body_id ~~ $bodies) {
            $date = $incoming->date_arrives_formatted;
        }
    }
    return {
        status  => $empire->get_status,
        incoming_probe  => $date,
    };
}


sub get_star_by_body {
    my ($self, $session_id, $body_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $body = Lacuna->db->resultset('Lacuna::DB::Result::Body')->find($body_id);
    # we don't do any privilege checking because it's assumed if you know the body id you can access the star,
    # plus, it's not like you couldn't get the info it sends back via the get_stars method anyway
    if (defined $body) {
        my $star = $body->star;
        return {
            star    => {
                x           => $star->x,
                y           => $star->y,
                z           => $star->z,
                name        => $star->name,
                id          => $star->id,
            },
            status  => $empire->get_status,
        };
    }
    else {
        confess [1002, 'Body does not exist.', $body_id];
    }
}

sub load_star {
    my ($self, $star_id) = @_;
    my $star;
    if (ref $star_id eq 'Lacuna::DB::Result::Star') { 
        $star = $star_id;
    }
    else {
        $star = Lacuna->db->resultset('star')->find($star_id);
    }
    return $star;
}

sub get_star_system {
    my ($self, $session, $star_id) = @_;
    my $empire = $self->get_empire_by_session($session);

    # get the star in question
    my $star = $self->load_star($star_id);

    # exceptions
    unless (defined $star) {
        confess [1002, 'Star does not exist.', $star_id];
    }
    unless ($star->id ~~ $empire->probed_stars) {
        confess [1010, 'Must have probed the star system to view it.'];
    }

    # get to work
    my $bodies = $star->bodies;
    my %out;
    while (my $body = $bodies->next) {
        $out{$body->id} = $body->get_status($empire);
        if ($body->isa('Lacuna::DB::Result::Body::Planet') && $body->empire_id ne 'None') {
            my $owner_empire = $body->empire;
            if (defined $owner_empire) {
                $out{$body->id}{empire} = {
                    id      => $body->empire_id,
                    name    => $owner_empire->name,
                };
            }
            else {
                warn "Deleted vestigial relationship between empire ".$body->empire_id." and body ".$body->id;
                $body->empire_id(undef);
                $body->put;
            }
        }
    }
    return {
        star    => $star->get_status,
        bodies  => \%out,
        status  => $empire->get_status,
    }
}

sub get_star_system_by_body {
    my ($self, $session_id, $body_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $body = Lacuna->db->resultset('Lacuna::DB::Result::Body')->find($body_id);
    if (defined $body) {
        my $star = $body->star;
        return $self->get_star_system($empire, $star);
    }
    else {
        confess [1002, 'Body does not exist.', $body_id];
    }
}

sub get_stars {
    my ($self, $session_id, $x1, $y1, $x2, $y2, $z) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my ($startx,$starty,$endx,$endy);
    if ($x1 > $x2) { $startx = $x2; $endx = $x1; } else { $startx = $x1; $endx = $x2; } # organize x
    if ($y1 > $y2) { $starty = $y2; $endy = $y1; } else { $starty = $y1; $endy = $y2; } # organize y
    if ((abs($endx - $startx) * abs($endy - $starty)) > 121) {
        confess [1003, 'Requested area too large.'];
    }
    else {
        my $stars = Lacuna->db->resultset('Lacuna::DB::Result::Star')->search({z=>$z, y=> {between => [$starty, $endy]}, x=>{between => [$startx, $endx]}});
        my @out;
        while (my $star = $stars->next) {
            push @out, $star->get_status($empire);
        }
        return { stars=>\@out, status=>$empire->get_status };
    }
}



__PACKAGE__->register_rpc_method_names(qw(get_stars get_star_by_body get_star_system get_star_system_by_body check_star_for_incoming_probe));

no Moose;
__PACKAGE__->meta->make_immutable;

