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
    my $empire = $self->get_empire_by_session($session_id);
    my $date = 0;
    my @bodies = $empire->planets->get_column('id')->all;
    my $incoming = Lacuna->db->resultset('Ships')->search({foreign_star_id=>$star_id, task=>'Travelling', type=>'probe', body_id => {in => \@bodies }}, {rows=>1})->single;
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
    my $empire = $self->get_empire_by_session($args->{session_id});
    my $alliance_id = $empire->alliance_id || 0;

    my $out = Lacuna->db->resultset('Map::StarLite')->get_star_map( $alliance_id, $empire->id, $args->{left}, $args->{right}, $args->{bottom}, $args->{top} );
    $out->{status} = $self->format_status($empire);

    return $out;
}

sub get_stars {
    confess [1003, 'get_stars API is no longer supported. use get_star_map instead'];
}

sub get_star {
    my ($self, $session_id, $star_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $star = Lacuna->db->resultset('Map::Star')->find($star_id);
    unless (defined $star) {
        confess [1002, "Couldn't find a star."];
    }
    return { star=>$star->get_status($empire), status=>$self->format_status($empire) };
}

sub get_star_by_name {
    my ($self, $session_id, $star_name) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $star = Lacuna->db->resultset('Map::Star')->search({name => $star_name}, {rows=>1})->single;
    unless (defined $star) {
        confess [1002, "Couldn't find a star."];
    }
    return { star=>$star->get_status($empire), status=>$self->format_status($empire) };
}

sub get_star_by_xy {
    my ($self, $session_id, $x, $y) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $star = Lacuna->db->resultset('Map::Star')->search({x=>$x, y=>$y}, {rows=>1})->single;
    unless (defined $star) {
        confess [1002, "Couldn't find a star."];
    }
    return { star=>$star->get_status($empire), status=>$self->format_status($empire) };
}

sub search_stars {
    my ($self, $session_id, $name, $alliance_id) = @_;
    if (length($name) < 3) {
        confess [1009, "Your search term must be at least 3 characters."];
    }
    my $empire = $self->get_empire_by_session($session_id);
    my @out;
    my $stars = Lacuna->db->resultset('Map::Star')->search({name => { like => $name.'%' }});
    if ($alliance_id) {
        $stars = $stars->search({
            influence   => {'>=' => 50 },
            alliance_id => $alliance_id,
        });
    }

    $stars = $stars->search({},{rows => 25});

    while (my $star = $stars->next) {
        push @out, $star->get_status; # planet data left out on purpose
    }
    return { stars => \@out , status => $self->format_status($empire) };
}

sub probe_summary_fissures {
    my ($self, $args) = @_;

    my $empire  = $self->get_empire_by_session($args->{session_id});
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
));

no Moose;
__PACKAGE__->meta->make_immutable;

