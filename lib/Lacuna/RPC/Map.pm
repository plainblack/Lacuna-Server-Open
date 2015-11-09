package Lacuna::RPC::Map;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC';
use Lacuna::Verify;
use Lacuna::Constants qw(ORE_TYPES);
use List::Util qw(max min);

sub check_star_for_incoming_probe {
    my ($self, $session_id, $star_id) = @_;
    my $session  = $self->get_session({session_id => $session_id });
    my $empire   = $session->current_empire;
    my $date = 0;
    my @bodies = $empire->planets->get_column('id')->all;
    my $incoming = Lacuna->db->resultset('Ships')->search({foreign_star_id=>$star_id, task=>'Travelling', type=>'probe', body_id => {in => \@bodies }})->first;
    if (defined $incoming) {
        $date = $incoming->date_available_formatted;
    }
    return {
        status  => $self->format_status($empire),
        incoming_probe  => $date,
    };
}

sub get_star_map {
    my ($self, $args) = @_;

    my $map_size = Lacuna->config->get('map_size');

    foreach my $bound (qw(top left right bottom)) {
        confess [1002, 'co-ordinates must be integers'] if $args->{$bound} != int($args->{$bound});
    }
    foreach my $bound (qw(left right)) {
        $args->{$bound} = max($args->{$bound}, $map_size->{x}[0]);
        $args->{$bound} = min($args->{$bound}, $map_size->{x}[1]);
    }
    foreach my $bound (qw(top bottom)) {
        $args->{$bound} = max($args->{$bound}, $map_size->{y}[0]);
        $args->{$bound} = min($args->{$bound}, $map_size->{y}[1]);
    }
    if ($args->{left} > $args->{right}) {
        my $temp = $args->{right};
        $args->{right} = $args->{left};
        $args->{left} = $temp;
    }
    if ($args->{top} < $args->{bottom}) {
        my $temp = $args->{bottom};
        $args->{bottom} = $args->{top};
        $args->{top} = $temp;
    }
    if ((abs($args->{top} - $args->{bottom}) * abs($args->{right} - $args->{left})) > 3001) {
        confess [1003, 'Requested area larger than 3001.'];
    }
    my $session  = $self->get_session({session_id => $args->{session_id}});
    my $empire   = $session->current_empire;
    my $alliance_id = $empire->alliance_id || 0;

    my $out = Lacuna->db->resultset('Map::StarLite')->get_star_map( $alliance_id, $empire->id, $args->{left}, $args->{right}, $args->{bottom}, $args->{top} );
    $out->{status} = $self->format_status($empire);

    return $out;
}

sub get_stars {
    my ($self, $session_id, $x1, $y1, $x2, $y2) = @_;
    my ($startx,$starty,$endx,$endy);
    if ($x1 > $x2) { $startx = $x2; $endx = $x1; } else { $startx = $x1; $endx = $x2; } # organize x
    if ($y1 > $y2) { $starty = $y2; $endy = $y1; } else { $starty = $y1; $endy = $y2; } # organize y
    if ((abs($endx - $startx) * abs($endy - $starty)) > 900) {
        confess [1003, 'Requested area too large.'];
    }
    my $session  = $self->get_session({session_id => $session_id });
    my $empire   = $session->current_empire;
    my $stars = Lacuna->db->resultset('Map::Star')->search({y=> {between => [$starty, $endy]}, x=>{between => [$startx, $endx]}});
    my @out;
    while (my $star = $stars->next) {
        push @out, $star->get_status($empire);
    }
    return { stars=>\@out, status=>$self->format_status($empire) };
}

sub get_star {
    my ($self, $session_id, $star_id) = @_;
    my $session  = $self->get_session({session_id => $session_id });
    my $empire   = $session->current_empire;
    my $star = Lacuna->db->resultset('Map::Star')->find($star_id);
    unless (defined $star) {
        confess [1002, "Couldn't find a star."];
    }
    return { star=>$star->get_status($empire), status=>$self->format_status($empire) };
}

sub get_star_by_name {
    my ($self, $session_id, $star_name) = @_;
    my $session  = $self->get_session({session_id => $session_id });
    my $empire   = $session->current_empire;
    my $star = Lacuna->db->resultset('Map::Star')->search({name => $star_name})->first;
    unless (defined $star) {
        confess [1002, "Couldn't find a star."];
    }
    return { star=>$star->get_status($empire), status=>$self->format_status($empire) };
}

sub get_star_by_xy {
    my ($self, $session_id, $x, $y) = @_;
    my $session  = $self->get_session({session_id => $session_id });
    my $empire   = $session->current_empire;
    my $star = Lacuna->db->resultset('Map::Star')->search({x=>$x, y=>$y})->first;
    unless (defined $star) {
        confess [1002, "Couldn't find a star."];
    }
    return { star=>$star->get_status($empire), status=>$self->format_status($empire) };
}

sub search_stars {
    my ($self, $session_id, $name) = @_;
    if (length($name) < 3) {
        confess [1009, "Your search term must be at least 3 characters."];
    }
    my $session  = $self->get_session({session_id => $session_id });
    my $empire   = $session->current_empire;
    my @out;
    my $stars = Lacuna->db->resultset('Map::Star')->search({name => { like => $name.'%' }},{rows => 25});
    while (my $star = $stars->next) {
        push @out, $star->get_status; # planet data left out on purpose
    }
    return { stars => \@out , status => $self->format_status($empire) };
}

sub probe_summary_fissures {
    my ($self, $args) = @_;

    my $session  = $self->get_session({session_id => $args->{session_id} });
    my $empire   = $session->current_empire;
    my $zone    = $args->{zone};
    my $fissure_rs = Lacuna->db->resultset('Building')->search({
            'me.class'          => 'Lacuna::DB::Result::Building::Permanent::Fissure',
        },{
            prefetch    => [
                { body => { star => 'probes'} },
            ]
        }
    );
    if ($args->{zone}) {
        $fissure_rs = $fissure_rs->search({
            'star.zone' => $args->{zone},
        });
    }
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
    my $fissures;
    while (my $fissure = $fissure_rs->next) {
        $fissures->{$fissure->body_id} = $fissure->body->get_status_lite;
    }
    return { fissures => $fissures};
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
            status          => $self->format_status($empire, $station),
            laws            => \@out,
        };
    }
    else {
        my $output;
        if ($star) {
            $output->{star} = $star->get_status($empire);
        }
        $output->{status} = $self->format_status($empire);
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
    get_body_status
    get_stars 
    get_star_by_name
    get_star 
    get_star_by_xy 
    search_stars 
    check_star_for_incoming_probe
    probe_summary_fissures
    view_laws
));

no Moose;
__PACKAGE__->meta->make_immutable;

