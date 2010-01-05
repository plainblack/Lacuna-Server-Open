package Lacuna::Map;

use Moose;
extends 'JSON::RPC::Dispatcher::App';
use List::MoreUtils qw(any);
use Lacuna::Verify;

has simpledb => (
    is      => 'ro',
    required=> 1,
);

with 'Lacuna::Role::Sessionable';

sub rename_star {
    my ($self, $session_id, $star_id, $name) = @_;
    Lacuna::Verify->new(content=>$name, throws=>[1000,'Name not available.'])
        ->length_gt(2)
        ->length_lt(31)
        ->no_restricted_chars
        ->no_profanity
        ->not_ok($self->simpledb->domain('star')->count({name=>$name})); # name available
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
        confess [1002, 'Star does not exist.'];
    }
}

sub get_stars_near_planet {
    my ($self, $session_id, $planet_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $planet = $self->simpledb->domain('planet')->find($planet_id);
    if (defined $planet) {
        my $star = $planet->star;
        return $self->get_stars($empire, $star->x + 5, $star->y + 5, $star->x - 5, $star->y - 5, $star->z); 
    }
    else {
        confess [1002, 'Planet does not exist.'];
    }
}

sub get_star_for_planet {
    my ($self, $session_id, $planet_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $planet = $self->simpledb->domain('planet')->find($planet_id);
    # we don't do any privilege checking because it's assumed if you know the planet id you can access the star,
    # plus, it's not like you couldn't get the info it sends back via the get_stars method anyway
    if (defined $planet) {
        my $star = $planet->star;
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
        confess [1002, 'Planet does not exist.'];
    }
}

sub get_stars {
    my ($self, $session_id, $x1, $y1, $x2, $y2, $z) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    if ((abs($x2 - $x1) * abs($y2 - $y1)) > 121) {
        confess [1003, 'Requested area too large.'];
    }
    else {
        my $stars = $self->simpledb->domain('star')->search({z=>$z, y=>['between', $y1, $y2], x=>['between', $x1, $x2]});
        my @out;
        my @probed = @{$empire->probed_stars};
        while (my $star = $stars->next) {
            my $alignment = 'unprobed';
            if (any { $_ = $star->id } @probed) {
                $alignment = 'probed';
                my $bodies = $star->bodies;
                my %alignments;
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
    my $planet = $self->simpledb->domain('planet')->search({empire_id=>['!=','None']},['x'],1);
    return (defined $planet)  ? $planet->x : 0;
}

sub get_min_x_inhabited {
    my ($self) = @_;
    my $planet = $self->simpledb->domain('planet')->search({empire_id=>['!=','None']},'x',1);
    return (defined $planet)  ? $planet->x : 0;
}

sub get_max_y_inhabited {
    my ($self) = @_;
    my $planet = $self->simpledb->domain('planet')->search({empire_id=>['!=','None']},['y'],1);
    return (defined $planet)  ? $planet->y : 0;
}

sub get_min_y_inhabited {
    my ($self) = @_;
    my $planet = $self->simpledb->domain('planet')->search({empire_id=>['!=','None']},'y',1);
    return (defined $planet)  ? $planet->y : 0;
}

sub get_max_z_inhabited {
    my ($self) = @_;
    my $planet = $self->simpledb->domain('planet')->search({empire_id=>['!=','None']},['z'],1);
    return (defined $planet)  ? $planet->z : 0;
}

sub get_min_z_inhabited {
    my ($self) = @_;
    my $planet = $self->simpledb->domain('planet')->search({empire_id=>['!=','None']},'z',1);
    return (defined $planet)  ? $planet->z : 0;
}


__PACKAGE__->register_rpc_method_names(qw(get_stars rename_star get_stars_near_planet));

no Moose;
__PACKAGE__->meta->make_immutable;

