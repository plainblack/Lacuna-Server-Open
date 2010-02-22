package Lacuna::Map;

use Moose;
extends 'JSON::RPC::Dispatcher::App';
use Lacuna::Util qw(in);
use Lacuna::Verify;
use Lacuna::Constants qw(ORE_TYPES);

has simpledb => (
    is      => 'ro',
    required=> 1,
);

with 'Lacuna::Role::Sessionable';

sub rename_star {
    my ($self, $session_id, $star_id, $name) = @_;
    Lacuna::Verify->new(content=>\$name, throws=>[1000,'Name not available.',$name])
        ->length_gt(2)
        ->length_lt(31)
        ->no_restricted_chars
        ->no_profanity
        ->not_ok($self->simpledb->domain('star')->count({cname=>Lacuna::Util::cname($name), id=>['!=',$star_id]})); # name available
    my $empire = $self->get_empire_by_session($session_id);
    my $star = $self->simpledb->domain('star')->find($star_id);
    if (defined $star) {
        if ($star->is_named) {
            confess [1010, "Can't rename a star that's already named."];
        }
        else {
            my $bodies = $star->bodies->count({empire_id=>$empire->id});
            if ($bodies) {
                $star->update({
                    name        => $name,
                    is_named    => 1,
                })->put;
                return 1;
            }
            else {
                confess [1010, "Can't renamed a star that you don't inhabit."];
            }
        }
    }
    else {
        confess [1002, 'Star does not exist.', $star_id];
    }
}

sub get_stars_near_body {
    my ($self, $session_id, $body_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $body = $self->simpledb->domain('body')->find($body_id);
    if (defined $body) {
        my $star = $body->star;
        return $self->get_stars($empire, $star->x - 5, $star->y - 5, $star->x + 5, $star->y + 5, $star->z); 
    }
    else {
        confess [1002, 'Planet does not exist.'];
    }
}

sub get_star_by_body {
    my ($self, $session_id, $body_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $body = $self->simpledb->domain('body')->find($body_id);
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
                can_rename  => ($star->is_named) ? 0 : 1,
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
    if (ref $star_id eq 'Lacuna::DB::Star') { 
        $star = $star_id;
    }
    else {
        $star = $self->simpledb->domain('star')->find($star_id);
    }
    return $star;
}

sub get_star_system {
    my ($self, $session, $star_id) = @_;
    my $empire = $self->get_empire_by_session($session);

    # get the star in question
    my $star = $self->load_star($star_id);

    # get to work
    if (defined $star) {
        my $bodies = $star->bodies;
        my $member = 0;
        my %out;
        while (my $body = $bodies->next) {
            my $owner = {};
            if ($body->isa('Lacuna::DB::Body::Planet') && $body->empire_id ne 'None') {
                my $owner_empire = $body->empire;
                if (defined $owner_empire) {
                    if ($body->empire_id eq $empire->id) {
                        $member = 1;
                    }
                    $owner = {
                        id      => $body->empire_id,
                        name    => $owner_empire->name,
                    };
                }
                else {
                    warn "Deleted vestigial relationship between empire ".$body->empire_id." and body ".$body->id;
                    $body->empire_id('None');
                    $body->put;
                }
            }
            my %ores;
            if ($body->isa('Lacuna::DB::Planet')) {
                foreach my $type (ORE_TYPES) {
                    $ores{$type} = $body->$type();
                }
            }
            $out{$body->id} = {
                name        => $body->name,
                image       => $body->image,
                empire      => $owner,
                ore         => \%ores,
                water       => ($body->isa('Lacuna::DB::Planet')) ? $body->water : 0,
                orbit       => $body->orbit,
           };
        }
        if ($member || in($star->id, $empire->probed_stars)) {
            return {
                star    => {
                    color       => $star->color,
                    name        => $star->name,
                    id          => $star->id,
                    can_rename  => (($star->is_named) ? 0 : 1),
                    x           => $star->x,
                    y           => $star->y,
                    z           => $star->z,
                },
                bodies  => \%out,
                status  => $empire->get_status,
            }
        }
        else {
            confess [1010, 'Must have probed the star system to view it.'];
        }
    }
    else {
        confess [1002, 'Star does not exist.', $star_id];
    }
}

sub get_star_system_by_body {
    my ($self, $session_id, $body_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $body = $self->simpledb->domain('body')->find($body_id);
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
        my $stars = $self->simpledb->domain('star')->search({z=>$z, y=>['between', $starty, $endy], x=>['between', $startx, $endx]});
        my @out;
        while (my $star = $stars->next) {
            my $alignment = 'unprobed';
            if (in($star->id, $empire->probed_stars)) {
                $alignment = 'probed';
                my $bodies = $star->bodies;
                while (my $body = $bodies->next) {
                    if ($body->isa('Lacuna::DB::Body::Planet')) {
                        if ($body->empire_id eq $empire->id) {
                            $alignment = 'self';
                        }
                    }
                }
            }
            push @out, {
                id          => $star->id,
                name        => $star->name,
                x           => $star->x,
                y           => $star->y,
                z           => $star->z,
                color       => $star->color,
                alignments  => $alignment,
                can_rename  => ( !$star->is_named && $alignment =~ m/self/ ) ? 1 : 0,
            };
        }
        return { stars=>\@out, status=>$empire->get_status };
    }
}

sub get_max_x_inhabited {
    my ($self) = @_;
    return $self->simpledb->domain('body')->max('x', {empire_id=>['!=','None']});
}

sub get_min_x_inhabited {
    my ($self) = @_;
    return $self->simpledb->domain('body')->min('x', {empire_id=>['!=','None']});
}

sub get_max_y_inhabited {
    my ($self) = @_;
    return $self->simpledb->domain('body')->max('y', {empire_id=>['!=','None']});
}

sub get_min_y_inhabited {
    my ($self) = @_;
    return $self->simpledb->domain('body')->min('y', {empire_id=>['!=','None']});
}

sub get_max_z_inhabited {
    my ($self) = @_;
    return $self->simpledb->domain('body')->max('z', {empire_id=>['!=','None']});
}

sub get_min_z_inhabited {
    my ($self) = @_;
    return $self->simpledb->domain('body')->min('z', {empire_id=>['!=','None']});
}


__PACKAGE__->register_rpc_method_names(qw(get_stars rename_star get_stars_near_body get_star_by_body get_star_system get_star_system_by_body));

no Moose;
__PACKAGE__->meta->make_immutable;

