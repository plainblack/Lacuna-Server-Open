package Lacuna::RPC::Map;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC';
use Lacuna::Verify;
use Lacuna::Constants qw(ORE_TYPES);

sub check_star_for_incoming_probe {
    my ($self, $session_id, $star_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $date = 0;
    my @bodies = $empire->planets->get_column('id')->all;
    my $incoming = Lacuna->db->resultset('Lacuna::DB::Result::Ships')->search({foreign_star_id=>$star_id, task=>'Travelling', type=>'probe', body_id => {in => \@bodies }}, {rows=>1})->single;
    if (defined $incoming) {
        $date = $incoming->date_available_formatted;
    }
    return {
        status  => $self->format_status($empire),
        incoming_probe  => $date,
    };
}

sub get_stars {
    my ($self, $session_id, $x1, $y1, $x2, $y2) = @_;
    my ($startx,$starty,$endx,$endy);
    if ($x1 > $x2) { $startx = $x2; $endx = $x1; } else { $startx = $x1; $endx = $x2; } # organize x
    if ($y1 > $y2) { $starty = $y2; $endy = $y1; } else { $starty = $y1; $endy = $y2; } # organize y
    if ((abs($endx - $startx) * abs($endy - $starty)) > 400) {
        confess [1003, 'Requested area too large.'];
    }
    my $empire = $self->get_empire_by_session($session_id);
    my $stars = Lacuna->db->resultset('Lacuna::DB::Result::Map::Star')->search({y=> {between => [$starty, $endy]}, x=>{between => [$startx, $endx]}});
    my @out;
    while (my $star = $stars->next) {
        push @out, $star->get_status($empire);
    }
    return { stars=>\@out, status=>$self->format_status($empire) };
}

sub get_star {
    my ($self, $session_id, $star_id) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $star = Lacuna->db->resultset('Lacuna::DB::Result::Map::Star')->find($star_id);
    unless (defined $star) {
        confess [1002, "Couldn't find a star."];
    }
    return { star=>$star->get_status($empire), status=>$self->format_status($empire) };
}

sub get_star_by_name {
    my ($self, $session_id, $star_name) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $star = Lacuna->db->resultset('Lacuna::DB::Result::Map::Star')->search({name => $star_name}, {rows=>1})->single;
    unless (defined $star) {
        confess [1002, "Couldn't find a star."];
    }
    return { star=>$star->get_status($empire), status=>$self->format_status($empire) };
}

sub get_star_by_xy {
    my ($self, $session_id, $x, $y) = @_;
    my $empire = $self->get_empire_by_session($session_id);
    my $star = Lacuna->db->resultset('Lacuna::DB::Result::Map::Star')->search({x=>$x, y=>$y}, {rows=>1})->single;
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
    my $empire = $self->get_empire_by_session($session_id);
    my @out;
    my $stars = Lacuna->db->resultset('Lacuna::DB::Result::Map::Star')->search({name => { like => $name.'%' }},{rows => 25});
    while (my $star = $stars->next) {
        push @out, $star->get_status; # planet data left out on purpose
    }
    return { stars => \@out , status => $self->format_status($empire) };
}

__PACKAGE__->register_rpc_method_names(qw(get_stars get_star_by_name get_star get_star_by_xy search_stars check_star_for_incoming_probe));

no Moose;
__PACKAGE__->meta->make_immutable;

