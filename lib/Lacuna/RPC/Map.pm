package Lacuna::RPC::Map;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC';
use Lacuna::Verify;
use Lacuna::Constants qw(ORE_TYPES);
use List::Util qw(max min);

sub check_star_for_incoming_probe {
    my ($self, $args) = @_;

    confess [1019, 'You must call using named arguments.'] if ref($args) ne "HASH";
    
    my $session_id  = $args->{session_id};
    my $star_id     = $args->{star_id};

    my $empire = $self->get_empire_by_session($session_id);
    my $date = 0;
    my @bodies = $empire->planets->get_column('id')->all;
    my $incoming = Lacuna->db->resultset('Ships')->search({
        foreign_star_id => $star_id, 
        task            => 'Travelling', 
        type            => 'probe', 
        body_id         => {in => \@bodies },
    }, {
        rows            => 1,
    })->single;
    
    if (defined $incoming) {
        $date = $incoming->date_available_formatted;
    }
    return {
        status          => $self->format_status($empire),
        incoming_probe  => $date,
    };
}


sub get_star_map {
    my ($self, $args) = @_;

    confess [1019, 'You must call using named arguments.'] if ref($args) ne "HASH";
    
    my $map_size = Lacuna->config->get('map_size');

    foreach my $bound (qw(top left right bottom)) {
        confess [1002, 'co-ordinates must be integers'] if $args->{$bound} != int($args->{$bound});
    }
    my $left    = $args->{left};
    my $right   = $args->{right};
    my $top     = $args->{top};
    my $bottom  = $args->{bottom};
    my $width   = $right - $left;
    my $height  = $top - $bottom;
    my $expanse_width   = $map_size->{x}[1] - $map_size->{x}[0] + 1;
    my $expanse_height  = $map_size->{y}[1] - $map_size->{y}[0] + 1;

    my $split_lr = 0;
    my $split_tb = 0;
    
    if ($width < 0) {
        $width += $expanse_width;
        $split_lr = 1;

    }
    if ($height < 0) {
        $height += $expanse_height;
        $split_tb = 1;
    }
    if ($width * $height > 3001) {
        confess [1003, 'Requested area larger than 3001.'];
    }

    my $empire = $self->get_empire_by_session($args->{session_id});
    my $alliance_id = $empire->alliance_id || 0;

    # Normalize the co-ordinates
    while ($left < $map_size->{x}[0] and $right < $map_size->{x}[0]) {
        $left += $expanse_width;
        $right += $expanse_width;
    }
    while ($top < $map_size->{y}[0] and $bottom < $map_size->{y}[0]) {
        $top += $expanse_height;
        $bottom += $expanse_height;
    }
    while ($left > $map_size->{x}[1] and $right > $map_size->{x}[1]) {
        $left -= $expanse_width;
        $right -= $expanse_width;
    }
    while ($top > $map_size->{y}[1] and $bottom > $map_size->{y}[1]) {
        $top -= $expanse_height;
        $bottom -= $expanse_height;
    }

    my @stars;
    my $out;
    if ($split_lr and $split_tb) {
        $out = Lacuna->db->resultset('Map::StarLite')->get_star_map( $alliance_id, $empire->id, $left, $map_size->{x}[1], $map_size->{y}[0], $top );
        push @stars, @{$out->{stars}};
        $out = Lacuna->db->resultset('Map::StarLite')->get_star_map( $alliance_id, $empire->id, $map_size->{x}[0], $right, $map_size->{y}[0], $top );
        push @stars, @{$out->{stars}};
        $out = Lacuna->db->resultset('Map::StarLite')->get_star_map( $alliance_id, $empire->id, $left, $map_size->{x}[1], $bottom, $map_size->{y}[1] );
        push @stars, @{$out->{stars}};
        $out = Lacuna->db->resultset('Map::StarLite')->get_star_map( $alliance_id, $empire->id, $map_size->{x}[0], $right, $bottom, $map_size->{y}[1] );
        push @stars, @{$out->{stars}};
    }
    elsif ($split_lr) {
        $out = Lacuna->db->resultset('Map::StarLite')->get_star_map( $alliance_id, $empire->id, $left, $map_size->{x}[1], $bottom, $top );
        push @stars, @{$out->{stars}};
        $out = Lacuna->db->resultset('Map::StarLite')->get_star_map( $alliance_id, $empire->id, $map_size->{x}[0], $right, $bottom, $top );
        push @stars, @{$out->{stars}};
    }
    elsif ($split_tb) {
        $out = Lacuna->db->resultset('Map::StarLite')->get_star_map( $alliance_id, $empire->id, $left, $right, $bottom, $map_size->{y}[1] );
        push @stars, @{$out->{stars}};
        $out = Lacuna->db->resultset('Map::StarLite')->get_star_map( $alliance_id, $empire->id, $left, $right, $map_size->{y}[0], $top );
        push @stars, @{$out->{stars}};
     }
    else {
        $out = Lacuna->db->resultset('Map::StarLite')->get_star_map( $alliance_id, $empire->id, $left, $right, $bottom, $top );
        push @stars, @{$out->{stars}};
    }

    $out = {
        stars   => \@stars,
        status  => $self->format_status($empire),
    };

    return $out;
}

# Get a star by it's ID, by it's name, or it's x/y co-ordinate
#
sub get_star {
    my ($self, $args) = @_;

    confess [1019, 'You must call using named arguments.'] if ref($args) ne "HASH";
    my $session_id  = $args->{session_id};
    my $empire      = $self->get_empire_by_session($session_id);
    my $stars = Lacuna->db->resultset('Map::Star')->search();
    if ($args->{star_id}) {
        $stars = $stars->seach({id => $args->{star_id}});
    }
    elsif ($args->{star_name}) {
        $stars = $stars->search({name => $args->{star_name}});
    }
    elsif (defined $args->{x} and defined $args->{y}) {
        $stars = $stars->search({x => $args->{x}, y => $args->{y}});
    }
    else {
        confess [1002, "You must specify one of star_id, star_name or x and y"];
    }
    my $star = $stars->search({},{rows => 1})->single;
    unless (defined $star) {
        confess [1002, "Couldn't find a star."];
    }
    return { star=>$star->get_status($empire), status=>$self->format_status($session) };
}

# Find a star based on it's (partial) name
# returns the first 25 such names
#
sub find_star {
    my ($self, $args) = @_;

    confess [1019, 'You must call using named arguments.'] if ref($args) ne "HASH";
    if (length($args->{name}) < 3) {
        confess [1009, "Your search term must be at least 3 characters."];
    }
    my $session_id  = $args->{session_id};
    my $empire      = $self->get_empire_by_session($session_id);
    my $stars       = Lacuna->db->resultset('Map::Star')->search({name => { like => $args->{name}.'%' }},{rows => 25});

    my @out;
    while (my $star = $stars->next) {
        push @out, $star->get_status; # planet data left out on purpose
    }
    return { stars => \@out , status => $self->format_status($session) };
}


# Get a summary of all fissures known to the alliance by virtue of
# their probe data sorted by distance from a location (star, body or x/y)
#
sub probe_summary_fissures {
    my ($self, $args) = @_;

    confess [1019, 'You must call using named arguments.'] if ref($args) ne "HASH";

    my $empire  = $self->get_empire_by_session($args->{session_id});

    my ($x,$y);

    if ($args->{star_name}) {
        my ($star) = Lacuna->db->resultset('Map::Star')->search({name => $args->{star_name}});
        confess [1002, "Cannot find star [".$args->{star_name}."]."] unless $star;
        $x = $star->x;
        $y = $star->y;
    }
    elsif ($args->{star_id}) {
        my ($star) = Lacuna->db->resultset('Map::Star')->search({name => $args->{star_name}});
        confess [1002, "Cannot find star ID [".$args->{star_id}."]."] unless $star;
        $x = $star->x;
        $y = $star->y;
    }
    elsif ($args->{body_name}) {
        my ($body) = Lacuna->db->resultset('Map::Body')->search({name => $args->{body_name}});
        confess [1002, "Cannot find body [".$args->{body_name}."]."] unless $body;
        $x = $body->x;
        $y = $body->y;
    }
    elsif ($args->{body_id}) {
        my ($body) = Lacuna->db->resultset('Map::Body')->search({id => $args->{body_id}});
        confess [1002, "Cannot find body ID [".$args->{body_id}."]."] unless $body;
        $x = $body->x;
        $y = $body->y;
    }
    elsif (defined $args->{x} and defined $args->{y}) {
        $x = $args->{x};
        $y = $args->{y};
    }
    else {
        confess [1002, "You must specify one of star_name, star_id, body_name, body_id or x,y."];
    }
    # find all fissures centered around x|y
    #
    my $fissure_rs = Lacuna->db->resultset('Building')->search({
            'me.class'          => 'Lacuna::DB::Result::Building::Permanent::Fissure',
        },{
            prefetch    => [
                { body => { star => 'probes'} },
            ]
        }
    );
    if ($empire->alliance_id) {
        $fissure_rs = $fissure_rs->search({
            'probes.alliance_id' => $empire->alliance_id,
        });
    }
    else {
        $fissure_rs = $fissure_rs->search({
            'probes.empire_id' => $empire->id,
        });
    }
    # It's just too difficult to work out distance, so let's just get them all and sort.
    my @fissures = $fissure_rs->all;

    my $distances;
    foreach my $fissure (@fissures) {
        my $body = $fissure->body;
        $distances->{$fissure->id} = {
            distance    => $body->calculate_distance_to_xy($x, $y),
            body        => $body,
        };
    }
    my @out;
    foreach my $key (sort {$distances->{$b}->{distance} <=> $distances->{$a}->{distance}} keys %$distances) {
        my $body = $distances->{$key}{body};
        my $row = {
            name        => $body->name,
            id          => $body->id,
            orbit       => $body->orbit,
            x           => $body->x,
            y           => $body->y,
            type        => $body->type,
            image       => $body->image,
            size        => $body->size,
            distance    => $distances->{$key}{distance} * 100,
        };
        push @out, $row;
    }
    return { fissures => \@out};
}

sub view_laws {
    my ($self, $session_id, $star_id) = @_;
    my $session  = $self->get_session({session_id => $session_id });
    my $empire   = $session->current_empire;
    my $star = Lacuna->db->resultset('Map::Star')->find($star_id);
    if ($star and $star->station_id) {
        my $station = Lacuna->db->resultset('Lacuna::DB::Result::Map::Body')
                ->find($star->station->id);
        my @out;
        my $laws;
        if ($station) {
            $laws = $station->laws;
            while (my $law = $laws->next) {
                push @out, $law->get_status($empire);
            }
        }
        return {
            star            => $star->get_status($empire),
            status          => $self->format_status($session, $station),
            laws            => \@out,
        };
    }
    else {
        my $output;
        if ($star) {
            $output->{star} = $star->get_status($empire);
        }
        $output->{status} = $self->format_status($session);
        $output->{laws} = [ { name => "Not controlled by a station",
                              descripition => "Not controlled by a station",
                              date_enacted => "00 00 0000 00:00:00 +0000",
                              id => 0
                            } ];
        return $output;
    }
}

__PACKAGE__->register_rpc_method_names(qw(
    get_star_map
    check_star_for_incoming_probe
    get_star
    find_star
    probe_summary_fissures
    view_laws
));

no Moose;
__PACKAGE__->meta->make_immutable;

